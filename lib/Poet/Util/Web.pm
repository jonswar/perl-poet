package Poet::Util::Web;
use Data::Dumper;
use URI;
use URI::Escape qw(uri_escape uri_unescape);
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(html_escape js_escape make_uri uri_escape uri_unescape);
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

my %html_escape =
  ( '&' => '&amp;', '>' => '&gt;', '<' => '&lt;', '"' => '&quot;' );
my $html_escape = qr/([&<>"])/;

# Stolen from Javascript::Value::Escape
my %js_escape = (
    q!\\!      => 'u005c',
    q!"!       => 'u0022',
    q!'!       => 'u0027',
    q!<!       => 'u003c',
    q!>!       => 'u003e',
    q!&!       => 'u0026',
    q!=!       => 'u003d',
    q!-!       => 'u002d',
    q!;!       => 'u003b',
    q!+!       => 'u002b',
    "\x{2028}" => 'u2028',
    "\x{2029}" => 'u2029',
);
map { $js_escape{ pack( 'U', $_ ) } = sprintf( "u%04d", $_ ) }
  ( 0x00 .. 0x1f, 0x7f );

sub html_escape {
    my $text = $_[0];
    $text =~ s/$html_escape/$html_escape{$1}/mg;
    return $text;
}

sub js_escape {
    my $text = shift;
    $text =~
      s!([\\"'<>&=\-;\+\x00-\x1f\x7f]|\x{2028}|\x{2029})!\\$js_escape{$1}!g;
    return $text;
}

sub make_uri {
    my ( $base, $params ) = @_;

    my $uri = URI->new($base);
    $uri->query_form($params) if defined($params);
    return $uri->as_string;
}

1;

__END__

=pod

=head1 NAME

Poet::Util::Web - Web-related utilities

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw(:web);

    # In a module...
    use Poet qw(:web);

    # Automatically available in Mason components

=head1 DESCRIPTION

This group of utilities includes

=over

=item html_escape ($str)

Return I<$str> with HTML entities escaped/unescaped.

=item uri_escape ($str), uri_unescape ($str)

Return I<$str> URI escaped/unescaped, from L<URI::Escape|URI::Escape>

=item js_escape ($str)

Return I<$str> escaped for Javascript, borrowed from
L<JavaScript::Value::Escape|JavaScript::Value::Escape>.

=item make_uri ($path, $args)

Create a URL by combining I<$path> with a query string formed from hashref
I<$args>. e.g.

    make_uri("/foo/bar", { a => 5, b => 6 });
        ==> /foo/bar?a=5&b=6

=back
