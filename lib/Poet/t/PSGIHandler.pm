package Poet::t::PSGIHandler;
use Poet::Test::Util;
use Capture::Tiny qw();
use File::Basename;
use File::Path;
use Guard;
use Poet::Util qw(trim write_file);
use Test::Most;
use IPC::System::Simple qw(run);
use strict;
use warnings;
use base qw(Test::Class);

my $env =
  initialize_temp_env( conf => { layer => 'production', 'foo.bar' => 5 } );
unlink( glob( $env->comps_path("*.mc") ) );

sub mech {
    my $mech = build_test_mech($env);
    @{ $mech->requests_redirectable } = ();
    return $mech;
}

sub add_comp {
    my ( $self, %params ) = @_;
    my $path = $params{path} or die "must pass path";
    my $src  = $params{src}  or die "must pass src";
    my $file = $env->comps_dir . $path;
    mkpath( dirname($file), 0, 0775 );
    write_file( $file, $src );
}

sub try_psgi_comp {
    my ( $self, %params ) = @_;
    my $path = $params{path} or die "must pass path";
    ( my $uri = $path ) =~ s/\.mc$//;
    my $qs = $params{qs} || '';
    my $expect_code =
      defined( $params{expect_code} ) ? $params{expect_code} : 200;

    $self->add_comp(%params);

    my $mech = $self->mech();
    {

        # Silence 'PSGI error' diagnostics if we're expecting error
        Test::More->builder->no_diag(1) if $expect_code == 500;
        scope_guard { Test::More->builder->no_diag(0) };
        $mech->get( $uri . $qs );
    }

    if ( my $expect_content = $params{expect_content} ) {

        if ( ref($expect_content) eq 'Regexp' ) {
            $mech->content_like( $expect_content, "$path - content" );
        }
        else {
            is(
                trim( $mech->content ),
                trim($expect_content),
                "$path - content"
            );
        }
        is( $mech->status, $expect_code, "$path - code" );
        if ( my $expect_headers = $params{expect_headers} ) {
            while ( my ( $hdr, $value ) = each(%$expect_headers) ) {
                cmp_deeply( $mech->res->header($hdr),
                    $value, "$path - header $hdr" );
            }
        }
    }
}

sub test_get_pl : Tests {
    my $self = shift;
    $self->add_comp(
        path => '/hi.mc',
        src  => 'path = <% $m->req->path %>'
    );
    my $cmd = sprintf( "%s /hi", $env->bin_path("get.pl") );
    my $output = Capture::Tiny::capture_merged { system($cmd) };
    is( $output, 'path = /hi', "get.pl output" );
}

sub test_basic : Tests {
    my $self = shift;
    $self->try_psgi_comp(
        path           => '/hi.mc',
        src            => 'path = <% $m->req->path %>',
        expect_content => 'path = /hi',
    );
}

sub test_error : Tests {
    my $self = shift;
    $self->try_psgi_comp(
        path           => '/die.mc',
        src            => '% die "bleah";',
        expect_code    => 500,
        expect_content => qr/bleah at/,
    );
}

sub test_not_found : Tests {
    my $self = shift;
    my $mech = $self->mech();
    $mech->get("/does/not/exist");
    is( $mech->status,  404, "status 404" );
    is( $mech->content, '',  "blank content" );
}

sub test_args : Tests {
    my $self = shift;
    $self->try_psgi_comp(
        path => '/args.mc',
        qs   => '?a=1&a=2&b=3&b=4&c=5&c=6&d=7&d=8',
        src  => '
<%args>
$.a
$.b => (isa => "Int")
$.c => (isa => "ArrayRef");
$.d => (isa => "ArrayRef[Int]");
</%args>

a = <% $.a %>
b = <% $.b %>
c = <% join(",", @{$.c}) %>
d = <% join(",", @{$.d}) %>

% my $args = $.args;
<% Mason::Util::dump_one_line($args) %>
',
        expect_content => <<EOF,
a = 2
b = 4
c = 5,6
d = 7,8

{a => '2',b => '4',c => ['5','6'],d => ['7','8']}
EOF
    );
}

sub test_abort : Tests {
    my $self = shift;
    $self->try_psgi_comp(
        path => '/redirect.mc',
        src  => '
will not be printed
% $m->redirect("http://www.google.com/");
will also not be printed
',
        expect_content => ' ',
        expect_code    => 302,
        expect_headers => { Location => 'http://www.google.com/' },
    );
    return;
    $self->try_psgi_comp(
        path => '/redirect_301.mc',
        src  => '
will not be printed
% $m->redirect("http://www.yahoo.com/", 301);
',
        expect_content => ' ',
        expect_code    => 301,
        expect_headers => { Location => 'http://www.yahoo.com/' },
    );
    $self->try_psgi_comp(
        path => '/not_found.mc',
        src  => '
will not be printed
% $m->clear_and_abort(404);
',
        expect_content => ' ',
        expect_code    => 404,
    );
}

sub test_import : Tests {
    my $self     = shift;
    my $root_dir = $env->root_dir;
    $self->try_psgi_comp(
        path => '/import.mc',
        src  => '
foo.bar = <% $conf->get("foo.bar") %>
root_dir = <% $env->root_dir %>
<% dh_live({baz => "blargh"}) %>
',
        expect_content =>
          sprintf( "
foo.bar = 5
root_dir = %s
<pre>
\[dh_live at %s/comps/import.mc line 4.] [$$] {
  baz => 'blargh'
}

</pre>
", $root_dir, $root_dir )
    );
}

sub test_visit : Tests {
    my $self = shift;

    Mason::Request->_reset_next_id();
    $self->add_comp(
        path => '/subreq/other.mc',
        src  => '
id=<% $m->id %>
<% $m->page->cmeta->path %>
<% $m->request_path %>
<% Mason::Util::dump_one_line($m->request_args) %>
',
    );
    $self->try_psgi_comp(
        path => '/subreq/visit.mc',
        src  => '
begin
id=<% $m->id %>
<%perl>$m->visit("/subreq/other", foo => 5);</%perl>
id=<% $m->id %>
end
',
        expect_content => "
begin
id=0
id=1
/subreq/other.mc
/subreq/other
\{foo => 5}
id=0
end
"
    );
}

sub test_cache : Tests {
    my $self = shift;

    my $expected_root_dir = $env->root_dir . "/data/cache";
    $self->try_psgi_comp(
        path => '/cache.mc',
        src  => '
chi_root_class: <% $m->cache->chi_root_class %>
root_dir: <% $m->cache->root_dir %>
',
        expect_content => "
chi_root_class: Poet::Cache
root_dir: $expected_root_dir
",
    );
}

1;
