package Poet::Import;
use Method::Signatures::Simple;
use strict;
use warnings;

method valid_vars () { qw($cache $conf $env $log) };

method import ($caller, $env, @vars) {
    foreach my $var (@vars) {
        if ( substr( $var, 0, 1 ) eq '$' ) {
            my $bare_var = substr( $var, 1 );
            my $provide_method = "provide_" . $bare_var;
            if ( $self->can($provide_method) ) {
                my $value = $self->$provide_method( $caller, $env );
                no strict 'refs';
                *{ $caller . "\::$bare_var" } = \$value;
                next;
            }
        }
        die sprintf(
            "unknown import parameter '$var' passed to Poet: valid import parameters are %s",
            join( ", ", map { "'$_'" } $self->valid_vars ) );
    }
}

method provide_cache ($caller, $env) {
    $env->app_class('Cache')->new();
}

method provide_conf ($caller, $env) {
    $env->conf();
}

method provide_env ($caller, $env) {
    $env;
}

method provide_log ($caller, $env) {
    require Log::Any;
    Log::Any->get_logger( category => $caller );
}

1;

__END__

=pod

=head1 NAME

Poet::Import -- Import Poet variables and utilities

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw($conf $env $log :file);

    # In a module...
    use Poet qw($conf $env $log :file);

=head1 DESCRIPTION

Poet makes it easy to import certain variables and utilities into any script or
module in your environment.

In a script:

    use Poet::Script qw(...);

and in a module:

    use Poet qw(...);

where C<...> contains one or more variable names, method tags prefixed with
":", and method names.

Note that C<use Poet::Script> is also necessary for initializing the
environment, whereas C<use Poet> has no effect other than importing.

=head1 VARIABLES

Here is the built-in list of variables you can import. Some of the variables
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

=head2 Debug Utilities

These debug utilities are always imported. Each function takes a single scalar
value, which is serialized with L<Data::Dumper|Data::Dumper> before being
output. The variants suffixed with 's' output a full stack trace.

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

=over

=item html_escape ($str), html_unescape ($str)

Return the string with HTML entities escaped/unescaped.

=item uri_escape ($str), uri_unescape ($str)

Return the string URI escaped/unescaped.

=item js_escape ($str), js_unescape ($str)

Return the string Javascript escaped/unescaped.

=item make_uri ($path, $args)

Create a URL by combining the C<$path> with a query string formed from hashref
I<$args>. e.g.

    make_uri("/foo/bar", { a => 5, b => 6 });
        ==> /foo/bar?a=5&b=6

=item make_qs ($args)

Create a query string from hashref I<$args>. e.g.

    make_qs({ a => 5, b => 6 });
        ==> a=5&b=6

=back

=head2 List Utilities (":list")

This includes all the functions in L<List::Util|List::Util> and
L<List::MoreUtils|List::MoreUtils>.

=head2 Hash Utilities (":hash")

This includes all the functions in L<Hash::Util|Hash::Util> and
L<Hash::MoreUtils|Hash::MoreUtils>.

=head2 File Utilities (":file")

This includes

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

=head1 CUSTOMIZING

To customize, create a C<MyApp::Import> subclass like so:

    package MyApp::Import;
    use Poet::Moose;
    extends 'Poet::Import';

where C<MyApp> is your app name.

=head2 Adding variables

To add your own variable, say C<$dbh>, add this to C<MyApp::Import>:

    method provide_dbh ($caller, $env) {
        # Generate and return a dbh.
        # $caller is the package importing the variable.
        # $env is the current Poet environment.
    }

C<provide_dbh> can return a single global value, or a dynamic value depending
on C<$caller>.

Now your scripts and libraries can do

    use Poet::Script qw($dbh);
    use Poet qw($dbh);
