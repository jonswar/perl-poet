package Poet::t::App;

use Test::Class::Most parent => 'Poet::Test::Class';

sub test_app_name_to_dir : Tests {
    require Poet::App::Command::new;

    my $try = sub {
        return Poet::App::Command::new->app_name_to_dir( $_[0] );
    };
    is( $try->("FooBar"),  "foo_bar" );
    is( $try->("HM"),      "hm" );
    is( $try->("foo_bar"), "foo_bar" );
}

1;
