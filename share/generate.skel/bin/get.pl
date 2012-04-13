#!/usr/bin/perl
use Poet::Script qw($env);
use Poet::Test::Util;
use warnings;
use strict;

my $url = shift(@ARGV) or die "usage: $0 url";
my $mech = build_test_mech($env);
$mech->get($url);
if ( $mech->success ) {
    print $mech->content;
}
else {
    printf( "error getting '%s': %d\n%s",
        $url, $mech->status, $mech->content ? $mech->content . "\n" : '' );
}
