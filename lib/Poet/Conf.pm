package Poet::Conf;
use Carp;
use Cwd qw(realpath);
use File::Basename;
use File::Slurp qw(read_file);
use File::Spec::Functions qw(catfile);
use Guard;
use Poet::Moose;
use Try::Tiny;
use YAML::XS;
use strict;
use warnings;

has 'conf_dir'       => ( required => 1 );
has 'data'           => ( init_arg => undef );
has 'is_development' => ( init_arg => undef );
has 'is_live'        => ( init_arg => undef );
has 'layer'          => ( init_arg => undef );

our %get_cache;

method BUILD () {
    $self->{layer}          = $self->determine_layer();
    $self->{is_development} = $self->layer eq 'development';
    $self->{is_live}        = $self->determine_is_live();
    $self->{data}           = $self->parse_config_files();
}

method parse_config_files () {
    my $conf_dir = $self->conf_dir();
    my %data     = ();

    # Provide some convenience globals.
    #
    $data{root_dir} = realpath( dirname($conf_dir) );
    $data{user} = getlogin || getpwuid($<);

    # Collect list of config files in appropriate order
    #
    my @conf_files = $self->ordered_conf_files();

    # Stores the file where each global/* key is declared.
    #
    my %global_keys;

    foreach my $file (@conf_files) {
        if ( defined $file && -f $file ) {
            my $new_data = $self->_read_config_file($file);
            %data = ( %data, %$new_data );

            # Make sure no keys are defined in multiple global config files
            #
            if ( $file =~ m{/global/} ) {
                foreach my $key ( keys(%$new_data) ) {
                    next if $key eq '_init';
                    if ( my $previous_file = $global_keys{$key} ) {
                        die sprintf(
                            "top-level key '%s' defined in both '%s' and '%s' - global conf files must be mutually exclusive",
                            $key, $previous_file, $file );
                    }
                    else {
                        $global_keys{$key} = $file;
                    }
                }
            }
        }
        $self->_flush_get_cache();
    }

    return \%data;
}

method determine_layer () {
    my $conf_dir = $self->conf_dir;
    my $local_cfg_file = catfile( $conf_dir, "local.cfg" );
    my $local_cfg =
      ( -f $local_cfg_file )
      ? $self->_read_config_file($local_cfg_file)
      : {};
    my $layer = $local_cfg->{layer}
      || die "must specify layer in '$local_cfg_file'";
    die "invalid layer '$layer' - no such file '$conf_dir/layer/$layer.cfg'"
      unless -f "$conf_dir/layer/$layer.cfg";

    return $layer;
}

method determine_is_live () {
    return $self->layer =~ /^(?:staging|production)$/;
}

method ordered_conf_files () {
    my $conf_dir = $self->conf_dir();
    my $layer    = $self->layer();

    return (
        "$conf_dir/global.cfg",
        glob("$conf_dir/global/*.cfg"),
        (
            $self->is_live
            ? ("$conf_dir/layer/live.cfg")
            : ()
        ),
        "$conf_dir/layer/$layer.cfg",
        "$conf_dir/local.cfg",
        $ENV{POET_EXTRA_CONF_FILE},
    );
}

method _read_config_file ($file) {

    # Read a yaml file into a hash, adding a dummy key pair to handle empty
    # files or files with nothing but comments, and checking for errors.
    # Return the hash.
    #
    my $yaml = read_file($file) . "\n\n_init: 0";
    my $hash;
    try {
        $hash = YAML::XS::Load($yaml);
    }
    catch {
        die "error parsing config file '$file': $_";
    };
    die "'$file' did not parse to a hash" unless ref($hash) eq 'HASH';
    return $hash;
}

# Memoize get, since conf can normally not change at runtime. This will
# benefit all get() and get_*() calls. Clear cache on set_local.
#
method _flush_get_cache () {
    %get_cache = ();
}

