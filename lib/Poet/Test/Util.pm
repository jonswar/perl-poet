package Poet::Test::Util;
use File::Basename;
use File::Path;
use File::Slurp;
use Poet::Environment::Generator;
use YAML::XS;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT = qw(temp_env write_conf_file);

sub write_conf_file {
    my ( $conf_file, $conf_content ) = @_;

    if ( ref($conf_content) eq 'HASH' ) {
        $conf_content = Dump($conf_content);
    }
    mkpath( dirname($conf_file), 0, 0775 );
    write_file( $conf_file, $conf_content );
}

sub temp_env {
    my (%params) = @_;

    my $root_dir =
      Poet::Environment::Generator->generate_environment_directory(
        root_dir => 'TEMP' );
    if ( my $conf_files = $params{conf_files} ) {
        while ( my ( $conf_file, $contents ) = each(%$conf_files) ) {
            write_conf_file( "$root_dir/conf/$conf_file", $contents );
        }
    }
    return Poet::Environment->new( root_dir => $root_dir );
}

1;
