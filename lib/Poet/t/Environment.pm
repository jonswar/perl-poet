package Poet::t::Environment;
use File::Slurp;
use Poet::Environment::Generator;
use Poet::Test::Util;
use Test::More;
use YAML::XS;
use strict;
use warnings;
use base qw(Test::Class);

sub test_environment : Tests(7) {
    my $self = shift;

    my $env      = temp_env();
    my $root_dir = $env->root_dir;

    foreach my $subdir qw(bin conf lib) {
        my $subdir_method = $subdir . "_dir";
        is( $env->$subdir_method, "$root_dir/$subdir", $subdir_method );
        ok( -d $env->$subdir_method, "$subdir exists" );
    }
    is( $env->layer, 'development', "layer" );
}

1;
