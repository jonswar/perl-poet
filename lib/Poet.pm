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
        my $env = Poet::Environment->instance
          or die "environment has not been initialized!";
        $env->app_class('Poet::Importer')->import( $caller, $env, @vars );
    }
}

1;

__END__

=pod

=head1 NAME

Poet -- A web framework for Mason developers

=head1 ENVIRONMENT

When using Poet, your entire web site lives within a single directory hierarchy
called the environment. The environment contains subdirectories for
configuration, logs, components, static files, etc.

None of your code or conf files need to know what the environment root is; it
is determined automatically upon Poet initialization. If you move your entire
environment to a different directory, things should just work.

You can get easy access to subdirectories and files under the environment via
L<Poet::Environment|Poet::Environment>.

=head1 CONFIGURATION

Poet configuration lives in one or more files in the C<conf/> subdirectory. The
format is L<YAML|http://www.yaml.org/> augmented with variable substitution.
See L<Poet::Conf|Poet::Conf>.

=head1 LOGGING

Poet uses the L<Log::Log4perl|Log::Log4perl> engine for logging, but with a
much simpler configuration for the common cases. See L<Poet::Log|Poet::Log>.

=head1 CACHING

Poet uses L<CHI|CHI> for caching, providing access to a wide variety of cache
backends (memory, files, memcached, etc.) You can configure caching for
different namespaces in Poet conf files. See L<Poet::Cache|Poet::Cache>.

=head1 POET VARIABLES

Certain variables are so integral to Poet development that Poet makes it easy
to grab them from the air, without having to explicitly call an accessor.  Some
of them are globals, and some of them are specific to each package.

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

=head2 Accessing in a script

    use Poet::Script qw($conf $env ...);

This will import the specified variables into the script namespace (usually
C<main>).

=head2 Accessing in a module

    use Poet qw($conf $env ...);

This will import the specified variables into the package's namespace.

=head2 Accessing in a Mason component

C<$conf> and C<$env> are automatically available as package globals in all
Mason components.  C<$m->E<gt>cache> and C<$m->E<gt>log> will get you the cache
and log objects for a particular Mason component.

=for readme continue

=head2 

=head1 ACKNOWLEDGEMENTS

Poet was originally designed and developed for the Digital Media group of the
Hearst Corporation, a diversified media company based in New York City.  Many
thanks to Hearst for agreeing to this open source release. Hearst has no direct
involvement with this open source release and bears no responsibility for its
support or maintenance.

=cut
