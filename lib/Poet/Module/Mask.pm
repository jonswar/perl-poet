package Poet::Module::Mask;

use strict;
use warnings;
use base qw(Module::Mask);

sub message {
    my ( $self, $filename ) = @_;
    return "Can't locate $filename in \@INC";
}

1;
