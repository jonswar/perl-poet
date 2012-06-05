package Poet::Cache;
use Poet qw($conf $poet);
use Method::Signatures::Simple;
use Moose;

extends 'CHI';

method initialize_caching () {
    my $default_config =
      { defaults => { driver => 'File', root_dir => $poet->data_path("cache") }
      };
    my $config = $conf->get_hash( 'cache' => $default_config );
    __PACKAGE__->config($config);
}

1;

=pod

=head1 NAME

Poet::Cache -- Poet caching with CHI

=head1 SYNOPSIS

    # In a conf file...
    cache:
       defaults:
          driver: Memcached
          servers: ["10.0.0.15:11211", "10.0.0.15:11212"]

    # In a script...
    use Poet::Script qw($cache);

    # In a module...
    use Poet qw($cache);

    # In a component...
    my $cache = $m->cache;

    # For an arbitrary namespace...
    my $cache = Poet::Cache->new(namespace => 'Some::Namespace')

    # then...
    my $customer = $cache->get($name);
    if ( !defined $customer ) {
        $customer = get_customer_from_db($name);
        $cache->set( $name, $customer, "10 minutes" );
    }
    my $customer2 = $cache->compute($name2, "10 minutes", sub {
        get_customer_from_db($name2)
    });

=head1 DESCRIPTION

Poet::Cache is a subclass of L<CHI>. CHI provides a unified caching API over a
variety of storage backends, such as memory, plain files, memory mapped files,
memcached, and DBI.

Each package and Mason component uses its own CHI L<namespace|CHI/namespace> so
that caches remain separate.

=head1 CONFIGURATION

The Poet configuration entry 'cache', if any, will be passed to
L<Poet::Cache-E<gt>config()|CHI/SUBCLASSING AND CONFIGURING CHI>. This can go
in any L<Poet conf file|Poet::Conf/CONFIGURATION FILES>, e.g. C<local.cfg> or
C<global/cache.cfg>.

Here's a simple configuration that caches everything to files under
C<data/cache>. This is also the default if no configuration is present.

   cache:
      defaults:
         driver: File
         root_dir: ${root}/data/cache

Here's a more involved configuration that defines several "storage types" and
assigns each namespace a storage type.

   cache:
      defaults:
         expires_variance: 0.2
      storage:
         file:
            driver: File
            root_dir: ${root}/data/cache
         memcached:
            driver: Memcached
            servers: ["10.0.0.15:11211", "10.0.0.15:11212"]
            compress_threshold: 4096
      namespace:
         /some/component:       { storage: file, expires_in: 5min }
         /some/other/component: { storage: memcached, expires_in: 1h }
         Some::Library:         { storage: memcached, expires_in: 10min } 

Given the configuration above, and the code

    package Some::Library;
    use Poet qw($cache);

this C<$cache> will be created with properties

    driver: Memcached
    servers: ["10.0.0.15:11211", "10.0.0.15:11212"]
    compress_threshold: 4096
    expires_in: 10min

=head1 USAGE

=head2 Obtaining cache handle

=over

=item *

In a script (namespace will be 'main'):

    use Poet::Script qw($cache);

=item *

In a module C<MyApp::Foo> (namespace will be 'MyApp::Foo'):

    use Poet qw($cache);

=item *

In a component C</foo/bar> (namespace will be '/foo/bar'):

    my $cache = $m->cache;

=item *

Manually for an arbitrary namespace:

    my $cache = Poet::Cache->new(namespace => 'Some::Namespace');
        
    # or
    
    my $cache = MyApp::Cache->new(category => 'Some::Namespace');

=back

=head2 Using cache handle

    my $customer = $cache->get($name);
    if ( !defined $customer ) {
        $customer = get_customer_from_db($name);
        $cache->set( $name, $customer, "10 minutes" );
    }
    my $customer2 = $cache->compute($name2, "10 minutes", sub {
        get_customer_from_db($name2)
    });

See L<CHI|CHI> and L<Mason::Plugin::Cache|Mason::Plugin::Cache> for more
details.

=head1 MODIFIABLE METHODS

These methods are not intended to be called externally, but may be useful to
override or modify with method modifiers in L<subclasses|/Poet::Subclassing>.

=over

=item initialize_caching

Called once when the Poet environment is initialized. By default, calls C<<
__PACKAGE__->config >> with the configuration entry 'cache'.

=back
