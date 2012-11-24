#!<% Poet::Tools::perl_executable %>
#
# Runs plackup with appropriate options
#
use Poet::Script qw($conf $poet);
use Plack::Runner;
use strict;
use warnings;

my $app_psgi = $poet->bin_path("app.psgi");
my $server = $poet->app_class('Server');

# Get plackup options based on config (e.g. server.port) and layer
#
my @options = $server->get_plackup_options();

my @argv = (@options, $app_psgi);
print "Running " . join(", ", "plackup", @argv) . "\n";
my $runner = Plack::Runner->new;
$runner->parse_options(@argv);
$runner->run;
