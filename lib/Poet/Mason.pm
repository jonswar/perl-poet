package Poet::Mason;    ## no critic (Moose::RequireMakeImmutable)

use Poet qw($conf $poet);
use List::MoreUtils qw(uniq);
use Method::Signatures::Simple;
use Moose;
use Try::Tiny;

extends 'Mason';

my $instance;

method instance ($class:) {
    $instance ||= $class->new();
    $instance;
}

method new ($class:) {
    return $class->SUPER::new( $class->get_options, @_ );
}

method get_options ($class:) {
    my %defaults = (
        cache_root_class => $poet->app_class('Cache'),
        comp_root        => $poet->comps_dir,
        data_dir         => $poet->data_dir,
        plugins          => [ $class->get_plugins ],
    );
    my %configured    = %{ $conf->get_hash("mason") };
    my $extra_plugins = $conf->get_list("mason.extra_plugins");
    delete( $configured{extra_plugins} );
    my %options = ( %defaults, %configured );
    $options{plugins} = [ uniq( @{ $options{plugins} }, '+Poet::Mason::Plugin', @$extra_plugins ) ];
    return %options;
}

method get_plugins ($class:) {
    return ( 'HTMLFilters', 'RouterSimple', 'Cache' );
}

method handle_psgi ($class: $psgi_env) {
    my $req      = $poet->app_class('Plack::Request')->new($psgi_env);
    my $res      = $poet->app_class('Plack::Response')->new();
    my $response = try {
        my $interp = $poet->app_class('Mason')->instance;
        my $m = $interp->_make_request( req => $req, res => $res );
        $m->run( $class->_psgi_comp_path($req), $class->_psgi_parameters($req) );
        $m->res;
    }
    catch {
        my $err = $_;
        if ( blessed($err) && $err->isa('Mason::Exception::TopLevelNotFound') ) {
            $poet->app_class('Plack::Response')->new(404);
        }
        else {

            # Prevent Plack::Middleware::Debug from capturing this stack point
            local $SIG{__DIE__} = undef;
            die $err;
        }
    };
    return $response->finalize;
}

method _psgi_comp_path ($class: $req) {
    my $comp_path = $req->path;
    $comp_path = "/$comp_path" if substr( $comp_path, 0, 1 ) ne '/';
    return $comp_path;
}

method _psgi_parameters ($class: $req) {
    return $req->parameters;
}

1;

__END__

=pod

=head1 NAME

Poet::Mason -- Mason settings and enhancements for Poet

=head1 SYNOPSIS

    # In a conf file...
    mason:
      plugins:
        - Cache
        - TidyObjectFiles
        - +My::Mason::Plugin
      static_source: 1
      static_source_touch_file: ${root}/data/purge.dat

    # Get the main Mason instance
    my $mason = Poet::Mason->instance();

    # Create a new Mason object
    my $mason = Poet::Mason->new(...);

=head1 DESCRIPTION

This is a Poet-specific L<Mason|Mason> subclass. It sets up sane default
settings, maintains a main Mason instance for handling web requests, and adds
Poet-specific methods to C<$m> (the Mason request object).

=head1 CLASS METHODS

=over

=item get_options

Returns a hash of Mason options by combining L<default settings|/DEFAULT
SETTINGS> and L<configuration|/CONFIGURATION>.

=item instance

Returns the main Mason instance used for web requests, which is created with
options from L<get_options|/get_options>.

=item new

Returns a new main Mason object, using options from
L<get_options|/get_options>. Unless you specifically need a new object, you
probably want to call L<instance|/instance>.

=back

=head1 DEFAULT SETTINGS

=over

=item *

C<comp_root> is set to L<$poet-E<gt>comps_dir|Poet::Environment/comps_dir>, by
default the C<comps> subdirectory under the environment root.

=item *

C<data_dir> is set to L<$poet-E<gt>data_dir|Poet::Environment/data_dir>, by
default the C<data> subdirectory under the environment root.

=item *

C<plugins> is set to include L<Cache|Mason::Plugin::Cache>,
L<HTMLFilters|Mason::Plugin::HTMLFilters> and
L<RouterSimple|Mason::Plugin::RouterSimple>.

=item *

C<cache_root_class> (a parameter of the C<Cache> plugin) is set to
C<MyApp::Cache> if it exists (replacing C<MyApp> with your L<app
name|Poet::Manual::Intro/App name>), otherwise C<Poet::Cache>.

=back

=head1 CONFIGURATION

The Poet configuration entry 'mason', if any, will be treated as a hash of
options that supplements and/or overrides the defaults above. If the hash
contains 'extra_plugins', these will be added to the default plugins. e.g.

    mason:
      static_source: 1
      static_source_touch_file: ${root}/data/purge.dat
      extra_plugins:
         - AnotherFavoritePlugin

=head1 QUICK VARS AND UTILITIES

Poet inserts the following line at the top of of every compiled Mason
component:

    use Poet qw($conf $poet :web);

which means that L<$conf|Poet::Conf>, L<$poet|Poet::Environment>, and L<web
utilities|Poet::Util::Web> are available from every component.

=head1 NEW REQUEST METHODS

Under Poet these additional web-related methods are available in the L<Mason
request object|Mason::Request>, accessible in components via C<$m> or elsewhere
via C<Mason::Request-E<gt>current_request>.

=over

=item req ()

A reference to the L<Plack::Request> object. e.g.

    my $user_agent = $m->req->headers->header('User-Agent');

=item res ()

A reference to the L<Plack::Response> object. e.g.

    $m->res->content_type('text/plain');

=item abort (status)

=item clear_and_abort (status)

These methods are overridden to set the response status before aborting, if
I<status> is provided. e.g. to send back a FORBIDDEN result:

    $m->clear_and_abort(403);

This is equivalent to

    $m->res->status(403);
    $m->clear_and_abort();

If a status is not provided, the methods work just as before.

=item redirect (url[, status])

Sets headers and status for redirect, then clears the Mason buffer and aborts
the request. e.g.

    $m->redirect("http://somesite.com", 302);

is equivalent to

    $m->res->redirect("http://somesite.com", 302);
    $m->clear_and_abort();

=item not_found ()

Sets the status to 404, then clears the Mason buffer and aborts the request.
e.g.

    $m->not_found();

is equivalent to

    $m->clear_and_abort(404);

=item session

A shortcut for C<$m-E<gt>req-E<gt>session>, the L<Plack
session|Plack::Session>.  This is simply a persistent hash that you can read
from and write to. It is tied to the user's browser session via cookies and
stored in a file cache in the data directory (by default).

    my $value = $m->session->{key};
    $m->session->{key} = { some_complex => ['value'] };

=item send_json ($data)

Output the JSON-encoded I<$data>, set the content type to "application/json",
and abort. e.g.

    method handle {
        my $data;
        # compute data somehow
        $m->send_json($data);
    }

C<send_json> is a shortcut for

    $m->clear_buffer;
    $m->print(JSON::XS::encode_json($data));
    $m->res->content_type("application/json");
    $m->abort();

=back
