package ANSILL::Backend::HTML;
# ABSTRACT: HTML preview backend for ANSILL

our $VERSION = '0.001';

use Moo;
use Types::Standard qw( InstanceOf Str );

has grid => (
  is => 'ro',
  isa => InstanceOf['ANSILL::Grid'],
  required => 1,
);

has title => (
  is => 'ro',
  isa => Str,
  default => 'ANSILL Preview',
);

my @ANSI16_HEX = (
  '#000000', '#aa0000', '#00aa00', '#aa5500',
  '#0000aa', '#aa00aa', '#00aaaa', '#aaaaaa',
  '#555555', '#ff5555', '#55ff55', '#ffff55',
  '#5555ff', '#ff55ff', '#55ffff', '#ffffff',
);

sub emit {
  my ($self) = @_;
  my $grid = $self->grid;
  my $title = _html_escape($self->title);

  my $html = <<"HEAD";
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>$title</title>
<style>
body { background: #000; margin: 20px; }
pre.ansill {
  font-family: "IBM Plex Mono", "Cascadia Code", "Consolas", monospace;
  font-size: 14px;
  line-height: 1.2;
  letter-spacing: 0;
}
</style>
</head>
<body>
<pre class="ansill">
HEAD

  my ($prev_fg, $prev_bg, $prev_bold) = (-1, -1, -1);
  my $span_open = 0;

  for my $y (1 .. $grid->height) {
    for my $x (1 .. $grid->width) {
      my $cell = $grid->get($x, $y);
      my $fg = $cell->fg // 7;
      my $bg = $cell->bg // 0;
      my $bold = $cell->bold ? 1 : 0;

      if ($fg != $prev_fg || $bg != $prev_bg || $bold != $prev_bold) {
        $html .= "</span>" if $span_open;

        my $fg_hex = $ANSI16_HEX[$fg] // '#aaaaaa';
        my $bg_hex = $ANSI16_HEX[$bg] // '#000000';
        my $weight = $bold ? 'font-weight:bold;' : '';

        $html .= qq{<span style="color:$fg_hex;background:$bg_hex;$weight">};
        $span_open = 1;

        $prev_fg = $fg;
        $prev_bg = $bg;
        $prev_bold = $bold;
      }

      $html .= _html_escape($cell->glyph);
    }

    $html .= "</span>" if $span_open;
    $html .= "\n";
    $span_open = 0;
    ($prev_fg, $prev_bg, $prev_bold) = (-1, -1, -1);
  }

  $html .= "</pre>\n</body>\n</html>\n";
  return $html;
}

sub _html_escape {
  my ($str) = @_;
  $str =~ s/&/&amp;/g;
  $str =~ s/</&lt;/g;
  $str =~ s/>/&gt;/g;
  $str =~ s/"/&quot;/g;
  return $str;
}

1;
