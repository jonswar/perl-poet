package Poet::t::Util;

use Test::Class::Most parent => 'Poet::Test::Class';
use Poet::Tools qw(read_file);
use Poet::Util::Debug qw(:all);
use Capture::Tiny qw(capture_stderr);

my $poet = __PACKAGE__->initialize_temp_env( conf => { layer => 'development' } );

sub test_debug : Tests {
    my $data = { foo => 5, bar => 6 };
    my $expect = qr|\[d. at .* line .*\] \[\d+\] \{\n  bar => 6,\n  foo => 5\n\}|;

    throws_ok { dd($data) } $expect, "dd";
    like( dh($data), $expect, "dh" );
    like( capture_stderr { dp($data) }, $expect, "dp" );

    my $console_log = $poet->logs_path("console.log");
    ok( !-f $console_log, "no console log" );
    dc($data);
    like( read_file($console_log), qr|$expect|, "dc" );
}

1;
