package Poet::t::Conf;
use Poet::Test::Util;
use Test::Most;
use strict;
use warnings;
use base qw(Test::Class);

require Poet;

my $conf_files = {
    'global/first.cfg'          => { a => 10, b => 6, c => 11, d => 12 },
    'global/second.cfg'         => { e => 20 },
    'global/third-not-a-config' => { f => 30 },
    'layer/personal.cfg'    => { c => 40, g => 50, h => 51 },
    'layer/development.cfg' => { f => 30 },
    'local.cfg' => { h => 60, layer => 'personal' },
};

my $expected_values = {
    a => 10,
    b => 6,
    c => 40,
    d => 12,
    e => 20,
    f => undef,
    g => 50,
    h => 60,
};

sub test_global : Test(9) {
    my $env = temp_env( conf_files => $conf_files );
    my $conf = $env->conf();
    while ( my ( $key, $value ) = each(%$expected_values) ) {
        is( $conf->get($key), $value,
            "$key = " . ( defined($value) ? $value : 'undef' ) );
    }
}

sub test_duplicate : Test(1) {
    throws_ok(
        sub {
            temp_env( conf_files =>
                  { %$conf_files, 'global/fourth.cfg' => { j => 71, c => 72 } }
            );
        },
        qr/key 'c' defined in both '.*(first|fourth)\.cfg' and '.*(first|fourth)\.cfg'/,
        'cannot define same key in multiple global config files'
    );
}

sub test_set_local : Test(12) {
    my $env = temp_env(
        conf_files => { 'global/foo.cfg' => { a => 5, b => 6, c => 7 } } );
    my $conf = $env->conf();

    is( $conf->get('a'), 5, 'a = 5' );
    is( $conf->get( 'b' => 0 ), 6, 'b = 6' );
    is( $conf->get('c'), 7, 'c = 7' );

    {
        my $lex = $conf->set_local( { a => 15, c => 17 } );
        is( $conf->get('a'), 15, 'a = 15 (set_local)' );
        is( $conf->get('b'), 6,  'b = 6 (set_local)' );
        is( $conf->get('c'), 17, 'c = 17 (set_local)' );
        {
            my $lex = $conf->set_local( { c => 27 } );
            is( $conf->get('c'), 27, 'c = 27 (set_local depth 2)' );

            my $lex2 = $conf->set_local( { c => 37 } );
            $lex2 = 'shiny';
            is( $conf->get('c'), 27, 'c = 27 (did not hold on to lexical)' );
        }
        is( $conf->get('c'), 17, 'c = 17 (set_local)' );
    }

    is( $conf->get('a'), 5, 'a = 5 (restored)' );
    is( $conf->get('b'), 6, 'b = 6 (restored)' );
    is( $conf->get('c'), 7, 'c = 7 (restored)' );
}

1;
