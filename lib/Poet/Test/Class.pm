package Poet::Test::Class;
use Method::Signatures::Simple;
use Carp;
use Cwd qw(realpath);
use File::Basename;
use File::Path;
use Plack::Util;
use Poet::Environment::Generator;
use Poet::Environment;
use Poet::Mechanize;
use Poet::Tools qw(tempdir_simple write_file);
use Test::Class::Most;
use YAML::XS;
use strict;
use warnings;

__PACKAGE__->SKIP_CLASS("abstract base class");

method write_conf_file ($class:) {
    my ( $conf_file, $conf_content ) = @_;

    if ( ref($conf_content) eq 'HASH' ) {
        $conf_content = %$conf_content ? YAML::XS::Dump($conf_content) : "";
    }
    mkpath( dirname($conf_file), 0, 0775 );
    write_file( $conf_file, $conf_content );
}

method temp_env ($class:) {
    my (%params) = @_;

    my $root_dir = $class->temp_env_dir(%params);
    my $app_name = $params{app_name} || 'TestApp';
    if ( my $conf = $params{conf} ) {
        $class->write_conf_file( "$root_dir/conf/local.cfg", $conf );
    }
    if ( my $conf_files = $params{conf_files} ) {
        while ( my ( $conf_file, $contents ) = each(%$conf_files) ) {
            $class->write_conf_file( "$root_dir/conf/$conf_file", $contents );
        }
    }
    return Poet::Environment->new(
        root_dir => $root_dir,
        app_name => $app_name
    );
}

method temp_env_dir ($class:) {
    my (%params) = @_;

    local $ENV{POET_SHARE_DIR} = $params{share_dir} || $class->share_dir;

    my $app_name = $params{app_name} || 'TestApp';
    my $root_dir = Poet::Environment::Generator->generate_environment_directory(
        root_dir => tempdir_simple('Poet-XXXX'),
        app_name => $app_name,
        quiet    => 1,
        style    => 'bare',
    );
    return realpath($root_dir);
}

method share_dir () {
    my $dist_root =
      dirname( dirname( dirname( dirname( realpath(__FILE__) ) ) ) );
    my ($share_dir) =
      grep { -d $_ }
      ( "$dist_root/share", "$dist_root/lib/auto/share/dist/Poet" );
    return $share_dir;
}

method initialize_temp_env ($class:) {
    my $poet = $class->temp_env(@_);
    Poet::Environment->initialize_current_environment( env => $poet );
}

method mech ($class:) {
    return Poet::Mechanize->new(@_);
}

# prevent YAML::XS warning...wtf
YAML::XS::Dump( {} );
YAML::XS::Dump( {} );

1;
