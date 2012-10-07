package Poet::t::Script;
use Test::Class::Most parent => 'Poet::Test::Class';
use Capture::Tiny qw(capture);
use Cwd qw(realpath);
use YAML::XS;
use Poet::Tools qw(dirname mkpath perl_executable tempdir_simple write_file);

my $script_template;

sub test_script : Tests {
    my $self     = shift;
    my $root_dir = $self->temp_env_dir();

    $self->write_conf_file( "$root_dir/conf/global/server.cfg", { 'foo.bar' => 42 } );

    my $script = "$root_dir/bin/foo/bar.pl";
    mkpath( dirname($script), 0, 0775 );
    my $env_lib_dir = realpath("lib");
    write_file( $script, sprintf( $script_template, perl_executable(), $env_lib_dir ) );
    chmod( 0775, $script );
    my ( $stdout, $stderr ) = capture { system($script) };
    ok( !$stderr, "no stderr" . ( defined($stderr) ? " - $stderr" : "" ) );

    my $result = Load($stdout);
    is_deeply( $result, [ $root_dir, "$root_dir/lib", "$root_dir/lib", 42 ] );
}

$script_template = '#!%s
use lib qw(%s);
use Poet::Script qw($conf $poet);
use YAML::XS;

print Dump([$poet->root_dir, $poet->lib_dir, $INC[0], $conf->get("foo.bar")]);
';

1;
