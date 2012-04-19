package Poet;
use Poet::Environment;
use Method::Signatures::Simple;
use strict;
use warnings;

method import ($class:) {
    my $env = Poet::Environment->current_env
      or die "environment has not been initialized!";
    $env->importer->export_to_level( 1, @_ );
}

1;

__END__

=pod

=head1 NAME

Poet -- a web framework for Mason developers

=head1 SYNOPSIS

  % poet new MyApp

=head1 DESCRIPTION

Poet is a modern Perl web framework for Mason developers. It uses
L<PSGI|PSGI>/L<Plack|Plack> for server integration, L<Mason|Mason> for request
routing and templating, and a selection of best-of-breed CPAN modules for
caching, logging and configuration.

Poet gives you:

=over

=item *

A common-sense directory hierarchy for web development

=item *

A multi-file configuration system with support for development/production
layers and concurrent development

=item *

Easy access to configuration, caching and logging facilities

=back

Poet's conventions and defaults are based on the author's best practices from
15+ years of Mason site development. That said, Poet was designed to be
flexible; if you see a decision you don't like, you can generally change it
with a subclass.

All documentation is indexed at L<Poet::Manual>.

=head1 SUPPORT

For now Poet will share a mailing list and IRC with Mason. The Mason mailing
list is L<mason-users@lists.sourceforge.net>; you must be
L<subscribed|https://lists.sourceforge.net/lists/listinfo/mason-users> to send
a message. The Mason IRC channel is L<#mason|irc://irc.perl.org/#mason>.

Bugs and feature requests will be tracked at RT:

    http://rt.cpan.org/NoAuth/Bugs.html?Dist=Poet
    bug-poet@rt.cpan.org

The latest source code can be browsed and fetched at:

    http://github.com/jonswar/perl-poet
    git clone git://github.com/jonswar/perl-poet.git

=head1 ACKNOWLEDGEMENTS

Poet was originally designed and developed for the Digital Media group of the
Hearst Corporation, a diversified media company based in New York City.  Many
thanks to Hearst for agreeing to this open source release. Hearst has no direct
involvement with this open source release and bears no responsibility for its
support or maintenance.

