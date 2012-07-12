package Poet::Log;
use Poet qw($conf $poet);
use File::Spec::Functions qw(rel2abs);
use Log::Any::Adapter;
use Method::Signatures::Simple;
use Poet::Tools qw(can_load dirname mkpath read_file write_file);
use strict;
use warnings;

method get_logger ($class: %params) {
    my $category = $params{category} || caller();
    return Log::Any->get_logger( category => $category );
}

method initialize_logging ($class:) {
    if (   can_load('Log::Log4perl')
        && can_load('Log::Any::Adapter')
        && can_load('Log::Any::Adapter::Log4perl') )
    {
        unless ( Log::Log4perl->initialized() ) {
            my $config_string = $class->generate_log4perl_config();
            Log::Log4perl->init( \$config_string );
        }
        Log::Any::Adapter->set('Log4perl');
    }
    else {
        write_file(
            $poet->logs_path("poet.log.ERROR"),
            sprintf(
                "[%s] Could not load Log::Log4perl or Log::Any::Adapter::Log4perl. Install them to enable logging, or modify logging for your application (see Poet::Manual::Subclassing).\n",
                scalar(localtime) )
        );
    }
}

method generate_log4perl_config ($class:) {
    my %log_config = %{ $conf->get_hash('log') };
    if ( my $log4perl_conf = $log_config{log4perl_conf} ) {
        $log4perl_conf = rel2abs( $log4perl_conf, $poet->conf_dir );
        return read_file($log4perl_conf);
    }

    my %defaults = (
        level  => 'info',
        output => 'poet.log',
        layout => '%d{dd/MMM/yyyy:HH:mm:ss.SS} [%p] %c - %m - %F:%L - %P%n',
        %{ $log_config{'defaults'} || {} }
    );
    my %classes = %{ $log_config{'class'} || {} };

    foreach my $set ( values(%classes) ) {
        foreach my $key (qw(level output layout)) {
            $set->{$key} = $defaults{$key} if !exists( $set->{$key} );
        }
    }
    foreach my $set ( \%defaults, values(%classes) ) {
        if ( $set->{output} =~ /^(?:stderr|stdout)$/ ) {
            $set->{appender_class} = "Log::Log4perl::Appender::Screen";
            $set->{stderr} = 0 if $set->{output} eq 'stdout';
        }
        else {
            $set->{appender_class} = "Log::Log4perl::Appender::File";
            $set->{filename} = rel2abs( $set->{output}, $poet->logs_dir );
            mkpath( dirname( $set->{filename} ), 0, 0775 );
        }
    }
    return join(
        "\n",
        $class->_generate_lines( 'log4perl.logger', 'default', \%defaults ),
        map {
            $class->_generate_lines( "log4perl.logger.$_",
                $class->_flatten_class_name($_),
                $classes{$_} )
        } sort( keys(%classes) ),
    );
}

method _generate_lines ($class: $logger, $appender, $set) {
    my $full_appender = "log4perl.appender.$appender";
    my @pairs         = (
        [ $logger => join( ", ", uc( $set->{level} ), $appender ) ],
        [ $full_appender          => $set->{appender_class} ],
        [ "$full_appender.layout" => 'Log::Log4perl::Layout::PatternLayout' ],
        [ "$full_appender.layout.ConversionPattern" => $set->{layout} ]
    );
    foreach my $key (qw(filename stderr)) {
        if ( exists( $set->{$key} ) ) {
            push( @pairs, [ "$full_appender.$key" => $set->{$key} ] );
        }
    }

    my $lines = join( "\n", map { join( " = ", @$_ ) } @pairs ) . "\n";
    return $lines;
}

method _flatten_class_name ($class: $class_name) {
    $class_name =~ s/(::|\.)/_/g;
    return $class_name;
}

1;

__END__

=pod

=head1 NAME

Poet::Log -- Poet logging

