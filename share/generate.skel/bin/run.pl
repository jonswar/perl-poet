#!<% Poet::Tools::perl_executable %>
#
# Runs plackup with appropriate options
#
use Poet::Script qw($conf $poet);
use IPC::System::Simple qw(run);
use strict;
use warnings;

my $app_psgi = $poet->bin_path("app.psgi");
my $server = $poet->app_class('Server');

# Get plackup options based on config (e.g. server.port) and layer
#
my @options = $server->get_plackup_options();

my @cmd = ("plackup", @options, $app_psgi);
print "Running " . join(", ", @cmd) . "\n";
run(@cmd);
