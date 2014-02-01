package Poet::t::Environment;

use Test::Class::Most parent => 'Poet::Test::Class';
use Poet::Tools qw(mkpath tempdir_simple write_file);
use Poet::Environment::Generator;

sub test_environment : Tests {
    my $self = shift;

    my $app_name = 'TheTestApp';
    my $poet     = $self->temp_env( app_name => $app_name );
    my $root_dir = $poet->root_dir;

    foreach my $subdir (qw(bin conf lib)) {
        my $subdir_method = $subdir . "_dir";
        is( $poet->$subdir_method, "$root_dir/$subdir", $subdir_method );
        ok( -d $poet->$subdir_method, "$subdir exists" );
        ok( -d $poet->path($subdir),  "$subdir exists" );
    }
    is( $poet->conf->layer, 'development', "layer" );
    foreach my $class (qw(Conf Log Mason)) {
        my $file = $poet->lib_path("$app_name/$class.pm");
        ok( -f $file, "$file exists" );
    }
    ok( -x $poet->bin_path("run.pl"), "run.pl executable" );
    ok( -x $poet->bin_path("get.pl"), "get.pl executable" );
}

sub test_dot_files_in_share_dir : Tests {
    my $self = shift;
    return 'author testing' if $ENV{AUTHOR_TESTING};
    require File::Copy::Recursive;

    my $share_dir = $self->share_dir;
    my $temp_dir  = tempdir_simple();
    File::Copy::Recursive::rcopy( $share_dir, $temp_dir ) or die $!;
    my $gen_dir = "$temp_dir/generate.skel";
    my @paths = ( "$gen_dir/extra", "$gen_dir/.git", "$gen_dir/bin/.svn" );
    foreach my $path (@paths) {
        mkpath( $path, 0, 0775 );
        write_file( "$path/hi.txt", "hi" );
    }
    my $env_dir = $self->temp_env_dir( share_dir => $temp_dir );
    ok( -d "$env_dir/extra",     "extra exists" );
    ok( !-d "$env_dir/.git",     ".git does not exist" );
    ok( !-d "$env_dir/bin/.svn", ".svn does not exist" );
}

1;
