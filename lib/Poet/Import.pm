package Poet::Import;
use Carp;
use Poet::Moose;
use strict;
use warnings;

our @CARP_NOT = qw(Poet Poet::Script);

has 'env'         => ( required => 1, weak_ref => 1 );
has 'package_map' => ( init_arg => undef, lazy_build => 1 );
has 'tag_map'     => ( init_arg => undef, lazy_build => 1 );
has 'valid_vars'  => ( init_arg => undef, lazy_build => 1 );

method BUILD () {
    foreach my $package ( keys( %{ $self->package_map } ) ) {
        Class::MOP::load_class($package);
    }
}

method export_to_level ($level, @params) {
    foreach my $param (@params) {
        if ( substr( $param, 0, 1 ) eq '$' ) {
            $self->export_var_to_level( substr( $param, 1 ), $level + 1 );
        }
        elsif ( substr( $param, 0, 1 ) eq ':' ) {
            $self->export_tag_to_level( substr( $param, 1 ), $level + 1 );
        }
    }
    $self->export_tag_to_level( 'default', $level + 1 );
}

method export_var_to_level ($var, $level) {
    my $provide_method = "provide_var_" . $var;
    if ( $self->can($provide_method) ) {
        my ($caller) = caller($level);
        my $value = $self->$provide_method($caller);
        no strict 'refs';
        *{ $caller . "\::$var" } = \$value;
    }
    else {
        croak sprintf( "unknown import var '\$$var': valid import vars are %s",
            join( ", ", map { "'$_'" } $self->valid_vars ) );
    }
}

method export_tag_to_level ($tag, $level) {
    my $packages = $self->tag_map->{$tag}
      or croak sprintf( "unknown import tag '$tag'; valid import tags are %s",
        join( ", ", map { "':$_'" } sort( keys( %{ $self->{tag_map} } ) ) ) );
    foreach my $package (@$packages) {
        my $functions = $self->package_map->{$package}
          or croak sprintf("unknown package '$package' in import tag '$tag'");
        $package->export_to_level( $level + 1, $package, @$functions );
    }
}

method _build_valid_vars () {
    my @provide_methods = grep { /^provide_var_/ } $self->meta->get_method_list;
    return [ sort( map { substr( $_, 12 ) } @provide_methods ) ];
}

method _build_package_map () {
    return {
        'File::Basename'        => [qw(basename dirname)],
        'File::Path'            => [qw(make_path remove_tree)],
        'File::Slurp'           => [qw(read_file write_file read_dir)],
        'File::Spec::Functions' => [qw(catdir catfile)],
        'List::MoreUtils'       => [
            qw(all any none apply first_index first_value indexes last_index last_value uniq)
        ],
        'List::Util'        => [qw(first min max reduce shuffle)],
        'Poet::Util::Debug' => [qw(dd dp dps dc dcs dh dhs)],
        'Poet::Util::Web'   => [qw(html_escape js_escape)],
        'Scalar::Util'      => [qw(blessed)],
        'URI::Escape'       => [qw(uri_escape uri_unescape)],
    };
}

method _build_tag_map () {
    return {
        'default' => ['Poet::Util::Debug'],
        'list'    => [ 'List::MoreUtils', 'List::Util' ],
        'file'    => [
            'File::Basename', 'File::Path',
            'File::Slurp',    'File::Spec::Functions'
        ],
        'web' => [ 'Poet::Util::Web', 'URI::Escape' ],
    };
}

method provide_var_cache ($caller) {
    $self->env->app_class('Cache')->new( namespace => $caller );
}

method provide_var_conf ($caller) {
    $self->env->conf();
}

method provide_var_env ($caller) {
    $self->env;
}

method provide_var_log ($caller) {
    require Log::Any;
    Log::Any->get_logger( category => $caller );
}

1;

__END__

=pod

=head1 NAME

Poet::Import -- Import Poet quick vars and utilities

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw($conf $env $log :file);

    # In a module...
    use Poet qw($conf $env $log :file);

=head1 DESCRIPTION

Poet makes it easy to import certain variables (known as "quick vars") and
utilities into any script or module in your environment.

In a script:

    use Poet::Script qw(...);

and in a module:

    use Poet qw(...);

where C<...> contains one or more quick var names (e.g. C<$conf>, C<$env>)
and/or utility tags (e.g. C<:file>, C<:web>).

Note that C<use Poet::Script> is also necessary for initializing the
environment, even if you don't care to import anything, whereas C<use Poet> has
no effect other than importing.

=head1 QUICK VARS

Here is the built-in list of quick vars you can import. Some of the variables
are singletons, and some of them are specific to each package they are imported
into.

=over

=item $env

The global environment object, provided by
L<Poet::Environment|Poet::Environment>. This provides information such as the
root directory and paths to subdirectories.

=item $conf

The global configuration object, provided by L<Poet::Conf|Poet::Conf>.

=item $cache

The cache for the current package, provided by L<Poet::Cache|Poet::Cache>.

=item $log

The logger for the current package, provided by L<Poet::Log|Poet::Log>.

=back

=head1 UTILITIES

=head2 Debug utilities

Each of the "d" functions takes a single scalar value, which is serialized with
L<Data::Dumper|Data::Dumper> before being output. The variants suffixed with
's' output a full stack trace.

=over

=item dd ($val)

Die with the serialized I<$val>.

=item dp ($val), dps ($val)

Print the serialized I<$val> to STDERR.

=item dc ($val), dcs ($val)

Append the serialized I<$val> to "console.log" in the C<logs> subdirectory of
the environment.

=item dh ($val), dhs ($val)

Print the serialized I<$val> to STDOUT, surrounded by <pre> </pre>.

=back

=head2 Web utilities (":web")

This group includes:

=over

=item html_escape ($str)

Return the string with HTML entities escaped/unescaped.

=item uri_escape ($str), uri_unescape ($str)

Return the string URI escaped/unescaped.

=item js_escape ($str)

Return the string escaped for Javascript.

=item make_uri ($path, $args)

Create a URL by combining the C<$path> with a query string formed from hashref
I<$args>. e.g.

    make_uri("/foo/bar", { a => 5, b => 6 });
        ==> /foo/bar?a=5&b=6

=back

=head2 List Utilities (":list")

This group includes all the functions in L<List::Util|List::Util> and
L<List::MoreUtils|List::MoreUtils>.

=head2 File Utilities (":file")

This group includes

=over

=item basename, dirname

From L<File::Basename|File::Basename>.

=item make_path, remove_tree

From L<File::Path|File::Path>.

=item read_file, write_file, read_dir

From L<File::Slurp|File::Slurp>.

=item catdir, catfile

From L<File::Spec::Functions|File::Spec::Functions>.

=back

=head1 MASON COMPONENTS

Every Mason component automatically gets this on top:

    use Poet qw($conf $env :web);

C<$m->E<gt>cache> and C<$m->E<gt>log> will get you the cache and log objects
for a particular Mason component.

=head1 CUSTOMIZING

To customize, create a C<MyApp::Import> subclass like so:

    package MyApp::Import;
    use Poet::Moose;
    extends 'Poet::Import';

where C<MyApp> is your app name.

=head2 Adding variables

To add your own variable, define a method called provide_var_I<varname> in
C<MyApp::Import>. For example to add a variable C<$dbh>:

    method provide_var_dbh ($caller) {
        # Generate and return a dbh.
        # $caller is the package importing the variable.
        # $env is the current Poet environment.
    }

C<provide_dbh> can return a single global value, or a dynamic value depending
on C<$caller>.

Now your scripts and libraries can do

    use Poet::Script qw($dbh);
    use Poet qw($dbh);
