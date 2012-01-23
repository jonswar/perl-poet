package Poet::Environment;
use Carp;
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
    my $app_class_name = join( "::", $self->app_name, $class_name );
    return
        can_load($app_class_name) ? $app_class_name
      : can_load($class_name)     ? $class_name
      :   die "cannot load $app_class_name or $class_name";
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

method layer ()          { $self->conf->layer }
method is_development () { $self->conf->is_development }
method is_live ()        { $self->conf->is_live }

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

    # Initialize logging
    #
    $self->{log_manager} =
      $self->app_class('Poet::Log::Manager')->new( env => $self );
    $self->{log_manager}->initialize_logging();
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

    # $env is automatically available in Mason components

    # then...
    my $layer          = $env->layer;
    my $root_dir       = $env->root_dir;
    my $path_to_script = $env->bin_path("foo/bar.pl");

    if ($env->is_development) {
        debug_mode('on');
    }

=head1 DESCRIPTION

The Poet::Environment object contains general information about the current
environment such as layer (e.g. 'development' or 'production') and directory
paths.

=head1 METHODS

=over

=item layer

Returns the current layer of the environment, e.g. 'development' or
'production'. The full list of layers is determined by the conf files in
conf/layer.

=item is_development

Returns true if the current layer is 'development'.

=item is_live

Returns true if the current layer is 'staging' or 'production'.

=item root_dir

Returns the root directory of the environment, i.e. where I<.poet_root> is
located.

=item bin_dir

=item comps_dir

=item conf_dir

=item data_dir

=item lib_dir

=item logs_dir

=item static_dir

Returns the specified subdirectory, which by default will be just below the
root dirctory. e.g. if the Poet environment root is C</my/env/root>, then

    $env->conf_dir
       ==> returns /my/env/root/conf

    $env->lib_dir
       ==> returns /my/env/root/lib

=item bin_path (subpath)

=item comps_path (subpath)

=item conf_path (subpath)

=item data_path (subpath)

=item lib_path (subpath)

=item logs_path (subpath)

=item static_path (subpath)

Returns the specified subdirectory with a relative I<subpath> added. e.g. if
the Poet environment root is C</my/env/root>, then

    $env->conf_path("log4perl.conf");
       ==> returns /my/env/root/conf/log4perl.conf

    $env->lib_path("Data/Type.pm");
       ==> returns /my/env/root/lib/Data/Type.pm

=item app_name

Returns the app name, e.g. 'MyApp', found in .poet_root.

=item conf

Returns the L<Poet::Conf|Poet::Conf> object associated with the environment.
Usually you'd access this by importing C<$conf>.

    my $conf = $env->conf;

=item current_environment

A class method that returns the current (singleton) environment for the
process. Usually you'd access this by importing C<$env>.

    my $env = Poet::Environment->current_environment;

=back

=head1 OVERRIDING ENVIRONMENT SUBDIRECTORIES

Any subdirectories other than conf_dir can be overriden in configuration. e.g.

    # Override bin_dir
    env.bin_dir: /some/other/bin/dir

With this configuration in place,

    $env->bin_dir
       ==> returns /some/other/bin/dir

    $env->bin_path("foo/bar.pl")
       ==> returns /some/other/bin/dir/foo/bar.pl

=head1 SEE ALSO

Poet

