package Poet::t::Run;
use Poet::Test::Util;
use Guard;
use IO::Socket;
use IPC::System::Simple qw(run);
use Test::WWW::Mechanize;
use Test::Most;
use strict;
use warnings;
use base qw(Test::Class);

sub test_run : Tests {
    my $env = temp_env(
        conf => { layer => 'development', plackup => { port => 9999 } } );
    my $root_dir = $env->root_dir;
    if ( my $pid = fork() ) {
        scope_guard { kill( 1, $pid ) };
        sleep(2);
        ok( is_port_active( 9999, '127.0.0.1' ), "port 9999 active" );

        my $mech = Test::WWW::Mechanize->new;
        $mech->get_ok('http://127.0.0.1:9999/');
        $mech->content_like(qr/Welcome to Poet/);
        $mech->content_like(qr/Environment root.*\Q$root_dir\E/);
    }
    else {
        close STDOUT;
        close STDERR;
        exec( $env->bin_path("run.pl") );
    }
}

sub is_port_active {
    my ( $port, $bind_addr ) = @_;

    return IO::Socket::INET->new(
        PeerAddr => $bind_addr,
        PeerPort => $port
    ) ? 1 : 0;
}

1;
