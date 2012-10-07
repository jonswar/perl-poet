package Poet::Mason::Plugin::Request;
use Mason::PluginRole;
use Poet qw($conf $poet);
use Poet::Plack::Response;
use JSON::XS;
use Try::Tiny;

has 'req' => ( is => 'ro', required => 1, isa => 'Object' );
has 'res' => ( is => 'ro', required => 1, isa => 'Object' );

around 'run' => sub {
    my $orig = shift;
    my $self = shift;

    my $result = $self->$orig(@_);
    $self->res->status(200) if !$self->res->status;
    $self->res->content_type( $conf->get( 'server.default_content_type' => 'text/html' ) )
      if !$self->res->content_type();
    $self->res->content( $result->output );
    return $result;
};

around 'construct_page_component' => sub {
    my $orig = shift;
    my $self = shift;
    my ( $compc, $args ) = @_;

    if ( blessed($args) && $args->can('get_all') ) {
        my $orig_args = $args;
        $args = $orig_args->as_hashref;

        # TODO: cache this
        my @array_attrs =
          map { $_->name }
          grep { $_->has_type_constraint && $_->type_constraint->is_a_type_of('ArrayRef') }
          $compc->meta->get_all_attributes;
        foreach my $attr (@array_attrs) {
            $args->{$attr} = [ $orig_args->get_all($attr) ];
        }
    }

    $self->$orig( $compc, $args );
};

override 'catch_abort' => sub {
    my ( $self, $code ) = @_;
    my $retval;
    try {
        $retval = $code->();
    }
    catch {
        my $err = $_;
        if ( $self->aborted($err) ) {
            $retval = $err->aborted_value;
        }
        else {
            local $SIG{__DIE__} = undef;
            die $err;
        }
    };
    return $retval;
};

before 'abort' => sub {
    my ( $self, $retval ) = @_;
    $self->res->status($retval) if defined($retval);
};

method redirect () {
    $self->res->redirect(@_);
    $self->clear_and_abort();
}

method not_found () {
    $self->clear_and_abort(404);
}

method session () {
    $self->req->session;
}

method send_json ($data) {
    $self->clear_buffer;
    $self->print( JSON::XS::encode_json($data) );
    $self->res->content_type("application/json");
    $self->abort();
}

1;
