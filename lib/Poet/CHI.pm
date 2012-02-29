package Poet::CHI;
use Poet qw($conf $env);
use Method::Signatures::Simple ();
use Moose;

extends 'CHI';

sub new {
    my $class = shift;

    my %defaults = %{ $conf->get_hash_from_common_prefix("cache.defaults.") };
    if ( !%defaults ) {
        %defaults = (
            driver   => "File",
            root_dir => $env->data_path("cache")
        );
    }
    return $class->SUPER::new( %defaults, @_ );
}
