package Poet::Server;
use Poet qw($conf $poet);
use Method::Signatures::Simple;
use Class::Load;
use strict;
use warnings;

method get_plackup_options () {

    my @options;

    # Pass -E with the layer name, e.g. "development" or "production"
    #
    push( @options, '-E', $conf->layer );

    if ( defined( my $port = $conf->get('server.port') ) ) {
        push( @options, '--port', $port );
    }
    if ( defined( my $host = $conf->get('server.host') ) ) {
        push( @options, '--host', $host );
    }

    if ( $conf->is_development ) {

        # In development mode, reload server when conf or lib file changes
        #
        push( @options, '-R', join( ",", $poet->conf_dir, $poet->lib_dir ) );
    }
    else {

        # In live mode, use access log instead of STDERR
        #
        push( @options, '--access_log', $poet->logs_path("access.log") );
    }

    return @options;
}

my $loaded_startup_modules;

method load_startup_modules () {
    return if $loaded_startup_modules++;
    foreach my $module ( @{ $conf->get_list('server.load_modules') } ) {
        Class::Load::load_class($module);
    }
}

1;
