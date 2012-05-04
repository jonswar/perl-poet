#!/usr/local/bin/perl
#
# Runs plackup with appropriate options
#
use Poet::Script qw($conf $env);
use IPC::System::Simple qw(run);
use strict;
use warnings;

my $app_psgi = $env->bin_path("app.psgi");
my $server = $env->app_class('Server');

# Get plackup options based on config (e.g. server.port) and layer
#
my @options = $server->get_plackup_options();

my @cmd = ("plackup", @options, $app_psgi);
print "Running " . join(", ", @cmd) . "\n";
run(@cmd);