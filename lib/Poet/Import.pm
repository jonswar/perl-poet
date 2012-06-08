package Poet::Import;
use Carp;
use Poet::Moose;
use Try::Tiny;
use strict;
use warnings;

our @CARP_NOT = qw(Poet Poet::Script);

has 'default_tags' => ( init_arg => undef, lazy_build => 1 );
has 'env'          => ( required => 1, weak_ref => 1 );
has 'valid_vars'   => ( init_arg => undef, lazy_build => 1 );

method _build_valid_vars () {
    my @provide_methods = grep { /^provide_var_/ } $self->meta->get_method_list;
    return [ sort( map { substr( $_, 12 ) } @provide_methods ) ];
}

method _build_default_tags () {
    return ['debug'];
}

method export_to_level ($level, @params) {
    my ($caller) = caller($level);
    $self->export_to_class($caller);
    foreach my $param (@params) {
        if ( substr( $param, 0, 1 ) eq '$' ) {
            $self->export_var_to_level( substr( $param, 1 ), $level + 1 );
        }
        elsif ( substr( $param, 0, 1 ) eq ':' ) {
            $self->export_tag_to_level( substr( $param, 1 ), $level + 1 );
        }
    }
    foreach my $tag ( @{ $self->default_tags } ) {
        $self->export_tag_to_level( $tag, $level + 1 );
    }
}

method export_to_class ($class) {
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
        croak sprintf(
            "unknown import var '\$$var': valid import vars are %s",
            join( ", ",
                map { "'\$$_'" } grep { $_ ne 'env' } @{ $self->valid_vars } )
        );
    }
}

method export_tag_to_level ($tag, $level) {
    my $util_class;
    try {
        $util_class = $self->env->app_class( "Util::" . ucfirst($tag) );
    }
    catch {
        croak "problem with import tag ':$tag' ($_)";
    };
    $util_class->export_to_level( $level + 1, $util_class, ':all' );
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
    $self->env->app_class('Log')->get_logger( category => $caller );
}

method provide_var_poet ($caller) {
    $self->env;
}

1;

__END__

=pod

=head1 NAME

Poet::Import -- Import Poet quick vars and utilities

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw($conf $poet $log :file);

    # In a module...
    use Poet qw($conf $poet $log :file);

=head1 DESCRIPTION

Poet makes it easy to import certain variables (known as "quick vars") and
utility sets into any script or module in your environment.

In a script:

    use Poet::Script qw(...);

and in a module:

    use Poet qw(...);

where C<...> contains one or more quick var names (e.g. C<$conf>, C<$poet>)
and/or utility tags (e.g. C<:file>, C<:web>).

(Note that C<use Poet::Script> is also necessary for initializing the
environment, even if you don't care to import anything, whereas C<use Poet> has
no effect other than importing.)

=head1 QUICK VARS

Here is the built-in list of quick vars you can import. Some of the variables
are singletons, and some of them are specific to each package they are imported
into.

=over

=item $poet

The global environment object, provided by
L<Poet::Environment|Poet::Environment>. This provides information such as the
root directory and paths to subdirectories.

For backward compatibility this is also available as C<$env>.

=item $conf

The global configuration object, provided by L<Poet::Conf|Poet::Conf>.

=item $cache

The cache for the current package, provided by L<Poet::Cache|Poet::Cache>.

=item $log

The logger for the current package, provided by L<Poet::Log|Poet::Log>.

=back

=head1 UTILITIES

=head2 Default utilities

The utilities in L<Poet::Util::Debug|Poet::Util::Debug> are always imported,
with no tag necessary.

=head2 :file

This tag imports all the utilities in L<Poet::Util::File|Poet::Util::File>.

=head2 :web

This tag imports all the utilities in L<Poet::Util::Web|Poet::Util::Web>. It is
automatically included in all Mason components.

=head1 MASON COMPONENTS

Every Mason component automatically gets this on top:

    use Poet qw($conf $poet :web);

C<$m-E<gt>cache> and C<$m-E<gt>log> will get you the cache and log objects for
a particular Mason component.

=head1 CUSTOMIZING

=head2 Adding variables

To add your own variable, define a method called provide_var_I<varname> in
C<MyApp::Import>. For example to add a variable C<$dbh>:

    package MyApp::Import;
    use Poet::Moose;
    extends 'Poet::Import';

    method provide_var_dbh ($caller) {
        # Generate and return a dbh.
        # $caller is the package importing the variable.
        # $poet is the current Poet environment.
    }

C<provide_dbh> can return a single global value, or a dynamic value depending
on C<$caller>.

Now your scripts and libraries can do

    use Poet::Script qw($dbh);
    use Poet qw($dbh);

=head2 Adding utility tags

To add your own utility tag, define a class C<MyApp::Util::Mytagname> that
exports a set of functions via the ':all' tag. For example:

    package MyApp::Util::Hash;
    use Hash::Util qw(hash_seed all_keys);
    use Hash::MoreUtils qw(slice slice_def slice_exists);
    
    our @EXPORT_OK = qw(hash_seed all_keys slice slice_def slice_exists);
    our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

    1;

Now your scripts and libraries can do

    use Poet::Script qw(:hash);
    use Poet qw(:hash);

=head2 Other exports

To export other general things to the calling class, you can override
C<export_to_class>, which takes the calling class as its argument. e.g.

    package MyApp::Import;
    use Poet::Moose;
    extends 'Poet::Import';

    before 'export_to_class' => sub {
        my ($self, $class) = @_;
        no strict 'refs';
        %{$class . "::some_name"} = ...;
    }

=over

=back
