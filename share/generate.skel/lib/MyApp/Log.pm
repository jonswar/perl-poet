package <% $app_name %>::Log;
use Poet qw($conf $poet);
use Poet::Moose;

extends 'Poet::Log';

# Add customizations to Poet::Log here.
#
# e.g. Use Log::Dispatch instead of Log4perl
#
# use Log::Any::Adapter;
# use Log::Dispatch;
#
# override 'initialize_logging' => sub {
#     my $log = Log::Dispatch->new( ... );
#     Log::Any::Adapter->set('Dispatch', dispatcher => $log);
#  };

1;
