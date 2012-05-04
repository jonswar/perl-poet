use Poet::Script qw($conf $env);
use Plack::Builder;
use Plack::Session::Store::Cache;
use strict;
use warnings;

# Load modules configured in server.load_modules
#
$env->app_class('Server')->load_startup_modules();

builder {

    # Add Plack middleware here
    #
    if ( $conf->is_development ) {
        enable "Plack::Middleware::StackTrace";
        enable "Plack::Middleware::Debug";
    }

    enable "Plack::Middleware::Static",
      path => qr{^/static/},
      root => $env->root_dir;

    enable "Plack::Middleware::Session",
      store => Plack::Session::Store::Cache->new(
        cache => $env->app_class('Cache')->new( namespace => 'session' ) );

    sub {
        my $psgi_env = shift;
        $env->app_class('Mason')->handle_psgi($psgi_env);
    };
};