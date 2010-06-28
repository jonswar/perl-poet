# $Id: $
#
package Poet::Environment;
use Carp;
use Carp::Assert;
use Poet::Conf;
use File::Basename;
use File::Path;
use File::Spec::Functions qw(catdir rel2abs);
use Moose;

has 'conf'    => ( is => 'ro' );
has 'name'    => ( is => 'ro' );
has 'version' => ( is => 'ro', lazy_build => 1 );

__PACKAGE__->generate_subdir_methods();

__PACKAGE__->meta->make_immutable();

my ($current_env);

sub subdirs              { [qw(bin conf lib logs state)] }
sub root_marker_filename { '.poet_root' }

sub initialize_current_environment {
    my ( $class, $root_dir ) = @_;

    if ( defined($current_env) ) {
        die sprintf(
            "initialize_current_environment called when current_env already set (%s)",
            $current_env->root_dir() );
    }
    $current_env = $class->new( root_dir => $root_dir );
}

sub get_environment {
    my ($class) = @_;

    return $current_env;
}

sub layer {
    my ($self) = @_;

    return $self->conf->layer;
}

sub BUILD {
    my ($self) = @_;

    my $root_dir             = $self->root_dir();
    my $root_marker_filename = $self->root_marker_filename();
    die
      "$root_dir is missing marker file $root_marker_filename - is it really an Poet environment root?"
      unless -f "$root_dir/$root_marker_filename";
    $self->{name} = basename($root_dir);

    # Initialize configuration
    #
    $self->{conf} = Poet::Conf->new( conf_dir => catdir( $root_dir, "conf" ) );
    my $conf = $self->{conf};

    # Determine where our standard subdirectories (bin, comps, etc.)
    # are. Can override in configuration with env.bin_dir, env.comps_dir, etc.,
    # which may be absolute or relative to root dir. Otherwise use obvious defaults.
    #
    foreach my $subdir ( @{ $self->subdirs() } ) {
        my $method = $subdir . "_dir";
        $self->{$method} =
          rel2abs( $conf->get( "env.$method" => $subdir ), $root_dir );
    }
}

sub generate_subdir_methods {
    my $class = shift;

    foreach my $subdir ( 'root', @{ $class->subdirs() } ) {
        my $dir_method = $subdir . "_dir";
        has $dir_method =>
          ( is => 'ro', ( $subdir eq 'root' ? ( required => 1 ) : () ) );
        my $path_method = $subdir . "_path";
        __PACKAGE__->meta->add_method(
            $path_method,
            sub {
                my ( $self, $relpath ) = @_;
                croak "$path_method expects relative path as argument"
                  unless defined($relpath);
                return $self->$dir_method . "/" . $relpath;
            }
        );
    }
}

1;

__END__

=pod

=head1 NAME

Poet::Environment -- Access to Poet environment

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw($env);

    # In a module...
    use Poet qw($env);

    # $env is automatically available in components

=head1 DESCRIPTION

Poet::Environment provides a singleton, $env, which gives information about the
current environment such as directory paths and layer.

=head1 METHODS

=over

=item layer

Returns the current layer of the environment. The full list of layers is
defined by the files in conf/layer.

=item root_dir

Returns the root directory of the environment, i.e. where I<.poet_root> is
located.

=item bin_dir

=item conf_dir

=item lib_dir

=item logs_dir

=item state_dir

Returns the specified subdirectory, which by default will be in the obvious
place just below the root directory. Any of these other than conf_dir can be
overriden in configuration. e.g.

    # Override bin_dir
    bin_dir: /some/other/bin/dir

=item bin_path (path)

=item conf_path (path)

=item lib_path (path)

=item logs_path (path)

=item state_path (path)

Returns the specified subdirectory with a relative path added. e.g.

    $env->conf_path("log4perl.conf");
    $env->lib_path("Data/Type.pm");

=back

=head1 SEE ALSO

Poet

=head1 AUTHOR

Jonathan Swartz

