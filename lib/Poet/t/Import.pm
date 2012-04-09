package Poet::t::Import;
use Poet::Test::Util;
use Test::Most;
use strict;
use warnings;
use base qw(Test::Class);

my ( $temp_env, $importer );

BEGIN {
    $temp_env = initialize_temp_env();
    $importer = $temp_env->importer;
}

sub test_valid_vars : Tests {
    cmp_deeply( $importer->valid_vars, supersetof(qw(cache conf env log)) );
}

sub test_import_vars : Tests {
    {
        package TestImportVars;
        BEGIN { $importer->export_to_level( 0, qw($cache $conf $env) ) }
        use Test::More;
        isa_ok( $cache, 'CHI::Driver',       '$cache' );
        isa_ok( $conf,  'Poet::Conf',        '$conf' );
        isa_ok( $env,   'Poet::Environment', '$env' );
    }
}

sub test_import_methods : Tests {
    {
        package TestImportMethods1;
        BEGIN { $importer->export_to_level(0) }
        use Test::More;
        ok( TestImportMethods1->can('dp'),        'yes dp' );
        ok( !TestImportMethods1->can('basename'), 'no read_file' );
    }
    {
        package TestImportMethods2;
        BEGIN { $importer->export_to_level( 0, qw(:file) ) }
        use Test::More;
        ok( TestImportMethods2->can('dp'),       'yes dp' );
        ok( TestImportMethods2->can('basename'), 'yes basename' );
    }
    {
        package TestImportMethods3;
        BEGIN { $importer->export_to_level( 0, qw(:web) ) }
        use Test::More;
        ok( TestImportMethods3->can('dp'),          'yes dp' );
        ok( TestImportMethods3->can('html_escape'), 'yes html_escape' );
        ok( TestImportMethods3->can('uri_escape'),  'yes uri_escape' );
    }
}

1;
