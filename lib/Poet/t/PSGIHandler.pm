package Poet::t::PSGIHandler;

use Test::Class::Most parent => 'Poet::Test::Class';
use Capture::Tiny qw();
use Config;
use Guard;
use File::Spec::Functions qw(rel2abs);
use Poet::Tools qw(dirname mkpath trim write_file);

my $poet = __PACKAGE__->initialize_temp_env(
    conf => {
        layer                 => 'production',
        'foo.bar'             => 5,
        'server.load_modules' => ['TestApp::Foo']
    }
);
unlink( glob( $poet->comps_path("*.mc") ) );
write_file( $poet->lib_path("TestApp/Foo.pm"), "package TestApp::Foo;\nsub bar {}\n1;\n" );

sub mech {
    my $self = shift;
    my $mech = $self->SUPER::mech( env => $poet );
    @{ $mech->requests_redirectable } = ();
    return $mech;
}

sub add_comp {
    my ( $self, %params ) = @_;
    my $path = $params{path} or die "must pass path";
    my $src  = $params{src}  or die "must pass src";
    my $file = $poet->comps_dir . $path;
    mkpath( dirname($file), 0, 0775 );
    write_file( $file, $src );
}

sub try_psgi_comp {
    my ( $self, %params ) = @_;
    my $path = $params{path} or die "must pass path";
    ( my $uri = $path ) =~ s/\.mc$//;
    my $qs = $params{qs} || '';
    my $expect_code = defined( $params{expect_code} ) ? $params{expect_code} : 200;

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
            is( trim( $mech->content ), trim($expect_content), "$path - content" );
        }
        is( $mech->status, $expect_code, "$path - code" );
        if ( my $expect_headers = $params{expect_headers} ) {
            while ( my ( $hdr, $value ) = each(%$expect_headers) ) {
                cmp_deeply( $mech->res->header($hdr), $value, "$path - header $hdr" );
            }
        }
    }
}

sub test_get_pl : Tests {
    my $self = shift;
    $self->add_comp(
        path => '/getpl.mc',
        src  => 'path = <% $m->req->path %>'
    );
    # See perlport "Command names versus file pathnames".
    my $perl = '';
    if ($^O eq 'MSWin32') {
        $perl = $Config{perlpath};
        $perl .= $Config{_exe} unless $perl =~ m/$Config{_exe}$/i;
        $perl = join(' ', $perl, map { '-I' . $_ } @INC);
    }
    my $cmd = sprintf( "%s %s /getpl", $perl, $poet->bin_path("get.pl") );
    my $output = Capture::Tiny::capture_merged { system($cmd) };
    is( $output, 'path = /getpl', "get.pl output" );
}

sub test_basic : Tests {
    my $self = shift;
    $self->try_psgi_comp(
        path           => '/basic.mc',
        src            => 'path = <% $m->req->path %>',
        expect_content => 'path = /basic',
    );
}

sub test_error : Tests {
    my $self = shift;
    $self->try_psgi_comp(
        path           => '/error.mc',
        src            => '% die "bleah";',
        expect_code    => 500,
        expect_content => qr/bleah/,
    );
}

sub test_not_found : Tests {
    my $self = shift;
    my $mech = $self->mech();
    $mech->get("/does/not/exist");
    is( $mech->status, 404, "status 404" );
    like( $mech->content, qr/Not found/, "default not found page" );
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
$.d => (isa => "ArrayRef[Int]", default => sub { [10] });
$.e => (isa => "ArrayRef[Int]", default => sub { [10] });
</%args>

a = <% $.a %>
b = <% $.b %>
c = <% join(",", @{$.c}) %>
d = <% join(",", @{$.d}) %>
e = <% join(",", @{$.e}) %>

% my $args = $.args;
<% Mason::Util::dump_one_line($args) %>
',
        expect_content => <<EOF,
a = 2
b = 4
c = 5,6
d = 7,8
e = 10

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
    $self->try_psgi_comp(
        path => '/go_to_redirect.mc',
        src  => '
<%init>
$m->go("/redirect");
</%init>
',
        expect_content => ' ',
        expect_code    => 302,
        expect_headers => { Location => 'http://www.google.com/' },
    );
    $self->try_psgi_comp(
        path => '/visit_redirect.mc',
        src  => '
<%init>
$m->visit("/redirect");
</%init>
',
        expect_content => ' ',
        expect_code    => 302,
        expect_headers => { Location => 'http://www.google.com/' },
    );
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
        expect_content => qr/Not found/,
        expect_code    => 404,
    );
}

sub test_import : Tests {
    my $self     = shift;
    my $root_dir = $poet->root_dir;
    $self->try_psgi_comp(
        path => '/import.mc',
        src  => '
foo.bar = <% $conf->get("foo.bar") %>
root_dir = <% $poet->root_dir %>
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

    my $expected_root_dir = rel2abs("data/cache", $poet->root_dir);
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

sub test_misc : Tests {
    my $self = shift;
    $self->try_psgi_comp(
        path           => '/misc.mc',
        src            => 'TestApp::Foo = <% TestApp::Foo->can("bar") ? "loaded" : "not loaded" %>',
        expect_content => 'TestApp::Foo = loaded',
    );
}

1;
