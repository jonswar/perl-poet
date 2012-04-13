package Poet::Environment::Generator;
use Cwd qw(realpath);
use File::Basename;
use File::Path;
use File::ShareDir;
use File::Slurp qw(read_dir);
use Mason;
use Method::Signatures::Simple;
use Poet::Util qw(write_file);
use Text::Trim qw(trim);
use strict;
use warnings;

method generate_environment_directory ($class: %params) {
    my $root_dir = $params{root_dir} or die "must specify root_dir";
    my $app_name = $params{app_name} || basename($root_dir);
    my $quiet    = $params{quiet};
    my $style    = $params{style} || 'standard';
    my $msg      = sub {
        print "$_[0]\n" unless $quiet;
    };

    die "invalid app_name '$app_name' - must be a valid Perl identifier"
      unless $app_name =~ qr/[[:alpha:]_]\w*/;
    die
      "cannot generate environment in $root_dir - directory exists and is non-empty"
      if ( -d $root_dir && @{ read_dir($root_dir) } );

    my $share_dir =
      realpath( $ENV{POET_SHARE_DIR} || File::ShareDir::dist_dir('Poet') );
    die "cannot find Poet share dir '$share_dir'" unless -d $share_dir;
    my $comp_root = "$share_dir/generate.skel";
    my $interp    = Mason->new(
        comp_root               => $comp_root,
        autoextend_request_path => 0,
        top_level_regex         => qr/./,
        allow_globals           => [qw($app_name $root_dir)],
    );
    $interp->set_global( '$app_name' => $app_name );
    $interp->set_global( '$root_dir' => $root_dir );

    my @paths = $interp->all_paths()
      or die "could not find template components";

    foreach my $path (@paths) {
        my $output = trim( $interp->run($path)->output );
        my $dest   = $root_dir . $path;
        mkpath( dirname($dest), 0, 0775 );
        if ( $path =~ /\.empty$/ ) {
            $msg->( dirname($dest) );
        }
        else {
            $msg->($dest);
            write_file( $dest, $output );
        }
    }

    rename( "$root_dir/lib/MyApp", "$root_dir/lib/$app_name" )
      unless $app_name eq 'MyApp';

    chmod( 0775, glob("$root_dir/bin/*.pl") );
    $msg->("\nNow run '$root_dir/bin/run.pl' to start your server.");

    return $root_dir;
}

1;
