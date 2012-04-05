package Poet::App::Command::new;
use Poet::Moose;
use Poet::Types;

extends 'Poet::App::Command';

has 'app_name' => ( isa => 'Poet::Types::AppName', is => 'rw', traits => [ 'NoGetopt' ] );
has 'dir'      => ( isa => 'Str', traits => ['Getopt'], cmd_aliases => 'd', lazy_build => 1, documentation => 'Directory to create; will adapt from app-name if ommitted' );
has 'quiet'    => ( isa => 'Bool', traits => ['Getopt'], cmd_aliases => 'q', documentation => 'Suppress most messages' );

my $description =
  'Generates a new Poet environment for an app with the provided name, which
should be suitable for use in Perl classnames (e.g. "MyFirstApp"). If not
provided, a directory is chosen by lowercasing and underscoring the app
name.

    % poet new MyApp
    my_app/bin/run
    my_app/comps/Base.mc
    ...

Options:';

method abstract ()    { "Create a new Poet installation" }
method description () { $description }
method usage_desc ()  { "poet new [-d dir] [-q] <AppName>" }

method _build_dir () {
    return $self->app_name_to_dir( $self->app_name );
}

method app_name_to_dir ($app_name) {
    my $dir;
    if ( $app_name =~ /^[A-Z]+$/ ) {
        $dir = lc($app_name);
    }
    else {
        $dir = lcfirst($app_name);
        $dir =~ s/([A-Z])/"_" . lc($1)/ge;
    }
    return $dir;
}

method execute ($opt, $args) {
    $self->usage_error("takes one argument (app name)") unless @$args == 1;
    $self->app_name( $args->[0] );

    require Poet::Environment::Generator;
    Poet::Environment::Generator->generate_environment_directory(
        root_dir => $self->dir,
        app_name => $self->app_name,
        quiet    => $self->quiet
    );
}

1;
