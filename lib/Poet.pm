package Poet;
use Poet::Environment;
use Poet::Vars;
use Method::Signatures::Simple;
use strict;
use warnings;

method import ($class:) {
    $class->export_to_level( 1, undef, @_ );
}

method export_to_level ($class: $level, $ignore, @params) {

    # Import requested Poet vars into caller.
    #
    if ( my @vars = grep { /^\$/ } @params ) {
        my ($caller) = caller($level);
        my $env = Poet::Environment->instance
          or die "environment has not been initialized!";
        $env->app_class('Vars')->import( $caller, $env, @vars );
    }
}

1;

__END__

=pod

=head1 NAME

Poet -- a web framework for Mason developers

=head1 SYNOPSIS

  % poet new -a MyApp

=head1 DESCRIPTION

Poet is a web framework for Mason developers. It uses PSGI/Plack for server
integration, Mason for request routing and templating, and a selection of
best-of-breed CPAN modules for caching, logging and configuration.

Poet gives you:

=over

=item *

A standard useful directory hierarchy for web development

=item *

A multi-file configuration system that scales well for multiple developers and
development/production layers

=item *

Easy access to configuration, caching and logging facilities

=back

Poet's conventions and defaults are based on the author's best practices from
15+ years of Mason site development. That said, Poet was designed to be
flexible; if you see a decision you don't like, you can generally change it
with a subclass.

=head2 

=head1 ACKNOWLEDGEMENTS

Poet was originally designed and developed for the Digital Media group of the
Hearst Corporation, a diversified media company based in New York City.  Many
thanks to Hearst for agreeing to this open source release. Hearst has no direct
involvement with this open source release and bears no responsibility for its
support or maintenance.

=cut
