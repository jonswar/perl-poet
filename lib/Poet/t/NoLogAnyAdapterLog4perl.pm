# Test Log::Any::Adapter::Log4perl not being present.
#
package Poet::t::NoLogAnyAdapterLog4perl;
use Test::Class::Most parent => 'Poet::Test::Class';
use Module::Mask;
use Poet::Tools qw(read_file);
use strict;
use warnings;

sub test_no_log4perl : Tests {
    my $self       = shift;
    my $mask       = new Module::Mask('Log::Any::Adapter::Log4perl');
    my $env        = $self->initialize_temp_env();
    my $error_file = $env->logs_path("poet.log.ERROR");
    ok( -f $error_file, "$error_file exists" );
    like( read_file($error_file), qr/Could not load/ );
}

1;
