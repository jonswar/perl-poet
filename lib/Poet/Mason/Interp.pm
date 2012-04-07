package Poet::Mason::Interp;
use Poet::Moose;
use Poet::Plack::Request;
use Try::Tiny;

extends 'Mason::Interp';

method handle_psgi ($env) {
    my $req      = Poet::Plack::Request->new($env);
    my $response = try {
        my $m = $self->_make_request( req => $req );
        $m->run( $self->psgi_comp_path($req), $self->psgi_parameters($req) );
        $m->res;
    }
    catch {
        my $err = $_;
        if ( blessed($err) && $err->isa('Mason::Exception::TopLevelNotFound') )
        {
            Poet::Plack::Response->new(404);
        }
        else {

            # Prevent Plack::Middleware::Debug from capturing this stack point
            local $SIG{__DIE__} = undef;
            die $err;
        }
    };
    return $response->finalize;
}

method psgi_comp_path ($req) {
    my $comp_path = $req->path;
    $comp_path = "/$comp_path" if substr( $comp_path, 0, 1 ) ne '/';
    return $comp_path;
}

method psgi_parameters ($req) {
    return $req->parameters;
}

1;
