package Poet;
use Poet::Environment;
use Method::Signatures::Simple;
use strict;
use warnings;

method import ($class:) {
    my $poet = Poet::Environment->current_env
      or die "environment has not been initialized!";
    $poet->importer->export_to_level( 1, @_ );
}

1;

__END__

=pod

=head1 NAME

Poet -- a modern Perl web framework for Mason developers

=head1 SYNOPSIS

  % poet new MyApp
  my_app/.poet_root
  my_app/bin/app.psgi
  ...

  % my_app/bin/run.pl
  Running plackup --Reload ... --env development --port 5000
  Watching ... for file updates.
  HTTP::Server::PSGI: Accepting connections at http://0:5000/

=head1 DESCRIPTION

Poet is a modern Perl web framework designed especially for L<Mason|Mason>
developers. It uses L<PSGI|PSGI>/L<Plack|Plack> for server integration, Mason
for request routing and templating, and a selection of best-of-breed CPAN
modules for caching, logging and configuration.

=head1 FEATURES

=over

=item *

A common-sense L<directory hierarchy|Poet::Environment> for web development

=item *

A L<configuration system|Poet::Conf> that scales elegantly with multiple coders
and multiple layers (development/production)

=item *

Integration with L<Log4perl|Log::Log4perl> for logging, wrapped with
dead-simple configuration

=item *

Integration with L<CHI|CHI> for powerful and flexible caching

=item *

The power of L<Mason|Mason>, an object-oriented templating system, for request
routing and content generation

=item *

Easy access to common L<objects|Poet::Import/QUICK VARS> and
L<utilities|Poet::Import/UTILITIES> from anywhere in your application

=item *

Conventions and defaults based on the author's best practices from over fifteen
years of Perl web development; and

=item *

The freedom to L<override|Poet::Manual::Subclassing> just about any of Poet's
behaviors

=back

=head1 DOCUMENTATION

All documentation is indexed at L<Poet::Manual>.

=head1 SUPPORT

For now Poet will share a mailing list and IRC with Mason. The Mason mailing
list is C<mason-users@lists.sourceforge.net>; you must be
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
Hearst Corporation, a diversified media company based in New York City. Many
thanks to Hearst for agreeing to this open source release. However, Hearst has
no direct involvement with this open source release and bears no responsibility
for its support or maintenance.

=head1 SEE ALSO

L<Mason|Mason>, L<Plack|Plack>, L<PSGI|PSGI>