=head1 SYNOPSIS

    # In a conf file...
    log:
      defaults:
        level: info
        output: poet.log
        layout: "%d{dd/MMM/yyyy:HH:mm:ss.SS} [%p] %c - %m - %F:%L - %P%n"
      category:
        CHI:
          level: debug
          output: chi.log
          layout: "%d{dd/MMM/yyyy:HH:mm:ss.SS} %m - %P%n"
        MyApp::Foo:
          output: stdout

    # In a script...
    use Poet::Script qw($log);

    # In a module...
    use Poet qw($log);

    # In a component...
    my $log = $m->log;

    # For an arbitrary category...
    my $log = Poet::Log->get_logger(category => 'MyApp::Bar');

    # then...
    $log->error("an error occurred");

    $log->debugf("arguments are: %s", \@_)
        if $log->is_debug();

=head1 DESCRIPTION

Poet uses L<Log::Any|Log::Any> and L<Log::Log4perl|Log::Log4perl> for logging,
with simplified configuration for the common case.

Log::Any is a logging abstraction that allows CPAN modules to log without
knowing about which logging framework is in use. It supports standard logging
methods (C<$log-E<gt>debug>, C<$log-E<gt>is_debug>) along with sprintf variants
(C<$log-E<gt>debugf>).

Log4perl is a powerful logging package that provides just about any
logging-related feature you'd want. One of its only drawbacks is its somewhat
cumbersome configuration. So, we provide a way to configure Log4perl simply
through L<Poet configuration|Poet::Conf> if you just want common features.

Note: Log4perl is not a strict dependency for Poet.  Log messages will simply
not get logged until you install it or until you L<modify logging|/MODIFIABLE
METHODS> for your app.

=head1 CONFIGURATION

The configurations below can go in any L<Poet conf
file|Poet::Conf/CONFIGURATION FILES>, e.g. C<local.cfg> or C<global/log.cfg>.

Here's a simple configuration that caches everything to C<logs/poet.log> at
C<info> level. This is also the default if no configuration is present.

    log:
      defaults:
        level: info
        output: poet.log
        layout: %d{dd/MMM/yyyy:HH:mm:ss.SS} [%p] %c - %m - %F:%L - %P%n

Here's a more involved configuration that maintains the same default, but adds
several I<categories> that are logged differently:

    log:
      defaults:
        level: info
        output: poet.log
        layout: "%d{dd/MMM/yyyy:HH:mm:ss.SS} [%p] %c - %m - %F:%L - %P%n"
      category:
        CHI:
          level: debug
          output: chi.log
          layout: "%d{dd/MMM/yyyy:HH:mm:ss.SS} %m - %P%n"
        MyApp::Foo:
          output: stdout

For the default and for each category, you can specify three different
settings:

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

Notice that we use '::' instead of '.' to specify hierarchical category names,
because '.' would interfere with L<Poet::Conf dot notation|Poet::Conf/Dot
notation for hash access>.

Finally, if you must use a full L<Log4perl configuration
file|Log::Log4perl::Config>, you can specify it this way:

    log:
      log4perl_conf: /path/to/log4perl.conf

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

    my $log = Poet::Log->get_logger(category => 'Some::Category');
        
    # or
    
    my $log = MyApp::Log->get_logger(category => 'Some::Category');

=back

=head2 Using log handle

    $log->error("an error occurred");

    $log->debugf("arguments are: %s", \@_)
        if $log->is_debug();

See C<Log::Any|Log::Any> for more details.

=head1 MODIFIABLE METHODS

These methods are not intended to be called externally, but may be useful to
override or modify with method modifiers in
L<subclasses|Poet::Manual::Subclassing>. Their APIs will be kept as stable as
possible.

=over

=item initialize_logging

Called once when the Poet environment is initialized. By default, initializes
log4perl with the results of L</generate_log4perl_config> and then calls C<<
Log::Any::Adapter->set('Log4perl') >>.  You can modify this to initialize
log4perl in your own way, or use a different Log::Any adapter, or use a
completely different logging system.

=item generate_log4perl_config

Returns a log4perl config string based on Poet configuration. You can modify
this to construct and return your own config.

=back
