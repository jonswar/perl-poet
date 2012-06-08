package Poet::t::Subclassing;
use Poet::Tools qw(write_file);
use Test::Class::Most parent => 'Poet::Test::Class';

sub test_subclassing : Tests {
    my $self = shift;

    my $root_dir = $self->temp_env_dir();
    write_file(
        "$root_dir/lib/TestApp/Cache.pm",
        join( "\n",
            "package TestApp::Cache;",
            "use Poet::Moose;",
            "extends 'Poet::Cache';" )
    );
    write_file(
        "$root_dir/lib/TestApp/Import.pm",
        join( "\n",
            "package TestApp::Import;",
            "use Poet::Moose;",
            "extends 'Poet::Import';" )
    );
    write_file(
        "$root_dir/lib/TestApp/Log.pm",
        join( "\n",
            "package TestApp::Log;",
            "use Poet::Moose;",
            "extends 'Poet::Log';",
            "sub get_logger { return bless({}, 'TestApp::Logger') }",
        )
    );
    my $poet = Poet::Environment->initialize_current_environment(
        root_dir => $root_dir,
        app_name => 'TestApp'
    );
    isa_ok( $poet, 'Poet::Environment', 'env' );    # can't override this yet
    isa_ok( $poet->importer, 'TestApp::Import', 'import' );
    isa_ok( $poet->conf,     'TestApp::Conf',   'conf' );
    is( $poet->app_class('Cache'), 'TestApp::Cache', 'cache' );

    {
        package Foo;
        Poet->import(qw($cache $conf $log $poet));
        use Test::More;
        is( $Foo::cache->chi_root_class, 'TestApp::Cache', '$cache' );
        isa_ok( $Foo::conf, 'TestApp::Conf',     '$conf' );
        isa_ok( $Foo::log,  'TestApp::Logger',   '$log' );
        isa_ok( $Foo::poet, 'Poet::Environment', '$poet' );
    }
}

1;
