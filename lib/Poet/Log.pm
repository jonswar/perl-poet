package Poet::Log;
use Log::Any;
use strict;
use warnings;

sub get_logger {
    my $class = shift;
    return Log::Any->get_logger(@_);
}

1;

__END__

=pod

=head1 NAME

Poet::Log -- Poet logging

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw($log);

    # In a module...
    use Poet qw($log);

    # In a component...
    my $log = $m->log;

    # For an arbitrary category...
    my $log = Log::Any->get_logger(category => 'Foo::Bar');

    # then...
    $log->error("an error occurred");

    $log->debugf("arguments are: %s", \@_)
        if $log->is_debug();

=head1 DESCRIPTION

Poet uses L<Log::Any|Log::Any> and L<Log::Log4perl|Log::Log4perl> for logging,
with an easy configuration option.

Log::Any is a logging abstraction that allows CPAN modules to log without
knowing about which logging framework is in use. It supports standard logging
methods (C<$log-E<gt>debug>, C<$log-E<gt>is_debug>) along with sprintf variants
(C<$log-E<gt>debugf>).

Log4perl is a powerful logging package that provides just about any
logging-related feature you'd want. However, it can be rather verbose to
configure, so we provide a way to configure Log4perl in a simpler way through
Poet conf files if you just want common features.

=head1 CONFIGURATION

=head2 Simple configuration

Here's a sample logging configuration. This can go in any Poet conf file(s),
e.g. local.cfg or global/log.cfg.

    log.defaults:
      level: info
      output: poet.log
      layout: "%d{dd/MMM/yyyy:HH:mm:ss.SS} [%p] %c - %m - %F:%L - %P%n"
    log.class.CHI:
      level: debug
      output: chi.log
      layout: "%d{dd/MMM/yyyy:HH:mm:ss.SS} %m - %P%n"
    log.class.MyApp.Foo:
      output: stdout

This defines default settings, and specific settings for category C<CHI> and
C<MyApp::Foo>. There are three setting types:

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

If a setting isn't defined for a specific category then it falls back to the
default. In this example, C<MyApp::Foo> will inherit the default level and
layout.

=head2 Advanced configuration

If you need a Log4perl feature that isn't handled by the simple configuration
case above, you can specify a full L<Log4perl configuration
file|Log::Log4perl::Config> instead:

    log.log4perl_conf_file: /path/to/log4perl.conf

=head1 USAGE

=head2 Obtaining log handle

=over

=item *

In a script (log category will be 'main'):

    use Poet::Script qw($log);

=item *

In a module C<MyApp::Foo> (log category will be 'MyApp::Foo'):

    use Poet qw($log);

=item *

In a component C</foo/bar> (log category will be 'Mason::Component::foo::bar'):

    my $log = $m->log;

=item *

Manually for an arbitrary log category:

    my $log = Log::Any->get_logger(category => 'Some::Category');

=back

=head2 Using log handle

    $log->error("an error occurred");

    $log->debugf("arguments are: %s", \@_)
        if $log->is_debug();

See C<Log::Any|Log::Any> for more details.

=head1 APPENDIX A: SIMPLE CONFIGURATION TRANSLATION

   log4perl.logger = INFO, default
   log4perl.appender.default = Log::Log4perl::Appender::File
   log4perl.appender.default.layout = Log::Log4perl::Layout::PatternLayout
   log4perl.appender.default.layout.ConversionPattern = %d{dd/MMM/yyyy:HH:mm:ss.SS} [%p] %c - %m - %F:%L - %P%n
   log4perl.appender.default.filename = /Users/swartz/git/poet.git/tmp/my_app/logs/poet.log
   
   log4perl.logger.MyApp.Foo = INFO, MyApp_Foo
   log4perl.appender.MyApp.Foo = Log::Log4perl::Appender::Screen
   log4perl.appender.MyApp.Foo.layout = Log::Log4perl::Layout::PatternLayout
   log4perl.appender.MyApp.Foo.layout.ConversionPattern = %d{dd/MMM/yyyy:HH:mm:ss.SS} [%p] %c - %m - %F:%L - %P%n
   log4perl.appender.MyApp.Foo.stderr = 0
   
   log4perl.logger.Foo = DEBUG, CHI
   log4perl.appender.Foo = Log::Log4perl::Appender::File
   log4perl.appender.Foo.layout = Log::Log4perl::Layout::PatternLayout
   log4perl.appender.Foo.layout.ConversionPattern = %d{dd/MMM/yyyy:HH:mm:ss.SS} %m - %P%n
   log4perl.appender.Foo.filename = /Users/swartz/git/poet.git/tmp/my_app/logs/chi.log

=head1 SEE ALSO

Poet

=cut
