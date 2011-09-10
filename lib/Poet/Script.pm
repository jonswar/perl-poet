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
    unless ( $INC[0] eq $lib_dir ) {
        unshift( @INC, $lib_dir );
    }

    require Poet;
    require Poet::Environment;
    Poet::Environment->initialize_current_environment($root_dir);
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

=pod

=head1 NAME

Poet::Script -- Intialize the Poet environment for a script

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw($conf $env $log);

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

