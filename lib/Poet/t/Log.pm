package Poet::t::Log;
use Cwd qw(realpath);
use File::Temp qw(tempdir);
use Test::LongString;
use Poet::Test::Util;
use Poet::Util qw(json_encode);
use strict;
use warnings;
use base qw(Test::Class);

sub test_log_config : Tests {
    my $logs_dir =
      realpath( tempdir( 'name-XXXX', TMPDIR => 1, CLEANUP => 1 ) );

    my $test = sub {
        my ( $conf, $expected ) = @_;
        $conf->{layer} = 'development';
        $conf->{"env.logs_dir"} = $logs_dir;
        my $env = temp_env( conf => $conf );
        my $log_conf =
          Poet::Log::Manager->new( env => $env )->_generate_log4perl_config();
        is_string( $log_conf, $expected, json_encode($conf) );
    };

    $test->(
        {},
        "log4perl.logger = INFO, default
log4perl.appender.default = Log::Log4perl::Appender::File
log4perl.appender.default.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.default.layout.ConversionPattern = %d{dd/MMM/yyyy:HH:mm:ss.SS} %c - %m - %F:%L%n
log4perl.appender.default.filename = $logs_dir/poet.log
"
    );

    $test->(
        { 'log.defaults' => { level => 'debug', output => 'foo.log' } },
        "log4perl.logger = DEBUG, default
log4perl.appender.default = Log::Log4perl::Appender::File
log4perl.appender.default.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.default.layout.ConversionPattern = %d{dd/MMM/yyyy:HH:mm:ss.SS} %c - %m - %F:%L%n
log4perl.appender.default.filename = $logs_dir/foo.log
"
    );

    $test->(
        {
            'log.defaults'  => { level => 'info', output => 'foo.log' },
            'log.class.Bar' => { level => 'warn', output => 'bar.log' },
            'log.class.App.Errors'    => { output => 'stderr' },
            'log.class.App.NonErrors' => { output => 'stdout' }
        },
        "log4perl.logger = INFO, default
log4perl.appender.default = Log::Log4perl::Appender::File
log4perl.appender.default.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.default.layout.ConversionPattern = %d{dd/MMM/yyyy:HH:mm:ss.SS} %c - %m - %F:%L%n
log4perl.appender.default.filename = $logs_dir/foo.log

log4perl.logger.App.Errors = INFO, App_Errors
log4perl.appender.App_Errors = Log::Log4perl::Appender::Screen
log4perl.appender.App_Errors.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.App_Errors.layout.ConversionPattern = %d{dd/MMM/yyyy:HH:mm:ss.SS} %c - %m - %F:%L%n

log4perl.logger.App.NonErrors = INFO, App_NonErrors
log4perl.appender.App_NonErrors = Log::Log4perl::Appender::Screen
log4perl.appender.App_NonErrors.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.App_NonErrors.layout.ConversionPattern = %d{dd/MMM/yyyy:HH:mm:ss.SS} %c - %m - %F:%L%n
log4perl.appender.App_NonErrors.stderr = 0

log4perl.logger.Bar = WARN, Bar
log4perl.appender.Bar = Log::Log4perl::Appender::File
log4perl.appender.Bar.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Bar.layout.ConversionPattern = %d{dd/MMM/yyyy:HH:mm:ss.SS} %c - %m - %F:%L%n
log4perl.appender.Bar.filename = $logs_dir/bar.log
"
    );
}

1;
