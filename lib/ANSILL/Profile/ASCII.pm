package ANSILL::Profile::ASCII;
# ABSTRACT: ASCII profile - strict printable ASCII only

use Moo;
extends 'ANSILL::Profile';

sub _build_glyph_map {
  return {
    # Single lines
    'line-h'     => '-',
    'line-v'     => '|',
    'corner-tl'  => '+',
    'corner-tr'  => '+',
    'corner-bl'  => '+',
    'corner-br'  => '+',
    'tee-up'     => '+',
    'tee-down'   => '+',
    'tee-left'   => '+',
    'tee-right'  => '+',
    'cross'      => '+',

    # Double lines (degrade to ASCII equivalents)
    'd-line-h'     => '=',
    'd-line-v'     => '|',
    'd-corner-tl'  => '+',
    'd-corner-tr'  => '+',
    'd-corner-bl'  => '+',
    'd-corner-br'  => '+',

    # Shading
    'shade-light'  => '.',
    'shade-medium' => ':',
    'shade-dark'   => '#',

    # Blocks
    'block-full'        => '#',
    'block-half-top'    => '~',
    'block-half-bottom' => '_',
    'block-half-left'   => '[',
    'block-half-right'  => ']',

    # Decorative
    'bullet'       => '*',
    'diamond'      => '*',
    'arrow-left'   => '<',
    'arrow-right'  => '>',
    'arrow-up'     => '^',
    'arrow-down'   => 'v',
  };
}

sub _check_glyph {
  my ($self, $glyph) = @_;
  return length($glyph) == 1 && ord($glyph) >= 0x20 && ord($glyph) <= 0x7E;
}

1;
