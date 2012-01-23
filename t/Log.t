#!perl -w
use File::Basename;
my $class;

BEGIN {
    $class = "Poet::t::" . substr( basename($0), 0, -2 );
    eval "require $class";
    die $@ if $@;
}
Test::Class::runtests( $class->new );
