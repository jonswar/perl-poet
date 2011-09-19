package Poet::Environment;
use Carp;
use Poet::Conf;
use File::Basename;
use File::Path;
use File::Slurp;
use Poet::Moose;
use Poet::Util qw(can_load catdir);

has 'app_name' => ( required => 1 );
has 'conf'     => ();

my ($current_env);

method subdirs () { [qw(bin comps conf data lib logs static t)] }

method app_class ($class_name) {
    my $app_specific_class = join( "::", $self->app_name, $class_name );
    return can_load($app_specific_class) ? $app_specific_class : $class_name;
}

method generate_subdir_methods ($class:) {
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

method initialize_current_environment ($class:) {
    if ( defined($current_env) ) {
        die sprintf(
            "initialize_current_environment called when current_env already set (%s)",
            $current_env->root_dir() );
    }
    $current_env = $class->new(@_);
}

method get_environment ($class:) {
    return $current_env;
}

method layer ()       { $self->conf->layer }
method is_internal () { $self->conf->is_internal }
method is_live ()     { $self->conf->is_live }

method BUILD () {
    my $root_dir = $self->root_dir();

    # Initialize configuration
    #
    $self->{conf} =
      $self->app_class('Poet::Conf')
      ->new( conf_dir => catdir( $root_dir, "conf" ) );
    my $conf = $self->{conf};

    # Determine where our standard subdirectories (bin, comps, etc.)
    # are. Can override in configuration with env.bin_dir, env.comps_dir,
    # etc.  Otherwise use obvious defaults.
    #
    foreach my $subdir ( @{ $self->subdirs() } ) {
        my $method = $subdir . "_dir";
        $self->{$method} = $conf->get( "env.$method" => "$root_dir/$subdir" );
    }
}

__PACKAGE__->generate_subdir_methods();
__PACKAGE__->meta->make_immutable();

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

Returns the current layer of the environment, e.g. 'development' or
'production'. The full list of layers is defined by the files in conf/layer.

=item root_dir

Returns the root directory of the environment, i.e. where I<.poet_root> is
located.

=item bin_dir

=item comps_dir

=item conf_dir

=item css_dir

=item data_dir

=item images_dir

=item js_dir

=item lib_dir

=item logs_dir

=item static_dir

Returns the specified subdirectory, which by default will be in the obvious
place (just below the root directory for most, just below the static directory
for C<css>, C<images> and C<js>). Any of these other than conf_dir can be
overriden in configuration. e.g.

    # Override bin_dir
    env.bin_dir: /some/other/bin/dir

=item bin_path (path)

=item conf_path (path)

=item css_path (path)

=item data_path (path)

=item images_path (path)

=item js_path (path)

=item lib_path (path)

=item logs_path (path)

=item static_path (path)

Returns the specified subdirectory with a relative path added. e.g.

    $env->conf_path("log4perl.conf");
    $env->lib_path("Data/Type.pm");

=back

=head1 SEE ALSO

Poet

=head1 AUTHOR

Jonathan Swartz

