package Poet::Log;
use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

Poet::Log -- Provides log objects

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw($log);

    # In a module...
    use Poet qw($log);

    # In a component...
    my $log = $m->log;

    # then...
    $log->error("an error occurred");
    $log->debugf("arguments are: %s", \@_)
        if $log->is_debug();

=head1 DESCRIPTION

Poet::Log provides the log object when you import the Poet C<$log> variable. It
uses L<log4perl|Log::Log4perl> as the engine but provides simpler configuration
via Poet conf files.

=head1 CONFIGURATION



=head1 SEE ALSO

Poet

=cut
