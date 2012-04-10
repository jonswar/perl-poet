package Poet::Mason;
use Poet qw($conf $env);
use List::MoreUtils qw(uniq);
use Method::Signatures::Simple;
use Moose;

extends 'Mason';

my $instance;

method instance ($class:) {
    $instance ||= $class->new();
    $instance;
}

method get_options ($class:) {
    my %defaults = (
        allow_globals => [qw($conf $env)],
        comp_root     => $env->comps_dir,
        data_dir      => $env->data_dir,
        plugins       => [ $class->get_plugins ],
    );
    my %options = ( %defaults, %{ $conf->get_hash("mason") } );
    push( @{ $options{plugins} }, '+Poet::Mason::Plugin' );    # mandatory
    return %options;
}

method get_plugins ($class:) {
    return ( 'HTMLFilters', 'RouterSimple' );
}

method new ($class:) {
    my $interp = $class->SUPER::new( $class->get_options, @_ );
    $class->_set_poet_globals($interp);
    return $interp;
}

method _set_poet_globals ($interp) {
    my %allowed_globals = map { ( $_, 1 ) } @{ $interp->allow_globals };
    $interp->set_global( '$conf', $conf ) if $allowed_globals{'$conf'};
    $interp->set_global( '$env',  $env )  if $allowed_globals{'$env'};
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

This is a Poet-specific Mason subclass. It sets up sane default settings,
maintains a main Mason instance for handling web requests, and adds
Poet-specific methods to the Mason request ($m).

=head1 CLASS METHODS

=over

=item get_options

Returns a hash of Mason options by combining L<default settings|DEFAULT
SETTINGS> and L<configuration|CONFIGURATION>.

=item instance

Returns the main Mason instance used for web requests, which is created with
options from L<get_options>.

=item new

Returns a new main Mason object, using options from L<get_options>. Unless you
specifically need a new object, you probably want to call L</instance>.

=back

=head1 DEFAULT SETTINGS

=over

=item *

C<comp_root> is set to L<$env-E<gt>comps_dir|Poet::Environment/comps_dir>, by
default the C<comps> subdirectory under the environment root.

=item *

C<data_dir> is set to L<$env-E<gt>data_dir|Poet::Environment/data_dir>, by
default the C<data> subdirectory under the environment root.

=item *

C<plugins> is set to include L<HTMLFilters|Mason::Plugins::HTMLFilters> and
L<RouterSimple|Mason::Plugins::RouterSimple>.

=item *

C<allow_globals> is set to include C<$conf> and $<env>.

=back

=head1 CONFIGURATION

The Poet configuration entry 'mason', if any, will be treated as a hash of
options that supplements and/or overrides the defaults above.

If you specify plugins, you'll need to explicitly include the default plugins
above if you still want them. e.g.

    mason:
        plugins:
           - HTMLFilters
           - RouterSimple
           - AnotherFavoritePlugin

=head1 POET VARIABLES IN COMPONENTS

L<Poet variables|Poet/POET VARIABLES> C<$conf> and C<$env> are automatically
made available as package globals in all Mason components.

C<$m->E<gt>cache> and C<$m->E<gt>log> will get you the cache and log objects
for a particular Mason component.

=head1 NEW REQUEST METHODS

Under Poet these additional methods are accessible in components via C<$m>.

=over

=item req ()

A reference to the L<Plack::Request> object. e.g.

    my $user_agent = $m->req->headers->header('User-Agent');

=item res ()

A reference to the L<Plack::Response> object. e.g.

    $m->res->content_type('text/plain');

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

=item abort (status)

=item clear_and_abort (status)

These methods are overriden to set the response status before aborting, if
I<status> is provided. e.g. to send back a FORBIDDEN result:

    $m->clear_and_abort(403);

This is equivalent to

    $m->res->status(403);
    $m->clear_and_abort();

=back
