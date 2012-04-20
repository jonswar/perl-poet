package Poet::t::Environment;
use File::Slurp;
use Poet::Environment::Generator;
use Poet::Test::Util;
use Test::Most;
use YAML::XS;
use strict;
use warnings;
use base qw(Test::Class);

sub test_environment : Tests {
    my $self = shift;

    my $app_name = 'TheTestApp';
    my $env      = temp_env( app_name => $app_name );
    my $root_dir = $env->root_dir;

    foreach my $subdir (qw(bin conf lib)) {
        my $subdir_method = $subdir . "_dir";
        is( $env->$subdir_method, "$root_dir/$subdir", $subdir_method );
        ok( -d $env->$subdir_method, "$subdir exists" );
    }
    is( $env->conf->layer, 'development', "layer" );
    foreach my $class (qw(Conf Log Mason)) {
        my $file = $env->lib_path("$app_name/$class.pm");
        ok( -f $file, "$file exists" );
    }
}

1;
