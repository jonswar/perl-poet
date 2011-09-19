package Poet::Script;
use File::Basename;
use Poet;
use Poet::Util qw(can_load read_file);
use strict;
use warnings;

my $root_marker_file = '.poet_root';

sub import {
    my $pkg = shift;

    my $script_dir = dirname($0);
    my $path       = $script_dir;
    my ( $root_dir, $app_name );

    my $lastpath = '';
    while ( length($path) > 1 && $path ne $lastpath ) {
        my $full_root_marker_file = "$path/$root_marker_file";
        if ( -f $full_root_marker_file ) {
            ($app_name) =
              ( read_file("$full_root_marker_file") =~ /app_name: (.*)/ )
              or die "cannot find app_name in $full_root_marker_file";
            $root_dir = $path;
            last;
        }
        $lastpath = $path;
        $path     = dirname($path);
    }
    unless ( defined $root_dir ) {
        die
          "could not find '$root_marker_file' upwards from script dir '$script_dir'";
    }

    my $lib_dir = "$root_dir/lib";
    unless ( $INC[0] eq $lib_dir ) {
        unshift( @INC, $lib_dir );
    }

    Poet::Environment->initialize_current_environment(
        root_dir => $root_dir,
        app_name => $app_name
    );
    Poet->export_to_level( 1, undef, @_ );
}

1;

=pod

=head1 NAME

Poet::Script -- Intialize the Poet environment for a script

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw($cache $conf $env $log);

=head1 DESCRIPTION

Poet::Script initializes the Poet environment for a script. It determines the
environment root by looking upwards from the directory of the current script
($0) until it finds the Poet marker file (.poet_root). It then shifts the lib/
subdirectory of the environment root onto @INC.

Imports such as '$conf' and $env' are handled the same way as in 'use Poet' -
see L<Poet/IMPORTS>.

=head1 SEE ALSO

Poet

=head1 AUTHOR

Jonathan Swartz

