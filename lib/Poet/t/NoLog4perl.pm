# Test Log::Log4perl or Log::Any::Adapter::Log4perl not being present.
#
package Poet::t::NoLog4perl;
use Test::Class::Most parent => 'Poet::Test::Class';
use Module::Mask;
use Poet::Tools qw(read_file);
use strict;
use warnings;

sub test_no_log4perl : Tests {
    my $self       = shift;
    my $poet       = $self->initialize_temp_env();
    my $error_file = $poet->logs_path("poet.log.ERROR");
    ok( -f $error_file, "$error_file exists" );
    like( read_file($error_file), qr/Could not load Log::Log4perl/ );
}

1;
