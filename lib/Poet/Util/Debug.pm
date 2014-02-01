package Poet::Util::Debug;

use Carp qw(longmess);
use Data::Dumper;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK =
  map { ( "$_", "$_" . "s", "$_" . "_live", "$_" . "s_live" ) } qw(dc dd dh dp);
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

my $console_log;

sub _dump_value_with_caller {
    my ( $value, $func_name ) = @_;

    my $dump =
      Data::Dumper->new( [$value] )->Indent(1)->Sortkeys(1)->Quotekeys(0)->Terse(1)->Dump();
    my @caller = caller(1);
    return
      sprintf( "[%s at %s line %d.] [%d] %s\n", $func_name, $caller[1], $caller[2], $$, $dump );
}

sub _define {
    my ( $func, $code ) = @_;

    no strict 'refs';
    my $funcs      = $func . "s";
    my $func_live  = $func . "_live";
    my $funcs_live = $func . "s_live";

    *$func = sub {
        return unless Poet::Environment->current_env->conf->is_development;
        $code->( _dump_value_with_caller( $_[0], $func ) );
    };
    *$funcs = sub {
        return unless Poet::Environment->current_env->conf->is_development;
        $code->( longmess( _dump_value_with_caller( $_[0], $funcs ) ) );
    };
    *$func_live = sub {
        $code->( _dump_value_with_caller( $_[0], $func_live ) );
    };
    *$funcs_live = sub {
        $code->( longmess( _dump_value_with_caller( $_[0], $funcs_live ) ) );
    };
}

_define(
    'dc',
    sub {
        $console_log ||= Poet::Environment->current_env->logs_path("console.log");
        open( my $fh, ">>", $console_log );
        $fh->print( $_[0] );
    }
);

_define(
    'dd',
    sub {
        die $_[0];
    }
);

_define(
    'dh',
    sub {
        return "<pre>\n$_[0]</pre>\n";
    }
);

_define(
    'dp',
    sub {
        print STDERR $_[0];
    }
);

1;

__END__

=pod

=head1 NAME

Poet::Util::Debug - Debug utilities

=head1 SYNOPSIS

    # In a script...
    use Poet::Script;

    # In a module...
    use Poet;

    # Automatically available in Mason components

    # then...

    # die with value
    dd $data;

    # print value to STDERR
    dp $data;

    # print value to logs/console.log
    dc $data;

    # return value prepped for HTML
    dh $data;

    # same as above with full stacktraces
    dds $data;
    dps $data;
    dcs $data;
    dhs $data;

=head1 DESCRIPTION

These debug utilities are automatically imported wherever C<use Poet> or C<use
Poet::Script> appear, and in all components. Because let's face it, debugging
is something you always want at your fingertips.

However, for safety, the short named versions of these utilities are no-ops
outside of L<development mode|Poet::Manual::Intro/Development versus live
mode>, in case debug statements accidentally leak into production (we've all
done it). You have to use longer, less convenient names outside of development
for them to work.

=head1 UTILITIES

Each of these utilities takes a single scalar value. The value is serialized
with L<Data::Dumper|Data::Dumper> and prefixed with a file name, line number,
and pid. e.g.

    dp { a => 5, b => 6 };

prints to STDERR

    [dp at ./d.pl line 6.] [1436] {
      a => 5,
      b => 6
    }

The variants suffixed with 's' additionally output a full stack trace.

=over

=item dd ($val), dds ($val)

Die with the serialized I<$val>.

=item dp ($val), dps ($val)

Print the serialized I<$val> to STDERR. Useful in scripts.

=item dc ($val), dcs ($val)

Append the serialized I<$val> to "console.log" in the C<logs> subdirectory of
the environment. Useful as a quick alternative to full-bore
L<logging|Poet::Log>.

=item dh ($val), dhs ($val)

Returns the serialized I<$val>, surrounded by C<< <pre> </pre> >> tags. Useful
for embedding in Mason components, e.g.

    <% dh($data) %>

=back

=head2 Live variants

Each of the functions above must be appended with "_live" in order to work in
L<live mode|Poet::Manual::Intro/Development versus live mode>. e.g.

    # This is a no-op in live mode
    dp [$foo];

    # but this will work
    dp_live [$foo];
