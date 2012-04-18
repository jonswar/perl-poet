package Poet::t::Script;
use Capture::Tiny qw(capture);
use Cwd qw(realpath);
use File::Basename;
use File::Path;
use File::Slurp;
use IPC::System::Simple qw(run);
use Poet::Test::Util;
use Poet::Util qw(tempdir_simple);
use Test::Most;
use YAML::XS;
use strict;
use warnings;
use base qw(Test::Class);

my $script_template;

sub test_script : Tests {
    my $self     = shift;
    my $root_dir = temp_env_dir();

    write_conf_file( "$root_dir/conf/global/server.cfg", { 'foo.bar' => 42 } );

    my $script = "$root_dir/bin/foo/bar.pl";
    mkpath( dirname($script), 0, 0775 );
    my $poet_lib_dir = realpath("lib");
    write_file( $script, sprintf( $script_template, $poet_lib_dir ) );
    chmod( 0775, $script );
    my ( $stdout, $stderr ) = capture { system($script) };
    ok( !$stderr, "no stderr" . ( defined($stderr) ? " - $stderr" : "" ) );

    my $result = Load($stdout);
    is_deeply( $result, [ $root_dir, "$root_dir/lib", "$root_dir/lib", 42 ] );
}

$script_template = '#!/usr/bin/env perl
use lib qw(%s);
use Poet::Script qw($conf $env);
use YAML::XS;

print Dump([$env->root_dir, $env->lib_dir, $INC[0], $conf->get("foo.bar")]);
';

1;
