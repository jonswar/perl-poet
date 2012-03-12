package Poet::Vars;
use Method::Signatures::Simple;
use strict;
use warnings;

method valid_import_params () { qw($cache $conf $env $log) };

method import ($caller, $env, @vars) {
    foreach my $var (@vars) {
        if ( substr( $var, 0, 1 ) eq '$' ) {
            my $bare_var = substr( $var, 1 );
            my $provide_method = "provide_" . $bare_var;
            if ( $self->can($provide_method) ) {
                my $value = $self->$provide_method( $caller, $env );
                no strict 'refs';
                *{ $caller . "\::$bare_var" } = \$value;
                next;
            }
        }
        die sprintf(
            "unknown import parameter '$var' passed to Poet: valid import parameters are %s",
            join( ", ", map { "'$_'" } $self->valid_import_params ) );
    }
}

method provide_cache ($caller, $env) {
    $env->app_class('Cache')->new();
}

method provide_conf ($caller, $env) {
    $env->conf();
}

method provide_env ($caller, $env) {
    $env;
}

method provide_log ($caller, $env) {
    require Log::Any;
    Log::Any->get_logger( category => $caller );
}

1;
