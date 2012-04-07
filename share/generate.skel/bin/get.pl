#!/usr/bin/perl
use Poet::Script;
use <% $app_name %>::Server;
use warnings;
use strict;

my $url = shift(@ARGV) or die "usage: $0 url";
<% $app_name %>::Server->make_psgi_test_request($url);
