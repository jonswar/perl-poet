#!perl -w
#
# Test Log::Log4perl not being present.
#
use Test::Most qw(defer_plan);
use Module::Mask;
use Poet::Test::Util;
use Poet::Util qw(read_file);
use strict;
use warnings;

my $mask = new Module::Mask ('Log::Log4perl');
my $env = initialize_temp_env();
my $error_file = $env->logs_path("poet.log.ERROR");
ok(-f $error_file, "$error_file exists");
like(read_file($error_file), qr/Could not load Log::Log4perl/);
all_done;
