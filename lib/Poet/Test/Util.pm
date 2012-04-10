package Poet::Test::Util;
use Cwd qw(realpath);
use File::Basename;
use File::Path;
use File::Slurp;
use Poet::Environment;
use Poet::Environment::Generator;
use Poet::Util qw(tempdir_simple);
use YAML::XS qw();
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT = qw(initialize_temp_env temp_env temp_env_dir write_conf_file);

sub write_conf_file {
    my ( $conf_file, $conf_content ) = @_;

    if ( ref($conf_content) eq 'HASH' ) {
        $conf_content = %$conf_content ? YAML::XS::Dump($conf_content) : "";
    }
    mkpath( dirname($conf_file), 0, 0775 );
    write_file( $conf_file, $conf_content );
}

sub temp_env {
    my (%params) = @_;

    my $root_dir = temp_env_dir(%params);
    my $app_name = $params{app_name} || 'TestApp';
    if ( my $conf = $params{conf} ) {
        write_conf_file( "$root_dir/conf/local.cfg", $conf );
    }
    if ( my $conf_files = $params{conf_files} ) {
        while ( my ( $conf_file, $contents ) = each(%$conf_files) ) {
            write_conf_file( "$root_dir/conf/$conf_file", $contents );
        }
    }
    return Poet::Environment->new(
        root_dir => $root_dir,
        app_name => $app_name
    );
}

sub temp_env_dir {
    my (%params) = @_;

    local $ENV{POET_SHARE_DIR} =
      dirname( dirname( dirname( dirname( realpath(__FILE__) ) ) ) ) . "/share";
    my $app_name = $params{app_name} || 'TestApp';
    my $root_dir = Poet::Environment::Generator->generate_environment_directory(
        root_dir => tempdir_simple('Poet-XXXX'),
        app_name => $app_name,
        quiet    => 1,
        style    => 'bare',
    );
    return realpath($root_dir);
}

sub initialize_temp_env {
    my $env = temp_env(@_);
    Poet::Environment->initialize_current_environment( env => $env );
}

# prevent YAML::XS warning...wtf
YAML::XS::Dump( {} );
YAML::XS::Dump( {} );

1;