method get ($key, $default) {
    return $get_cache{$key} if exists( $get_cache{$key} );
    my $value = $self->data->{$key};
    if ( defined($value) ) {
        while ( $value =~ /(\$ (?: ([\w\.\-]+) | \{([\w\.\-]+)\} ) )/x ) {
            my $var_decl  = $1;
            my $var_key   = defined($2) ? $2 : $3;
            my $var_value = $self->get($var_key);
            $var_value = '' if !defined($var_value);
            $value =~ s/\Q$var_decl\E/$var_value/;
        }
    }
    $get_cache{$key} = $value;
    return defined($value) ? $value : $default;
}

method get_or_die ($key) {
    if ( defined( my $value = $self->get($key) ) ) {
        return $value;
    }
    else {
        die "could not get conf for '$key'";
    }
}

method get_list ($key, $default) {
    if ( defined( my $value = $self->get($key) ) ) {
        if ( ref($value) eq 'ARRAY' ) {
            return $value;
        }
        else {
            my $error = sprintf(
                "list value expected for config key '%s', got non-list '%s'",
                $key, $value );
            croak($error);
        }
    }
    elsif ( defined $default ) {
        return $default;
    }
    else {
        return [];
    }
}

method get_hash ($key, $default) {
    if ( defined( my $value = $self->get($key) ) ) {
        if ( ref($value) eq 'HASH' ) {
            return $value;
        }
        else {
            my $error = sprintf(
                "hash value expected for config key '%s', got non-hash '%s'",
                $key, $value );
            croak($error);
        }
    }
    elsif ( defined $default ) {
        return $default;
    }
    else {
        return {};
    }
}

method get_hash_from_common_prefix ($prefix) {

    # Find all keys with the given prefix, and return a hashref containing just
    # those keys and values with the prefix stripped off.
    #
    my $prefix_length = length($prefix);
    return {
        map { ( substr( $_, $prefix_length ), $self->get($_) ) }
        grep { /^\Q$prefix\E(.+)$/ } $self->get_keys
    };
}

method get_boolean ($key) {
    return $self->get($key) ? 1 : 0;
}

method set_local ($pairs) {
    if ( !defined(wantarray) ) {
        warn "result of set_local must be assigned!";
    }
    die "set_local expects hashref" unless ref($pairs) eq 'HASH';

    # Make a copy of current data, then apply the pairs
    #
    my $orig_data = { %{ $self->{data} } };
    while ( my ( $key, $value ) = each(%$pairs) ) {
        $self->{data}->{$key} = $value;
    }
    $self->conf_has_changed();

    # Restore original data when $guard goes out of scope
    #
    my $guard = guard { $self->{data} = $orig_data; $self->conf_has_changed() };
    return $guard;
}

method get_keys () {
    return keys( %{ $self->{data} } );
}

method dump () {
    return YAML::XS::Dump( { map { "$_: " . $self->get($_) } $self->get_keys } )
      . "\n";
}

