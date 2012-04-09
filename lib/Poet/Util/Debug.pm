package Poet::Util::Debug;
use Carp qw(longmess);
use Data::Dumper;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(
  dc
  dcs
  dd
  dh
  dhs
  dp
  dps
);

my $console_log;

sub _dump_value_with_caller {
    my ($value) = @_;

    my $dump =
      Data::Dumper->new( [$value] )->Indent(1)->Sortkeys(1)->Quotekeys(0)
      ->Terse(1)->Dump();
    my @caller = caller(1);
    return sprintf( "[dp at %s line %d.] %s\n", $caller[1], $caller[2], $dump );
}

sub dc {
    return if _debug_disabled();
    my $fh = _open_console_log();
    $fh->print( _dump_value_with_caller(@_) );
}

sub dcs {
    return if _debug_disabled();
    my $fh = _open_console_log();
    $fh->print( longmess( _dump_value_with_caller(@_) ) );
}

sub dd {
    return if _debug_disabled();
    die _dump_value_with_caller(@_);
}

sub dh {
    return if _debug_disabled();
    print "<pre>\n" . _dump_value_with_caller(@_) . "\n</pre>\n";
}

sub dhs {
    return if _debug_disabled();
    print "<pre>\n" . longmess( _dump_value_with_caller(@_) ) . "\n</pre>\n";
}

sub dp {
    return if _debug_disabled();
    print STDERR _dump_value_with_caller(@_);
}

sub dps {
    return if _debug_disabled();
    print STDERR longmess( _dump_value_with_caller(@_) );
}

sub _debug_disabled {
    return Poet::Environment->instance->conf->get_boolean(
        'debug.disable_utils');
}

sub _open_console_log {
    $console_log ||= Poet::Environment->instance->log_path("console.log");
    open( my $fh, ">>$console_log" );
    return $fh;
}

1;
