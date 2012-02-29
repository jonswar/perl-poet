use Poet::Script qw($conf $env);
use Plack::Builder;
use warnings;
use strict;

builder {

    # Add Plack middleware here
    #
    if ( $conf->is_development ) {
        enable "Plack::Middleware::StackTrace";
    }
    enable "Plack::Middleware::Static",
      path => qr{^/static/},
      root => $env->root_dir;

    my $interp = Poet::Mason->current_interp;

    sub {
        my $psgi_env = shift;
        $interp->handle_psgi($psgi_env);
    };
};
