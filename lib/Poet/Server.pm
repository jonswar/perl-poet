package Poet::Server;
use Poet qw($conf $env);
use Plack::Builder;
use Plack::Runner;
use Method::Signatures::Simple;
use IPC::System::Simple qw(run);
use strict;
use warnings;

method get_plackup_options ($class:) {
    my %defaults = (
        env => $conf->layer,
        %{ $conf->get_hash("plackup") },
    );
    if ( $conf->is_internal ) {
        $defaults{Reload} = join( ",", $class->_reload_dirs );
    }
    else {
        $defaults{access_log} = $env->log_path("access.log");
    }
    return ( %defaults, %{ $conf->get_hash("server") } );
}

method plackup ($class:) {
    my %options = $class->get_plackup_options;
    my @run_args = map { ( "--$_", $options{$_} ) } sort( keys(%options) );
    print "running plackup " . join( " ", @run_args ) . "\n";

    my $app    = $class->build_psgi_app();
    my $runner = Plack::Runner->new;
    $runner->parse_options(@run_args);
    $runner->run($app);
}

method build_psgi_app ($class:) {
    builder {
        if ( $conf->is_internal ) {
            enable "Plack::Middleware::StackTrace";
            enable "Plack::Middleware::Debug";
        }
        enable "Plack::Middleware::Static",
          path => qr{^/static/},
          root => $env->root_dir;

        my $interp = $env->app_class('Mason')->instance;

        sub {
            my $psgi_env = shift;
            $interp->handle_psgi($psgi_env);
        };
    }
}

method build_test_mech ($class:) {
    require Test::WWW::Mechanize::PSGI;
    return Test::WWW::Mechanize::PSGI->new( app => $class->build_psgi_app );
}

method make_psgi_test_request ($class: $url) {
    my $mech = $class->build_test_mech();
    $mech->get($url);
    if ( $mech->success ) {
        print $mech->content;
    }
    else {
        printf( "error getting '%s': %d\n%s",
            $url, $mech->status, $mech->content ? $mech->content . "\n" : '' );
    }
}

method _reload_dirs () {
    return ( $env->conf_dir, $env->lib_dir );
}

1;

__END__

=pod

=head1 NAME

Poet::Server -- Implements PSGI app and plackup

=head1 DESCRIPTION

This module is responsible for building the PSGI app and running plackup with
settings appropriate to the Poet environment.

=head1 METHODS

These methods can be overriden or modified with method modifiers in
L<subclasses|<Poet::Subclasses>.

=over

=item get_plackup_options

Returns a hash of plackup options. The keys will be prepended with "--" to turn
this into a set of command-line options.

By default, this returns something like

    env => "development",                   # from $conf->layer
    Reload => ...,                          # only in development
    access_log => "<root>/logs/access.log", # only in production

plus anything in the Poet configuration entry 'plackup'.

=item plackup

Runs plackup with the options from L</get_plackup_options>.

=item build_psgi_app

Builds the PSGI app with an appropriate set of middleware. By default,

=over

=item *

Plack::Middleware::StackTrace and Plack::Middleware::Debug are added in
development

=item *

Plack::Middleware::Static is used for /static paths

=item *

The request is handed off to Mason for dispatch and rendering

=back
