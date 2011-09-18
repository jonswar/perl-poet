# $Id: $
#
package Poet::Importer;
use Poet::Moose;

has 'caller' => ( required => 1 );
has 'env'    => ( required => 1 );

# todo: determine from mop
method valid_import_params  () { qw(cache conf env log) };

method import (@vars) {
    foreach my $var (@vars) {
        if ( substr( $var, 0, 1 ) eq '$' ) {
            my $bare_var = substr( $var, 1 );
            my $provide_method = "provide_" . $bare_var;
            if ( $self->can($provide_method) ) {
                my $value = $self->$provide_method();
                no strict 'refs';
                *{ $self->caller . "\::$bare_var" } = \$value;
                next;
            }
        }
        die sprintf(
            "unknown import parameter '$var' passed to Poet: valid import parameters are %s",
            join( ", ", map { "'$_'" } $self->valid_import_params ) );
    }
}

method provide_cache () {
    require CHI;
    my %cache_defaults =
      %{ $self->env->conf->get_hash_from_common_prefix('cache.defaults.') };
    if ( !%cache_defaults ) {
        %cache_defaults = (
            driver   => 'File',
            root_dir => $self->env->data_path("cache")
        );
    }
    CHI->new( %cache_defaults, namespace => $self->caller );
}

method provide_conf () {
    $self->env->conf();
}

method provide_env () {
    $self->env;
}

method provide_log () {
    require Log::Any;
    Log::Any->get_logger( category => $self->caller );
}

__PACKAGE__->meta->make_immutable();

1;
