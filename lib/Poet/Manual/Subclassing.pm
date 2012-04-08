
=head1 NAME

Poet::Manual::Subclassing - Customizing Poet with subclasses

=head1 DESCRIPTION

You can subclass the following Poet classes for your application:

    Poet::Cache
    Poet::Conf
    Poet::Log
    Poet::Mason
    Poet::Server
    Poet::Vars
    
and arrange things so that Poet always uses your subclass instead of its
default class.

Place Poet subclasses under C<lib/MyApp/Class.pm> in your environment, where
C<MyApp> is the name of your app and C<Class> is the class you are subclassing
minus the C<Poet> prefix.

For example, to subclass C<Poet::Cache>:

    package MyApp::Cache;
    use Poet::Moose;
    extends 'Poet::Interp';

    # put your modifications here

    1;

Note: L<Poet::Moose|Poet::Moose> is Moose plus a few Poet standards. You could
also use plain C<Moose> here.

Poet will automatically detect, load and use any such subclasses. Internally it
uses the L<app_class|Poet::Environment/app_class> environment method whenever
it needs a classname, e.g.

    # Do something with MyApp::Cache or Poet::Cache
    $env->app_class('Cache')->...

=head1 EXAMPLES

=head2 Use INI instead of YAML for config files

    package MyApp::Conf;
    use Config::INI;
    use Moose;
    extends 'Poet::Conf';

    override 'read_conf_file' => sub {
        my ($self, $file) = @_;
        return Config::INI::Reader->read_file($file);
    };

=head2 Use Log::Dispatch instead of Log4perl for logging

    package MyApp::Log;
    use Log::Any::Adapter;
    use Log::Dispatch;
    use Moose;
    extends 'Poet::Log';

    override 'initialize_logging' => sub {
        my $log = Log::Dispatch->new( ... );
        Log::Any::Adapter->set('Dispatch', dispatcher => $log);
    };

=head2 Add your own $dbh import variable

    package MyApp::Vars;
    use DBI;
    use Poet::Moose;
    extends 'Poet::Vars';
    
    method provide_dbh ($caller, $env) {
        $dbh = DBI->connect(...);
    }
