package Poet::Util::Web;
use Data::Dumper;
use URI;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(html_escape js_escape make_uri);

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
