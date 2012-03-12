package Poet::Moose;
use Moose                      ();
use MooseX::HasDefaults::RO    ();
use MooseX::StrictConstructor  ();
use Method::Signatures::Simple ();
use Moose::Exporter;
use strict;
use warnings;
Moose::Exporter->setup_import_methods( also => ['Moose'] );

sub init_meta {
    my $class     = shift;
    my %params    = @_;
    my $for_class = $params{for_class};
    Method::Signatures::Simple->import( into => $for_class );
    Moose->init_meta(@_);
    MooseX::StrictConstructor->init_meta(@_);
    MooseX::HasDefaults::RO->init_meta(@_);
}

1;

__END__

=pod

=head1 NAME

Poet::Moose - Poet Moose policies

=head1 SYNOPSIS

    # instead of use Moose;
    use Poet::Moose;

=head1 DESCRIPTION

Sets certain Moose behaviors for Poet's internal classes. Using this module is
equivalent to

    use Moose;
    use MooseX::HasDefaults::RO;
    use MooseX::StrictConstructor;
    use Method::Signatures::Simple;
