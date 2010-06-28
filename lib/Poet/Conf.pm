package Poet::Conf;
use Carp;
use Carp::Assert;
use Cwd qw(realpath);
use File::Basename;
use File::Slurp qw(read_file);
use File::Spec::Functions qw(catfile);
use Guard;
use Memoize;
use Moose;
use YAML::AppConfig;
use YAML::XS qw(Load);
use strict;
use warnings;

has 'app_conf'    => ( is => 'ro', init_arg => undef );
has 'conf_dir'    => ( is => 'ro', required => 1 );
has 'is_internal' => ( is => 'ro', init_arg => undef );
has 'is_live'     => ( is => 'ro', init_arg => undef );
has 'layer'       => ( is => 'ro', init_arg => undef );

__PACKAGE__->meta->make_immutable();

our $log;

sub BUILD {
    my ( $self, $params ) = @_;

    $self->{layer}       = $self->determine_layer();
    $self->{is_internal} = $self->determine_is_internal();
    $self->{is_live}     = !$self->{is_internal};
    $self->{app_conf}    = $self->parse_config_files();
}

sub parse_config_files {
    my ($self) = @_;

    my $conf_dir = $self->conf_dir();

    # Unfortunately YAML::AppConfig crashes on empty config files, or config files with
    # nothing but comments. We add a single "_init: 0" pair to prevent this.
    #
    my $app_conf =
      YAML::AppConfig->new( string => "_init: 0", yaml_class => 'YAML::XS' );

    # Provide some convenience globals.
    #
    $app_conf->set( root_dir => realpath( dirname($conf_dir) ) );

    # Collect list of config files in appropriate order
    #
    my @conf_files = $self->ordered_conf_files();

    # Stores the file where each global/* key is declared.
    #
    my %global_keys;

    foreach my $file (@conf_files) {
        if ( defined $file && -f $file ) {
            my $yaml = $self->_read_yaml_file($file);
            $app_conf->merge( string => $yaml );

            # Make sure no keys are defined in multiple global config files
            #
            if ( $file =~ m{/global/} ) {
                my $global_cfg = Load($yaml);
                foreach my $key ( keys(%$global_cfg) ) {
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
        flush_memoize_cache();
    }

    return $app_conf;
}

sub determine_layer {
    my $self = shift;

    my $conf_dir = $self->conf_dir;
    my $local_cfg_file = catfile( $conf_dir, "local.cfg" );
    my $local_cfg =
      ( -f $local_cfg_file )
      ? Load( $self->_read_yaml_file($local_cfg_file) )
      : {};
    my $layer = $local_cfg->{layer}
      || die "must specify layer in '$local_cfg_file'";
    die "invalid layer '$layer' - no such file '$conf_dir/layer/$layer.cfg'"
      unless -f "$conf_dir/layer/$layer.cfg";

    return $layer;
}

sub determine_is_internal {
    my $self = shift;

    return $self->layer =~ /^(?:personal|development)$/;
}

sub ordered_conf_files {
    my $self = shift;

    my $conf_dir = $self->conf_dir();
    my $layer    = $self->layer();

    return (
        glob("$conf_dir/global/*.cfg"),
        (
            $self->is_internal
            ? ("$conf_dir/layer/internal.cfg")
            : ("$conf_dir/layer/live.cfg")
        ),
        "$conf_dir/layer/$layer.cfg",
        "$conf_dir/local.cfg",
        $ENV{POET_EXTRA_CONF_FILE},
    );
}

sub _read_yaml_file {
    my ( $self, $file ) = @_;

    # Read a yaml file, adding a dummy key pair to handle empty files or files with
    # nothing but comments. Check for errors before returning. This means parsing
    # files twice (here and above) but makes the code cleaner.
    #
    my $yaml = read_file($file) . "\n\n_init: 0";
    eval { my $conf = Load($yaml) };
    if ( my $error = $@ ) {
        $error =~ s/Syck parser //g;
        $error =~ s/at \S+\/Syck\.pm line .*//g;
        die "error parsing config file '$file': $error";
    }
    return $yaml;
}

# Memoize _get, since conf can normally not change at runtime. This will
# benefit all get() and get_*() calls. Clear cache on set_local.
#
memoize( __PACKAGE__ . "::_get" );

sub flush_memoize_cache {
    Memoize::flush_cache( __PACKAGE__ . "::_get" );
}

sub _get {
    my ( $self, $key ) = @_;

    return $self->app_conf->get($key);
}

sub get {
    my ( $self, $key, $default ) = @_;

    if ( defined( my $value = $self->_get($key) ) ) {
        return $value;
    }
    else {
        return $default;
    }
}

sub get_or_die {
    my ( $self, $key ) = @_;

    if ( defined( my $value = $self->_get($key) ) ) {
        return $value;
    }
    else {
        die "could not get conf for '$key'";
    }
}

sub get_list {
    my ( $self, $key, $default ) = @_;

    if ( defined( my $value = $self->_get($key) ) ) {
        if ( ref($value) eq 'ARRAY' ) {
            return $value;
        }
        else {
            my $error = sprintf(
                "list value expected for config key '%s', got non-list '%s'",
                $key, $value );
            $self->handle_conf_error($error);
            return [];
        }
    }
    elsif ( defined $default ) {
        return $default;
    }
    else {
        return [];
    }
}

sub get_hash {
    my ( $self, $key, $default ) = @_;

    if ( defined( my $value = $self->_get($key) ) ) {
        if ( ref($value) eq 'HASH' ) {
            return $value;
        }
        else {
            my $error = sprintf(
                "hash value expected for config key '%s', got non-hash '%s'",
                $key, $value );
            $self->handle_conf_error($error);
            return {};
        }
    }
    elsif ( defined $default ) {
        return $default;
    }
    else {
        return {};
    }
}

sub handle_conf_error {
    my ( $self, $msg ) = @_;

    my $env = Poet::Environment->get_environment;
    if ( !$env || $env->is_live ) {
        $log->warn($msg);
    }
    else {
        croak $msg;
    }
}

sub get_boolean {
    my ( $self, $key ) = @_;

    return $self->_get($key) ? 1 : 0;
}

sub set_local {
    my ( $self, $pairs ) = @_;

    if ( !defined(wantarray) ) {
        warn "result of set_local must be assigned!";
    }
    my $orig_app_conf = $self->{app_conf};
    $self->{app_conf} = YAML::AppConfig->new( object => $orig_app_conf );
    while ( my ( $key, $value ) = each(%$pairs) ) {
        $self->{app_conf}->set( $key, $value );
    }
    $self->conf_has_changed();

    # Restore configuration when $guard goes out of scope
    my $guard =
      guard { $self->{app_conf} = $orig_app_conf; $self->conf_has_changed() };
    return $guard;
}

sub keys {
    my ($self) = @_;

    return keys( %{ $self->{app_conf}->config } );
}

sub dump_conf {
    my ( $self, ) = @_;

    return $self->{app_conf}->dump;
}

# Things we need to do whenever the conf changes.
#
sub conf_has_changed {
    my ($self) = @_;

    $self->flush_memoize_cache();
}

1;

__END__

=pod

=head1 NAME

Poet::Conf -- Access to Poet configuration

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw($conf);

    # In a module...
    use Poet qw($conf);

    # then...
    my $value = $conf->get('key', 'default');
    my $value = $conf->get_or_die('key');

    my $listref = $conf->get_list('key', ['default']);
    my $hashref = $conf->get_hash('key', {'default' => 5});
    my $bool = $conf->get_boolean('key');

    my @keys = grep { /^foo\./ } $conf->keys;

    { 
       my $lex = $conf->set_local({'key' => 'new_value'});
       # key has new_value inside this scope only
    }

=head1 DESCRIPTION

Poet::Conf provides a singleton, $conf, which gives access to the current
environment's configuration.

=head1 WHERE CONFIGURATION COMES FROM

=head2 Location of configuration files

Poet configuration files are found in the conf/ subdirectory of the environment
root:

  conf/
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

internal.cfg - read when layer = personal or development

=item *

live.cfg - read when layer = anything but personal or development

=item *

I<layer>.cfg - settings for each particular layer

=back

=item *

local.cfg contains settings for this particular instance of the environment. It
is not checked into version control. local.cfg must contain at least the layer,
e.g.

    layer: personal    

=item *

If $ENV{POET_EXTRA_CONF_FILE} is defined when configuration initializes, it is
read as an extra conf file whose values override all others.

=back

=head2 Format of files

The configuration format is provided by L<YAML::AppConfig|YAML::AppConfig>.
This is basically YAML with an added variable syntax that allows config entries
to be based on each other. For most purposes, plain YAML will suffice. See
http://www.yaml.org/refcard.html for a quick reference.

Example:

   apache.httpd_install_dir: /home/webuser/site/vendor/httpd
   apache.group: webuser

   load_modules:
     - CGI
     - CGI::Cookie

See more YAML examples at http://www.yaml.org/refcard.html.

By convention we use "." as a separator when we want hierarchial key names,
e.g. ''apache.*''. This is purely a convention, and not necessary for all keys.

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

=head1 SEE ALSO

Poet, Poet::Environment

=head1 AUTHOR

Jonathan Swartz

=cut
