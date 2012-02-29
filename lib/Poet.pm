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

Poet -- A web framework for Mason developers

=head1 LOGGING

Poet uses the Log::Log4perl engine for logging, but with a much simpler
configuration for the common cases. See L<Poet::Log|Poet::Log>.

=head1 POET VARIABLES

The variables are:

=over

=item $cache

The cache for the current package, provided by L<CHI|CHI> or a subclass
thereof.

=item $conf

The global configuration object, provided by L<Poet::Conf|Poet::Conf>.

=item $env

The global environment object, provided by
L<Poet::Environment|Poet::Environment>.

=item $log

The logger for the current package, provided by L<Log::Any|Log::Any>.

=back

In a module: 'use Poet'. In a script: 'use Poet::Script'.

=for readme continue

=head1 ACKNOWLEDGEMENTS

Poet was originally designed and developed for the Digital Media group of the
Hearst Corporation, a diversified media company based in New York City.  Many
thanks to Hearst for agreeing to this open source release. Hearst has no direct
involvement with this open source release and bears no responsibility for its
support or maintenance.

=cut
