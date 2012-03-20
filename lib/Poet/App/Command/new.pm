package Poet::App::Command::new;
use Poet::Moose;
use Poet::Types;

extends 'MooseX::App::Cmd::Command';

has 'app_name' => ( isa => 'Poet::Types::AppName', traits => ['Getopt'], cmd_flag => 'app-name', cmd_aliases => 'a', documentation => 'Name of app, e.g. MyApp or ABC', default => 'MyApp' );
has 'dir'      => ( isa => 'Str', traits => ['Getopt'], cmd_aliases => 'd', lazy_build => 1, documentation => 'Directory to create; will adapt from app-name if ommitted' );
has 'quiet'    => ( isa => 'Bool', traits => ['Getopt'], cmd_aliases => 'q', documentation => 'Suppress most messages' );

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

method abstract () {
    "Create a new Poet installation";
}

method execute () {
    require Poet::Environment::Generator;
    Poet::Environment::Generator->generate_environment_directory(
        root_dir => $self->dir,
        app_name => $self->app_name,
        quiet    => $self->quiet
    );
}

1;
