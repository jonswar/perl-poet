package Poet::t::Conf;
use Test::Class::Most parent => 'Poet::Test::Class';

require Poet;

my $conf_files = {
    'global/first.cfg'          => { a => 10, b => 6, c => 11, d => 12 },
    'global/second.cfg'         => { e => 20 },
    'global/third-not-a-config' => { f => 30 },
    'layer/personal.cfg'    => { c => 40, g => '_${b}', h => 51 },
    'layer/development.cfg' => { f => 30 },
    'local.cfg' => { h => '__${e}', layer => 'personal' },
};

my $expected_values = {
    a => 10,
    b => 6,
    c => 40,
    d => 12,
    e => 20,
    f => undef,
    g => "_6",
    h => "__20",
};

sub test_global : Tests {
    my $self = shift;
    my $env  = $self->temp_env( conf_files => $conf_files );
    my $conf = $env->conf();
    while ( my ( $key, $value ) = each(%$expected_values) ) {
        is( $conf->get($key), $value,
            "$key = " . ( defined($value) ? $value : 'undef' ) );
    }
}

sub test_duplicate : Tests {
    my $self = shift;
    throws_ok(
        sub {
            $self->temp_env( conf_files =>
                  { %$conf_files, 'global/fourth.cfg' => { j => 71, c => 72 } }
            );
        },
        qr/key 'c' defined in both '.*(first|fourth)\.cfg' and '.*(first|fourth)\.cfg'/,
        'cannot define same key in multiple global config files'
    );
}

sub test_set_local : Tests {
    my $self = shift;
    my $env  = $self->temp_env(
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

sub test_dot_notation : Tests {
    my $self       = shift;
    my $conf_files = {
        'layer/personal.cfg' => '
a:
   b:
      c: 1
      d: 2
e:
   f:
      g: 3
      h: 4
',
        'local.cfg' => '
layer: personal
a.b.c: 6
e:
   f:
      g: 7

'
    };
    my $env = $self->temp_env( conf_files => $conf_files );
    my %expected_values = (
        'a' => { 'b' => { c => 6, d => 2 } },
        'a.b'   => { c => 6, d => 2 },
        'a.b.c' => 6,
        'a.b.d' => 2,
        'e'     => { f => { g => 7 } },
        'e.f'   => { g => 7 },
        'e.f.g' => 7,
        'x.y.z' => undef
    );
    my $conf           = $env->conf();
    my $check_expected = sub {
        my $desc = shift;
        foreach my $key ( sort( keys(%expected_values) ) ) {
            my $value = $expected_values{$key};
            cmp_deeply( $conf->get($key), $value, "$key - $desc" );
        }
    };

    $check_expected->('initial');
    throws_ok( sub { $conf->get('a.b.c.z') },
        qr/hash value expected for conf key 'a.b.c', got non-hash '6'/,
        "a.b.c.z" );

    $conf_files->{'layer/personal.cfg'} = { 'a' => { 'b' => 17 } };
    throws_ok(
        sub { $env = $self->temp_env( conf_files => $conf_files ) },
        qr/error assigning to 'a.b.c' in .*; 'a.b' already has non-hash value/,
        "e.f: 17"
    );

    {
        my $lex = $conf->set_local( { 'a.b.c' => 16 } );
        local $expected_values{'a'} = { 'b' => { c => 16, d => 2 } },
          local $expected_values{'a.b'} = { c => 16, d => 2 };
        local $expected_values{'a.b.c'} = 16;
        $check_expected->('set_local');
    }

    $check_expected->('after set_local');
}

sub test_types : Tests {
    my $self       = shift;
    my $truth      = { c => 't', d => 'true', e => 'y', f => 'yes' };
    my $falsity    = { c => 'f', d => 'false', e => 'n', f => 'no' };
    my $conf_files = {
        'global.cfg' => {
            scalar  => 5,
            list    => [ 1, 2, 3 ],
            hash    => { size => 'large', flavor => 'chocolate' },
            truth   => $truth,
            falsity => $falsity,
        }
    };

    my $env = $self->temp_env( conf_files => $conf_files );
    my $conf = $env->conf();

    cmp_deeply( $conf->get_list('list'), [ 1, 2, 3 ], 'list ok' );
    foreach my $key (qw(scalar hash)) {
        throws_ok( sub { $conf->get_list($key) }, qr/list value expected/ );
    }
    cmp_deeply(
        $conf->get_hash('hash'),
        { size => 'large', flavor => 'chocolate' },
        'hash ok'
    );
    foreach my $key (qw(scalar list)) {
        throws_ok( sub { $conf->get_hash($key) }, qr/hash value expected/ );
    }
    foreach my $key (qw(c d e f)) {
        is( $conf->get_boolean("truth.$key"),   1, "$key = true" );
        is( $conf->get_boolean("falsity.$key"), 0, "$key = false" );
    }
    foreach my $key (qw(scalar list hash)) {
        throws_ok( sub { $conf->get_boolean($key) },
            qr/boolean value expected/ );
    }
}

sub test_layer_required : Tests {
    my $self = shift;
    throws_ok(
        sub { $self->temp_env( conf_files => { 'local.cfg' => {} } ) },
        qr/must specify layer/,
        'no layer'
    );
}

sub test_interpolation : Tests {
    my $self = shift;
    my $env  = $self->temp_env(
        conf => {
            layer  => 'development',
            'a.b'  => 'bar',
            'c'    => '/foo/${a.b}/baz',
            'd'    => '/foo/${huh}/baz',
            'deep' => { 'e' => 5, 'f' => [ '${c}', ['${a.b}'] ] }
        }
    );
    my $conf = $env->conf();
    is( $conf->get('c'), '/foo/bar/baz', 'substitution' );
    throws_ok { $conf->get('d') } qr/could not get conf for 'huh'/,
      'bad substitution';
    cmp_deeply(
        $conf->get('deep'),
        {
            e => 5,
            f => [ '/foo/bar/baz', ['bar'] ]
        },
        'deep'
    );

}

1;