# Things we need to do whenever the conf changes.
#
method conf_has_changed () {
    $self->_flush_get_cache();
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=head1 NAME

Poet::Conf -- Poet configuration

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw($conf);

    # In a module...
    use Poet qw($conf);

    # $conf is automatically available in Mason components

    # then...
    my $value = $conf->get('key', 'default');
    my $value = $conf->get_or_die('key');

    my $listref = $conf->get_list('key', ['default']);
    my $hashref = $conf->get_hash('key', {'default' => 5});
    my $hashref = $conf->get_hash_from_common_prefix('cache.defaults.');
    my $bool = $conf->get_boolean('key');

    my @keys = grep { /^foo\./ } $conf->get_keys;

    print $conf->dump;

    { 
       my $lex = $conf->set_local({'key' => 'new_value'});
       # key has new_value inside this scope only
    }

=head1 DESCRIPTION

The Poet::Conf object gives access to the current environment's configuration,
read from configuration files in the conf/ subdirectory.

=head1 WHERE CONFIGURATION COMES FROM

=head2 Location of configuration files

Poet configuration files are found in the conf/ subdirectory of the environment
root:

  conf/
    global.cfg
    global/
      something.cfg
      something_else.cfg
      ...
    layer/
      internal.cfg
      live.cfg
      ...
    local.cfg
  $ENV{POET_EXTRA_CONF_FILE}

The files are read in the following order, with later files taking precedence
over earlier files.

=over

=item *

The global/ directory contains various settings for the environment, organized
into different files as desired. All .cfg files are read in alphabetical order,
and it is an error for two global files to set the same key. These are checked
into version control.

=item *

The layer/ directory contains version-controlled files specific to layers:

=over

=item *

development.cfg, production.cfg, etc. - settings for each particular layer

=item *

live.cfg - read when layer = "staging" or "production"

=back

=item *

local.cfg contains settings for this particular instance of the environment. It
is not checked into version control. local.cfg must contain at least the layer,
e.g.

    layer: development

=item *

If $ENV{POET_EXTRA_CONF_FILE} is defined when configuration initializes, it is
read as an extra conf file whose values override all others.

=back

=head2 Format of files

The basic configuration format is L<YAML|http://www.yaml.org/>. For example:

   # if conf file contains

   apache.httpd_install_dir: /home/webuser/site/vendor/httpd
   apache.group: webuser

   load_modules:
     - CGI
     - CGI::Cookie

   # then

   $conf->get('apache.group')
      => "webuser"
   $conf->get('load_modules') or $conf->get_list('load_modules')
      => ['CGI', 'CGI::Cookie']

By convention Poet apps use "." as a separator when we want hierarchial key
names, e.g. ''apache.*''.

The one addition to standard YAML is that config entries can refer to other
entries via the syntax C<$key> or C<${key}>. For example:

   # conf file

   foo: 5
   bar: "The number $foo"
   baz: ${bar}00

   # then
   
   $conf->get('foo')
      => 5
   $conf->get('bar')
      => "The number 5"
   $conf->get('baz')
      => "The number 500"

This is only supported for keys matching C<[\w\.\-]+>.

=head1 OBTAINING $conf SINGLETON

To get $conf in a script:

    use Poet::Script qw($conf);

To get $conf in a module:

    use Poet qw($conf);

$conf is automatically available in components.

=head1 METHODS

=over

=item get

    my $value = $conf->get('key' => 'default');

Get I<key> from configuration. If I<key> is unavailable, return the I<default>,
or undef if no default is given.

The return value may be a scalar, list reference, or hash reference, though we
recommend using L</get_list> and L</get_hash> if you expect a list or hash.

=item get_or_die

    my $value = $conf->get_or_die('key');

Get I<key> from configuration. If I<key> is unavailable, throw a fatal error.

=item get_list

    my $listref = $conf->get_list('key', ['default']);

Get I<key> from configuration. If the value is not a list reference, throw a
warning.

If I<key> is unavailable, return the I<default>, or an empty list reference if
no default is given.

=item get_hash

    my $hashref = $conf->get_hash('key', {'default' => 5});

Get I<key> from configuration. If the value is not a hash reference, throw a
warning.

If I<key> is unavailable, return the I<default>, or an empty hash reference if
no default is given.

=item get_hash_from_common_prefix (I<prefix>)

    my $hashref = $conf->get_hash_from_common_prefix('cache.defaults.');

Find all keys with the given I<prefix>, and return a hashref containing just
those keys and values with the prefix stripped off. e.g. if these configuration
entries exist (in any files):

    cache.defaults.depth: 3
    cache.defaults.expires_variance: 0.2
    cache.defaults.namespace: Default

then the call above would return

    { depth => 3, expires_variance => 0.2, namespace => 'Default' }

If no keys have the given prefix, an empty hashref is returned.

Using a common prefix is often preferable to specifying a single hash, because
the individual entries can be overriden.

=item get_boolean

    my $bool = $conf->get_boolean('key');

Get I<key> from configuration, or undef if I<key> is unavailable. This method
simply indicates to the reader that a boolean is expected.

=item keys

    my @keys = sort $conf->keys;

Return a list of all keys in configuration.

=item set_local

    my $lex = $conf->set_local({'key', 'value', ['key', 'value', ...]});

Temporarily set each I<key> to I<value>. The original value will be restored
when $lex goes out of scope.

This is intended for specialized use in unit tests and development tools, NOT
for production code. Setting and resetting of configuration values will make it
much more difficult to read and debug code!

=back

=head1 CREDITS

The ideas of merging multiple conf files and variable substitution came from
L<YAML::AppConfig>.

=head1 SEE ALSO

Poet

=cut
