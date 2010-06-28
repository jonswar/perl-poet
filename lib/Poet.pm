package Poet;
use Poet::Environment;
use strict;
use warnings;

our $VERSION = '6.0.0';

sub import {
    my $pkg = shift;
    $pkg->export_to_level( 1, undef, @_ );
}

sub export_to_level {
    my ( $pkg, $level, $ignore, @params ) = @_;

    # Import requested globals into caller.
    #
    my @vars = grep { /^\$/ } @params;
    my @valid_import_params = qw($cache $conf $env $log);
    if (@vars) {
        my ($caller) = caller($level);

        foreach my $var (@vars) {
            my $value;
            if ( $var eq '$conf' ) {
                $value = Poet::Environment->get_environment()->conf()
                  or die "configuration has not been initialized!";
            }
            elsif ( $var eq '$env' ) {
                $value = Poet::Environment->get_environment()
                  or die "environment has not been initialized!";
            }
            elsif ( $var eq '$log' ) {
                $value = Log::Any->get_logger( category => $caller );
            }
            else {
                die sprintf(
                    "unknown import parameter '$var' passed to Poet: valid import parameters are %s",
                    join( ", ", map { "'$_'" } @valid_import_params ) );
            }
            my $no_sigil_var = substr( $var, 1 );
            no strict 'refs';
            *{"$caller\::$no_sigil_var"} = \$value;
        }
    }
}

sub initialize_environment {
    my ( $class, $root_dir ) = @_;
    Poet::Environment->initialize_current_environment($root_dir);
}

sub initialize_environment_if_needed {
    my $class = shift;
    if ( !Poet::Environment->get_environment() ) {
        Poet::Environment->initialize_current_environment(@_);
    }
}

1;

__END__

=pod

=head1 NAME

Poet -- A flexible application environment

=head1 SYNOPSIS

    # In a module...
    use Poet qw($conf $env $log);

=head1 DESCRIPTION

Poet provides a flexible environment for a web or standalone application. It
gives you

=over

=item *

A standard root directory with conf, lib, bin, etc., autodetected from any
script inside the environment

=item *

A multi-file configuration layout with knowledge of different application
"layers"

=item *

Easy one-line access to environment, configuration, caching and logging objects

=back

=for readme stop

=head1 IMPORTS

The sole purpose of 'use Poet' is to import standard Poet variables into the
current package. You can import the same variables from 'use Poet::Script' when
initializing a script.

The variables are:

=over

=item $conf

The global configuration object provided by L<Poet::Conf|Poet::Conf>.

=item $env

The global environment object provided by
L<Poet::Environment|Poet::Environment>.

=item $log

The logger for the current package, provided by L<Log::Any|Log::Any>.

=back

=head1 SEE ALSO

Poet::Script

=for readme continue

=head1 ACKNOWLEDGEMENTS

Poet was originally designed and developed for the Digital Media group of the
Hearst Corporation, a diversified media company based in New York City.  Many
thanks to Hearst management for agreeing to this open source release.

=head1 AUTHOR

Jonathan Swartz

=cut
