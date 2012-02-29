package Poet;
use Poet::Environment;
use Poet::Importer;
use Method::Signatures::Simple;
use strict;
use warnings;

method import ($class:) {
    $class->export_to_level( 1, undef, @_ );
}

method export_to_level ($class: $level, $ignore, @params) {

    # Import requested globals into caller.
    #
    if ( my @vars = grep { /^\$/ } @params ) {
        my ($caller) = caller($level);
        my $env = Poet::Environment->get_environment()
          or die "environment has not been initialized!";
        $env->app_class('Poet::Importer')->import( $caller, $env, @vars );
    }
}

1;

__END__

=pod

=head1 NAME

Poet -- Import Poet variables into current package

=head1 SYNOPSIS

    # In a module...
    use Poet qw($cache $conf $env $log);

=head1 DESCRIPTION

For information about the Poet framework see L<Poet::Manual>.

The sole purpose of 'use Poet' is to import standard Poet variables into the
current package. You can import the same variables from 'use Poet::Script' when
initializing a script.

The variables are:

=over

=item $cache

The cache for the current package, provided by L<CHI|CHI>.

=item $conf

The global configuration object provided by L<Poet::Conf|Poet::Conf>.

=item $env

The global environment object provided by
L<Poet::Environment|Poet::Environment>.

=item $log

The logger for the current package, provided by L<Log::Any|Log::Any>.

=back

=head1 SEE ALSO

L<Poet::Script|Poet::Script>, L<Poet::Manual|Poet::Manual>

=for readme continue

=head1 ACKNOWLEDGEMENTS

Poet was originally designed and developed for the Digital Media group of the
Hearst Corporation, a diversified media company based in New York City.  Many
thanks to Hearst for agreeing to this open source release. Hearst has no direct
involvement with this open source release and bears no responsibility for its
support or maintenance.

=cut
