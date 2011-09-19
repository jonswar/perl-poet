use Poet::Script qw($conf $env $interp);
use Plack::Builder;
use warnings;
use strict;

builder {

    # Add Plack middleware here
    #
    if ( $env->is_internal ) {
        enable "Plack::Middleware::StackTrace";
    }
    enable "Plack::Middleware::Static",
      path => qr{^/static/},
      root => $env->root_dir;

    sub {
        my $psgi_env = shift;
        $interp->handle_psgi($psgi_env);
    };
};
