package <% $app_name %>::Mason;
use Poet qw($conf $env);
use strict;
use warnings;
use base qw(Mason);

sub new {
    my $class = shift;

    my %defaults = (
        comp_root => $env->comps_dir,
        data_dir  => $env->data_dir,
        plugins   => ["PSGIHandler"],
        %{ $conf->get_hash_from_common_prefix("mason.") },
    );
    return $class->SUPER::new(%defaults, @_);
}

1;
