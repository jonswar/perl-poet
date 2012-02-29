package Poet::Log;
use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

Poet::Log -- Provides log objects

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw($log);

    # In a module...
    use Poet qw($log);

    # In a component...
    my $log = $m->log;

    # then...
    $log->error("an error occurred");
    $log->debugf("arguments are: %s", \@_)
        if $log->is_debug();

=head1 DESCRIPTION

Poet::Log provides the log object when you import the Poet C<$log> variable. It
uses L<log4perl|Log::Log4perl> as the engine but provides simpler configuration
via Poet conf files.

=head1 CONFIGURATION

Here's are sample configuration entries for logging. These can go in any Poet
conf file(s), e.g. local.cfg or global/log.cfg.

    log.defaults:
       level: info
       output: poet.log
       layout: "%d{dd/MMM/yyyy:HH:mm:ss.SS} [%p] %c - %m - %F:%L - %P%n"
    log.class.Foo:
      level: debug
      output: chi.log
      layout: "%d{dd/MMM/yyyy:HH:mm:ss.SS} %m - %P%n"
    log.class.Bar:
      output: stdout
    log.class.Baz:
      output: stderr

This defines default settings and per-class settings for three classes. There
are three items that can be set within each setting:

=over

=item *

level - one of the valid log4perl levels (fatal, error, warn, info, debug,
trace)

=item *

output - can be a relative filename (which will be placed in the Poet log
directory), an absolute filename, or the special names "stdout" or "stderr"

=item *

layout - a valid log4perl L<PatternLayout|Log::Log4perl::Layout::PatternLayout>
string.

=back

The configuration above will generate a log4perl configuration roughly like
this:

   log4perl.logger = INFO, default
   log4perl.appender.default = Log::Log4perl::Appender::File
   log4perl.appender.default.layout = Log::Log4perl::Layout::PatternLayout
   log4perl.appender.default.layout.ConversionPattern = %d{dd/MMM/yyyy:HH:mm:ss.SS} [%p] %c - %m - %F:%L - %P%n
   log4perl.appender.default.filename = /Users/swartz/git/poet.git/tmp/my_app/logs/poet.log
   
   log4perl.logger.Bar = INFO, Bar
   log4perl.appender.Bar = Log::Log4perl::Appender::Screen
   log4perl.appender.Bar.layout = Log::Log4perl::Layout::PatternLayout
   log4perl.appender.Bar.layout.ConversionPattern = %d{dd/MMM/yyyy:HH:mm:ss.SS} [%p] %c - %m - %F:%L - %P%n
   log4perl.appender.Bar.stderr = 0
   
   log4perl.logger.Baz = INFO, Baz
   log4perl.appender.Baz = Log::Log4perl::Appender::Screen
   log4perl.appender.Baz.layout = Log::Log4perl::Layout::PatternLayout
   log4perl.appender.Baz.layout.ConversionPattern = %d{dd/MMM/yyyy:HH:mm:ss.SS} [%p] %c - %m - %F:%L - %P%n
   
   log4perl.logger.Foo = DEBUG, Foo
   log4perl.appender.Foo = Log::Log4perl::Appender::File
   log4perl.appender.Foo.layout = Log::Log4perl::Layout::PatternLayout
   log4perl.appender.Foo.layout.ConversionPattern = %d{dd/MMM/yyyy:HH:mm:ss.SS} %m - %P%n
   log4perl.appender.Foo.filename = /Users/swartz/git/poet.git/tmp/my_app/logs/chi.log

=head1 SEE ALSO

Poet

=cut
