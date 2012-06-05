use Poet::Script qw($conf $poet);
use Plack::Builder;
use Plack::Session::Store::Cache;
use strict;
use warnings;

# Load modules configured in server.load_modules
#
$poet->app_class('Server')->load_startup_modules();

builder {

    # Add Plack middleware here
    #
    if ( $conf->is_development ) {
        enable "Plack::Middleware::StackTrace";
        enable "Plack::Middleware::Debug";
    }

    enable "Plack::Middleware::Static",
      path => qr{^/static/},
      root => $poet->root_dir;

    enable "Plack::Middleware::Session",
      store => Plack::Session::Store::Cache->new(
        cache => $poet->app_class('Cache')->new( namespace => 'session' ) );

    sub {
        my $psgi_env = shift;
        $poet->app_class('Mason')->handle_psgi($psgi_env);
    };
};
