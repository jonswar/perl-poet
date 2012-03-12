package Poet::Mason;
use Poet qw($conf $env);
use List::MoreUtils qw(uniq);
use Method::Signatures::Simple;
use Moose;

extends 'Mason';

my $instance;

method instance ($class:) {
    $instance ||= Mason->new();
    $instance;
}

method get_options ($class:) {
    my %defaults = (
        allow_globals => [qw($conf $env)],
        comp_root     => $env->comps_dir,
        data_dir      => $env->data_dir,
        plugins       => [ 'PSGIHandler', 'RouterSimple' ],
        %{ $conf->get_hash("mason") },
    );
    return %defaults;
}

method new ($class:) {
    my $mason = $class->SUPER::new( $class->get_options, @_ );
    $mason->_set_poet_globals;
    return $mason;
}

method _set_poet_globals () {
    my %allowed_globals = map { ( $_, 1 ) } @{ $self->allow_globals };
    $self->set_global( '$conf', $conf ) if $allowed_globals{'$conf'};
    $self->set_global( '$env',  $env )  if $allowed_globals{'$env'};
}

1;

__END__

=pod

=head1 NAME

Poet::Mason -- Manage Mason default settings and main instance

=head1 SYNOPSIS

    # In a conf file...
    mason:
      plugins:
        - Cache
        - TidyObjectFiles
        - +My::Mason::Plugin
      static_source: 1
      static_source_touch_file: ${root}/data/purge.dat

    # Get the main Mason instance
    my $mason = Poet::Mason->instance();

    # Create a new Mason object
    my $mason = Poet::Mason->new(...);

=head1 DESCRIPTION

This module manages default settings for Mason and maintains a main Mason
instance for handling web requests.

=head1 METHODS

=over

=item new

Returns a new main Mason instance, using options from L<get_options>.

=item instance

Returns the main Mason instance used for web requests, which is created with
options from L<get_options>.

=item get_options

Returns Mason options by combining L<default settings|DEFAULT SETTINGS> and
L<configuration|CONFIGURATION>.

=back

=head1 DEFAULT SETTINGS

=over

=item *

C<comp_root> is set to L<$env-E<gt>comps_dir|Poet::Environment/comps_dir>, by
default the C<comps> subdirectory under the environment root.

=item *

C<data_dir> is set to L<$env-E<gt>data_dir|Poet::Environment/data_dir>, by
default the C<data> subdirectory under the environment root.

=item *

C<plugins> is set to include L<PSGIHandler|Mason::Plugins::PSGIHandler> and
L<RouterSimple|Mason::Plugins::RouterSimple>, which are necessary and helpful
(respectively) for handling web requests.

=item *

C<allow_globals> is set to include C<$conf> and $<env>

=back

=head1 CONFIGURATION

The Poet configuration entry 'mason', if any, will be treated as a hash of
options that supplements and/or overrides the defaults above.

If you specify C<plugins>, make sure to include C<PSGIHandler> or a plugin with
an equivalent API.

=head1 POET VARIABLES

L<Poet variables|Poet/POET VARIABLES>C<$conf> and C<$env> are automatically
made available as package globals in all Mason components.

C<$m->E<gt>cache> and C<$m->E<gt>log> will get you the cache and log objects
for a particular Mason component.

