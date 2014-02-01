package Poet::t::Log;

use Poet::Tools qw(rmtree tempdir_simple);
use JSON::XS;
use Test::Class::Most parent => 'Poet::Test::Class';

__PACKAGE__->initialize_temp_env();

sub test_log_config : Tests {
    my $poet      = Poet::Environment->current_env;
    my $conf      = $poet->conf;
    my $logs_dir  = $poet->logs_dir;
    my $temp_dir  = tempdir_simple();
    my $other_dir = "$temp_dir/other";

    my $test = sub {
        my ( $conf_settings, $expected ) = @_;
        my $lex      = $conf->set_local($conf_settings);
        my $log_conf = Poet::Log->generate_log4perl_config();
        is( $log_conf, $expected, encode_json($conf_settings) );
    };

    my $default_layout = "%d{dd/MMM/yyyy:HH:mm:ss.SS} [%p] %c - %m - %F:%L - %P%n";

    rmtree($_) for ( $logs_dir, $other_dir );
    $test->(
        {},
        "log4perl.logger = INFO, default
log4perl.appender.default = Log::Log4perl::Appender::File
log4perl.appender.default.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.default.layout.ConversionPattern = $default_layout
log4perl.appender.default.filename = $logs_dir/poet.log
"
    );
    ok( -d $logs_dir,   "$logs_dir created" );
    ok( !-d $other_dir, "$other_dir not created" );

    rmtree($_) for ( $logs_dir, $other_dir );
    $test->(
        { log => { 'defaults' => { level => 'debug', output => 'foo.log' } } },
        "log4perl.logger = DEBUG, default
log4perl.appender.default = Log::Log4perl::Appender::File
log4perl.appender.default.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.default.layout.ConversionPattern = $default_layout
log4perl.appender.default.filename = $logs_dir/foo.log
"
    );
    ok( -d $logs_dir,   "$logs_dir created" );
    ok( !-d $other_dir, "$other_dir not created" );

    $test->(
        {
            log => {
                'defaults' => { level => 'info', output => 'foo.log' },
                'class'    => {
                    'Bar'           => { level  => 'warn', output => "$other_dir/bar.log" },
                    'Bar.Errors'    => { output => 'stderr' },
                    'Bar.NonErrors' => { output => 'stdout' },
                }
            }
        },
        "log4perl.logger = INFO, default
log4perl.appender.default = Log::Log4perl::Appender::File
log4perl.appender.default.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.default.layout.ConversionPattern = $default_layout
log4perl.appender.default.filename = $logs_dir/foo.log

log4perl.logger.Bar = WARN, Bar
log4perl.appender.Bar = Log::Log4perl::Appender::File
log4perl.appender.Bar.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Bar.layout.ConversionPattern = $default_layout
log4perl.appender.Bar.filename = $other_dir/bar.log

log4perl.logger.Bar.Errors = INFO, Bar_Errors
log4perl.appender.Bar_Errors = Log::Log4perl::Appender::Screen
log4perl.appender.Bar_Errors.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Bar_Errors.layout.ConversionPattern = $default_layout

log4perl.logger.Bar.NonErrors = INFO, Bar_NonErrors
log4perl.appender.Bar_NonErrors = Log::Log4perl::Appender::Screen
log4perl.appender.Bar_NonErrors.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Bar_NonErrors.layout.ConversionPattern = $default_layout
log4perl.appender.Bar_NonErrors.stderr = 0
"
    );
}

1;
