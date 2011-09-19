package Poet::Environment::Generator;
use Cwd qw(realpath);
use File::Basename;
use File::Path;
use File::Slurp;
use File::Temp qw(tempdir);
use Poet::Environment;
use Poet::Moose;
use Text::Trim qw(trim);
use strict;
use warnings;

my $root_marker_file = '.poet_root';
my @static_subdirs   = qw(css images js);

my (
    $app_psgi_template,  $global_cfg_template, $layer_cfg_template,
    $local_cfg_template, $root_marker_template
);

method generate_environment_directory ($class: %params) {
    my $root_dir = $params{root_dir};
    die "must specify root_dir" unless defined $root_dir;

    $root_dir = realpath($root_dir);
    my $app_name = $params{app_name} || basename($root_dir);
    die "invalid app_name '$app_name' - must be a valid Perl identifier"
      unless $app_name =~ qr/[[:alpha:]_]\w*/;

    die
      "cannot generate environment in $root_dir - directory exists and is non-empty"
      if ( -d $root_dir && @{ read_dir($root_dir) } );

    my @subdirs = (
        @{ Poet::Environment->subdirs() },
        ( map { "static/$_" } @static_subdirs ), "conf/layer"
    );
    foreach my $subdir (@subdirs) {
        my $full_dir = join( '/', $root_dir, $subdir );
        mkpath( $full_dir, 0, 0775 );
    }

    my %standard_files = (
        'conf/local.cfg' => $local_cfg_template,
        'app.psgi'       => $app_psgi_template,
    );

    my $generate = sub {
        my ( $subfile, $body ) = @_;
        my $full_file = join( '/', $root_dir, $subfile );
        trim($body);
        write_file( $full_file, $body );
        chmod( 0664, $full_file );
    };

    $generate->(
        $root_marker_file, sprintf( $root_marker_template, $app_name )
    );
    $generate->( 'conf/local.cfg', $local_cfg_template );
    $generate->( 'app.psgi',       $app_psgi_template );
    foreach my $layer (qw(personal development staging production)) {
        my $full_file = "$root_dir/conf/layer/$layer.cfg";
        $generate->(
            "conf/layer/$layer.cfg", sprintf( $layer_cfg_template, $layer )
        );
    }
    $generate->( "conf/global.cfg", $global_cfg_template );

    return $root_dir;
}

$app_psgi_template = '
use Poet::Script qw($conf $env $interp);
use Plack::Builder;
use warnings;
use strict;

builder {

    # Add Plack middleware here
    #
    if ($env->is_internal) {
        enable "Plack::Middleware::StackTrace";
    }

    sub {
        my $psgi_env = shift;
        $interp->handle_psgi($psgi_env);
    };
};
';

$root_marker_template = '
# Marks the Poet environment root. Do not delete.
app_name: %s
';

$local_cfg_template = '
# Contains configuration local to this environment.
# This file should not be checked into version control.

layer: personal
';

$layer_cfg_template = '
# Contains configuration specific to the %s layer.
';

$global_cfg_template = '
# Contains global configuration.
';

1;
