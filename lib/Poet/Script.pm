# $Id: $
#
# Add the appropriate lib path to @INC and initialize Poet.
#
package Poet::Script;
use File::Basename;
use strict;
use warnings;

sub import {
    my $pkg = shift;

    my $root_dir = determine_root_dir();
    my $lib_dir  = "$root_dir/lib";

    require Poet;
    Poet->initialize_environment( run_mode => $run_mode );
    Poet->export_to_level( 1, undef, @_ );
}

sub determine_root_dir {
    my $script_dir = dirname($0);
    my $path       = $script_dir;
    my $root_dir;

    my $lastpath = '';
    while ( length($path) > 1 && $path ne $lastpath ) {
        if ( -f "$path/.poet_root" ) {
            $root_dir = $path;
            last;
        }
        $lastpath = $path;
        $path     = dirname($path);
    }
    unless ( defined $root_dir ) {
        die
          "could not find Poet environment root upwards from script dir '$script_dir'";
    }
    return $root_dir;
}

1;
