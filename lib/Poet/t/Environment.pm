package Poet::t::Environment;
use strict;
use warnings;
use base qw(Test::Class);

require Poet;

sub test_environment : Tests(50) {
    my $self = shift;

    my $root_dir =
      Poet::Environment::Generator->generate_environment_directory(
        root_dir => 'TEMP' );
    foreach my $subdir qw(bin conf lib) {
        ok( -d "$root_dir/$subdir", "$subdir exists" );
    }
    my $env = Poet->initialize_environment($root_dir);
    foreach my $subdir qw(bin conf lib) {
        my $subdir_method = $subdir . "_dir";
        is( $env->$subdir_method, "$root_dir/$subdir", $subdir_method );
    }
}

1;
