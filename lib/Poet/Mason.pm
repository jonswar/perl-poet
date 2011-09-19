package Poet::Mason;
use Poet qw($conf $env);
use Method::Signatures::Simple ();
use base qw(Mason);

method new ($class:) {
    my $default_plugins = $conf->get_list( 'mason.plugins' => ['PSGIHandler'] );
    my %defaults = (
        comp_root => $env->comps_dir,
        data_dir  => $env->data_dir,
        plugins   => $default_plugins,
    );
    my $mason_root_class = $conf->get( 'mason.root_class' => 'Mason' );
    return $mason_root_class->SUPER::new(@_);
}

1;

__END__
