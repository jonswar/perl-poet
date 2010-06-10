#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Poet');
}

diag("Testing Poet $Poet::VERSION, Perl $], $^X");
