package <% $app_name %>::Mason;
use Poet qw($conf $env);
use Poet::Moose;

extends 'Poet::Mason';

# You can create Mason subclasses in <% $app_name %>/Mason, e.g.
# <% $app_name %>::Mason::Request, and they will be autodetected by Mason.

1;
