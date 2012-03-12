package Poet::Server;
use Poet qw($conf $env);
use strict;
use warnings;

method get_options ($class:) {
    my %defaults = (
        app => $env->root_path("app.psgi"),
        env => $conf->layer,
        %{ $conf->get_hash("server") },
    );
    if ( $conf->is_development ) {
        $defaults{Reload} = join( ",", $class->_reload_dirs );
    }
    else {
        $defaults{access_log} = $env->log_path("access.log");
    }
    return ( %defaults, %{ $conf->get_hash("server") } );
}

method plackup ($class:) {
    my $options = $class->get_options;
    my @run_args = map { ( "--$_", $options->{$_} ) } sort( keys(%$options) );
    print "running plackup " . join( " ", @run_args ) . "\n";
    run( "plackup", @run_args );
}

method _reload_dirs () {
    return ( $env->root_dir, $env->conf_dir, $env->lib_dir );
}

1;
