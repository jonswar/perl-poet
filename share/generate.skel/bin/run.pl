#!/usr/bin/env perl
#
# Runs plackup with appropriate options
#
use Poet::Script qw($conf $env);
use IPC::System::Simple qw(run);
use Plack::Runner;
use strict;
use warnings;

my $app_psgi = $env->bin_path("app.psgi");

# Pass -E with the layer name, e.g. "development" or "production"
#
my @options = ('-E', $conf->layer);

if ( $conf->is_development ) {

    # In development mode, reload server when conf or lib file changes
    #
    push(@options, '-R', join( ",", $env->conf_dir, $env->lib_dir ));
}
else {

    # In live mode, use access log instead of STDERR
    #
    push(@options, '--access_log', $env->logs_path("access.log"));
}

# Add options from plackup conf entry, e.g.
#
#   plackup:
#      port: 5000
#
my %plackup_conf = %{ $conf->get_hash('plackup') };
push(@options, map { ("--$_", $plackup_conf{$_}) } keys(%plackup_conf));

# Run via Plack::Runner instead of plackup so that environment is already initialized
#
my $runner = Plack::Runner->new;
$runner->parse_options(@options, $app_psgi);
$runner->run;
