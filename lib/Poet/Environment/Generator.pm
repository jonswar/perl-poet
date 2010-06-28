package Poet::Environment::Generator;
use File::Path;
use strict;
use warnings;

my ( $root_marker_template, $local_cfg_template );

sub generate_environment_directory {
    my ( $class, $root_dir ) = @_;

    my $root_dir = $params{root_dir} or die "must specify root_dir";
    if ( $root_dir eq 'TEMP' ) {
        $root_dir = tempdir( "poet-XXXX", TMPDIR => 1, CLEANUP => 1 );
    }
    else {
        $root_dir = realpath($root_dir);
    }

    die
      "cannot generate environment in $root_dir - directory exists and is non-empty"
      if ( -d $root_dir && @{ read_dir($root_dir) } );

    my @standard_subdirs = @{ Poet::Environment->subdirs() };
    foreach my $subdir (@standard_subdirs) {
        my $full_dir = catdir( $root_dir, split( '/', $subdir ) );
        mkpath( $full_dir, 0, 0775 );
    }

    my $root_marker_filename = Poet::Environment::root_marker_filename();
    my %standard_files       = (
        $root_marker_filename => $root_marker_template,
        'conf/local.cfg'      => $local_cfg_template,
    );
    while ( my ( $subfile, $body ) = each(%standard_files) ) {
        my $full_file = catdir( $root_dir, split( '/', $subfile ) );
        trim($body);
        write_file( $full_file, $body );
        chmod( 0664, $full_file );
    }

    return $root_dir;
}

$root_marker_template = '
$Id: $

This file marks the directory as a Poet environment root. Do not delete.
';

$local_cfg_template = '
# $Id: $
#
# Contains configuration local to this instance of
# the environment. This file should not be checked into
# version control.
';

1;
