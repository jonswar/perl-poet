package Poet::t::Environment;
use Test::Class::Most parent => 'Poet::Test::Class';
use Poet::Environment::Generator;

sub test_environment : Tests {
    my $self = shift;

    my $app_name = 'TheTestApp';
    my $env      = $self->temp_env( app_name => $app_name );
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
