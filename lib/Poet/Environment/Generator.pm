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
    $app_psgi_template,    $chi_class_template, $global_cfg_template,
    $layer_cfg_template,   $local_cfg_template, $mason_class_template,
    $root_marker_template, $run_script_template
);

method generate_environment_directory ($class: %params) {
    my $root_dir = $params{root_dir} or die "must specify root_dir";

    $root_dir = realpath($root_dir);
    my $app_name = $params{app_name} || basename($root_dir);
    die "invalid app_name '$app_name' - must be a valid Perl identifier"
      unless $app_name =~ qr/[[:alpha:]_]\w*/;

    die
      "cannot generate environment in $root_dir - directory exists and is non-empty"
      if ( -d $root_dir && @{ read_dir($root_dir) } );

    my @subdirs = (
        @{ Poet::Environment->subdirs() },
        ( map { "static/$_" } @static_subdirs )
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
        my ( $subfile, $body, $perms ) = @_;
        $perms ||= 0664;
        my $full_file = join( '/', $root_dir, $subfile );
        trim($body);
        mkpath( dirname($full_file), 0, 0775 );
        write_file( $full_file, $body );
        chmod( $perms, $full_file );
    };

    $generate->(
        $root_marker_file, sprintf( $root_marker_template, $app_name )
    );
    $generate->(
        "lib/$app_name/Mason.pm", sprintf( $mason_class_template, $app_name )
    );
    $generate->(
        "lib/$app_name/CHI.pm", sprintf( $chi_class_template, $app_name )
    );
    $generate->( "bin/run", sprintf( $run_script_template, $root_dir ), 0775 );
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

$chi_class_template = '
package %s::CHI;
use Poet qw($conf $env);
use strict;
use warnings;
use base qw(CHI);

sub new {
    my $class = shift;

    my %%defaults = %%{ $conf->get_hash_from_common_prefix("cache.defaults.") };
    if ( !%%defaults ) {
        %%defaults = (
            driver   => "File",
            root_dir => $env->data_path("cache")
        );
    }
    return $class->SUPER::new(@_);
}
';

$global_cfg_template = '
# Contains global configuration.
';

$layer_cfg_template = '
# Contains configuration specific to the %s layer.
';

$local_cfg_template = '
# Contains configuration local to this environment.
# This file should not be checked into version control.

layer: personal
';

$mason_class_template = '
package %s::Mason;
use Poet qw($conf $env);
use strict;
use warnings;
use base qw(Mason);

sub new {
    my $class = shift;

    my %%defaults = (
        comp_root => $env->comps_dir,
        data_dir  => $env->data_dir,
        plugins   => ["PSGIHandler"],
        %%{ $conf->get_hash_from_common_prefix("mason.") },
    );
    return $class->SUPER::new(@_);
}
';

$root_marker_template = '
# Marks the Poet environment root. Do not delete.
app_name: %s
';

$run_script_template = '
#!/bin/sh
plackup -r %s/app.psgi
';

1;
