package Poet::Script;
use Cwd qw(realpath);
use File::Basename;
use File::Spec::Functions qw(rel2abs);
use Method::Signatures::Simple;
use Poet::Environment;
use Poet::Util qw(can_load read_file);
use strict;
use warnings;

method import ($pkg:) {
    unless ( Poet::Environment->current_env ) {
        my $root_dir = determine_root_dir();
        my $env      = initialize_with_root_dir($root_dir);
    }
    Poet::Environment->current_env->importer->export_to_level( 1, @_ );
}

func initialize_with_root_dir($root_dir) {
    my $lib_dir = "$root_dir/lib";
      unless ( $INC[0] eq $lib_dir ) {
        unshift( @INC, $lib_dir );
    }

    my ($app_name) = ( read_file("$root_dir/.poet_root") =~ /app_name: (.*)/ )
      or die "cannot find app_name in $root_dir/.poet_root";

      return Poet::Environment->initialize_current_environment(
        root_dir => $root_dir,
        app_name => $app_name
      );
  }

  func determine_root_dir() {

    # Search for .poet_root upwards from current directory, using rel2abs
    # first, then realpath.
    #
    my $path1      = dirname( rel2abs($0) );
      my $path2    = dirname( realpath($0) );
      my $root_dir = search_upward($path1) || search_upward($path2);
      unless ( defined $root_dir ) {
        die sprintf( "could not find .poet_root upwards from %s",
            ( $path1 eq $path2 ) ? "'$path1'" : "'$path1' or '$path2'" );
    }
    return $root_dir;
  }

  func search_upward($path) {
    my $count = 0;
      while ( realpath($path) ne '/' && $count++ < 10 ) {
        if ( -f "$path/.poet_root" ) {
            return realpath($path);
            last;
        }
        $path = dirname($path);
    }
    return undef;
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
until it finds the Poet marker file (.poet_root). It then shifts the lib/
subdirectory of the environment root onto @INC.

Imports such as '$conf' and $env' are handled the same way as in 'use Poet' -
see L<Poet/IMPORTS>.

