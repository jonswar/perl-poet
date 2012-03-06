package Poet::Mason;
use Poet qw($conf $env);
use List::MoreUtils qw(uniq);
use Method::Signatures::Simple ();
use Moose;

extends 'Mason';

my $instance;

sub instance {
    $instance ||= Mason->new();
    $instance;
}

sub get_defaults {
    my @plugins = uniq( @{ $conf->get_list("mason.plugins") }, 'PSGIHandler' );
    my %defaults = (
        comp_root => $env->comps_dir,
        data_dir  => $env->data_dir,
        plugins   => \@plugins,
        %{ $conf->get_hash_from_common_prefix("mason.") },
    );
    return %defaults;
}

sub new {
    my $class = shift;

    return $class->SUPER::new( $class->get_defaults, @_ );
}

1;

__END__
