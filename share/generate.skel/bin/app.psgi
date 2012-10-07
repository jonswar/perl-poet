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
        enable "StackTrace";
        enable "Debug";
    }

    enable "ErrorDocument", map { $_ => $poet->static_path("errors/$_.html") } qw(401 403 404 500);

    if ( $conf->is_live ) {
        enable "HTTPExceptions", rethrow => 0;
    }

    enable "Static",
      path => qr{^/static/},
      root => $poet->root_dir;

    enable "Session",
      store => Plack::Session::Store::Cache->new(
        cache => $poet->app_class('Cache')->new( namespace => 'session' ) );

    sub {
        my $psgi_env = shift;
        $poet->app_class('Mason')->handle_psgi($psgi_env);
    };
};
