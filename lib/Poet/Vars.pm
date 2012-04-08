package Poet::Vars;
use Method::Signatures::Simple;
use strict;
use warnings;

method valid_vars () { qw($cache $conf $env $log) };

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
            join( ", ", map { "'$_'" } $self->valid_vars ) );
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

__END__

=pod

=head1 NAME

Poet::Vars -- Implements Poet special variables

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw($cache $conf $env $log);

    # In a module...
    use Poet qw($cache $conf $env $log);

=head1 DESCRIPTION

This module implements the L<Poet variables|Poet/POET VARIABLES> that can be
easily imported into any module or script. There is no user API here.

=head1 ADDING YOUR OWN VARIABLES

To add your own variable, say C<$dbh>, to this list, create a C<MyApp::Vars>
subclass like so:

    package MyApp::Vars;
    use Poet::Moose;
    extends 'Poet::Vars';
    
    method provide_dbh ($caller, $env) {
        # Generate and return a dbh.
        # $caller is the package importing the variable.
        # $env is the current Poet environment.
    }

C<provide_dbh> can return a single global value, or a dynamic value depending
on C<$caller>.

Now your scripts and libraries can do

    use Poet::Script qw($dbh);
    use Poet qw($dbh);
