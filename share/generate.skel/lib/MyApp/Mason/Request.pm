package <% $app_name %>::Mason::Request;
use Poet qw($conf $poet);
use Poet::Moose;

extends 'Mason::Request';

# Add customizations to Mason::Request here.
#
# e.g. Perform tasks before and after each Mason request
#
# override 'run' => sub {
#     my $self = shift;
#
#     do_tasks_before_request();
#
#     my $result = super();
#
#     do_tasks_after_request();
#
#     return $result;
# };

1;
