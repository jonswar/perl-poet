package Poet::Environment;
use Carp;
use File::Basename;
use File::Path;
use File::Slurp;
use Poet::Moose;
use Poet::Util qw(can_load catdir);

has 'app_name'    => ( required => 1 );
has 'conf'        => ();
has 'log_manager' => ();
has 'root_dir'    => ( required => 1 );

my ($current_env);

method subdirs () { [qw(bin comps conf data lib logs static t)] }

method app_class ($class_name) {
    my $app_class_name  = join( "::", $self->app_name, $class_name );
    my $poet_class_name = join( "::", "Poet",          $class_name );
    return
        can_load($app_class_name)  ? $app_class_name
      : can_load($poet_class_name) ? $poet_class_name
      :   die "cannot load $app_class_name or $class_name";
}

method generate_subdir_methods ($class:) {
    foreach my $subdir ( 'root', @{ $class->subdirs() } ) {
        my $dir_method = $subdir . "_dir";
        has $dir_method => () if $subdir ne 'root';
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

method initialize_current_environment ($class: %params) {
    if ( defined($current_env) ) {
        die sprintf(
            "initialize_current_environment called when current_env already set (%s)",
            $current_env->root_dir() );
    }
    $current_env = $params{env} || $class->new(%params);

    # Initialize logging and caching
    #
    $current_env->app_class('Log')->initialize_logging();
    $current_env->app_class('Cache')->initialize_caching();
}

method instance ($class:) {
    return $current_env;
}

method BUILD () {
    my $root_dir = $self->root_dir();

    # Initialize configuration
    #
    $self->{conf} =
      $self->app_class('Conf')->new( conf_dir => catdir( $root_dir, "conf" ) );
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

Poet::Environment -- Poet environment

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw($env);

    # In a module...
    use Poet qw($env);

    # $env is automatically available in Mason components

    # then...
    my $root_dir       = $env->root_dir;
    my $path_to_script = $env->bin_path("foo/bar.pl");
    my $path_to_lib    = $env->lib_path("Foo/Bar.pm");

=head1 DESCRIPTION

The Poet::Environment object contains information about the current environment
and its directory paths.

=head1 PATH METHODS

=over

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

=back

=head1 OTHER METHODS

=over

=item app_name

Returns the app name, e.g. 'MyApp', found in .poet_root.

=item conf

Returns the L<Poet::Conf|Poet::Conf> object associated with the environment.
Usually you'd access this by importing C<$conf>.

=item instance

A class method that returns the current (singleton) environment for the
process. Usually you'd access this by importing C<$env>.

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

L<Poet|Poet>

