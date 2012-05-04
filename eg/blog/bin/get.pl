#!/usr/local/bin/perl
use Poet::Script qw($env);
use Poet::Mechanize;
use warnings;
use strict;

my $url = shift(@ARGV) or die "usage: $0 url";
my $mech = Poet::Mechanize->new();
$mech->get($url);
if ( $mech->success ) {
    print $mech->content;
}
else {
    printf( "error getting '%s': %d\n%s",
        $url, $mech->status, $mech->content ? $mech->content . "\n" : '' );
}

__END__

=pod

=head1 NAME

get.pl - Get a URL via command line without a running server

=head1 SYNOPSIS

   get.pl url

=head1 DESCRIPTION

Runs a request through your Poet application in a single process without
actually requiring a running server. The request will use the same psgi.app
and pass through all the same middleware, etc. Uses
L<Test::WWW::Mechanize::PSGI|Test::WWW::Mechanize::PSGI>.

The url scheme and host are optional, so either of these will work:

    get.pl /action
    get.pl http://localhost/action

Because the request runs in a single process, it's easy to run through a debugger:

    perl -d get.pl /action

or profiler:

    perl -d:NYTProf get.pl /action
    nytprofhtml

=cut