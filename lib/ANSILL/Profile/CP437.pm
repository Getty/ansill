package ANSILL::Profile::CP437;
# ABSTRACT: CP437 profile - classic DOS/BBS character set

use Moo;
use utf8;
extends 'ANSILL::Profile';

sub _build_glyph_map {
  return {
    # Single lines
    'line-h'     => "\x{2500}",  # ─
    'line-v'     => "\x{2502}",  # │
    'corner-tl'  => "\x{250C}",  # ┌
    'corner-tr'  => "\x{2510}",  # ┐
    'corner-bl'  => "\x{2514}",  # └
    'corner-br'  => "\x{2518}",  # ┘
    'tee-up'     => "\x{2534}",  # ┴
    'tee-down'   => "\x{252C}",  # ┬
    'tee-left'   => "\x{2524}",  # ┤
    'tee-right'  => "\x{251C}",  # ├
    'cross'      => "\x{253C}",  # ┼

    # Double lines
    'd-line-h'     => "\x{2550}",  # ═
    'd-line-v'     => "\x{2551}",  # ║
    'd-corner-tl'  => "\x{2554}",  # ╔
    'd-corner-tr'  => "\x{2557}",  # ╗
    'd-corner-bl'  => "\x{255A}",  # ╚
    'd-corner-br'  => "\x{255D}",  # ╝

    # Shading
    'shade-light'  => "\x{2591}",  # ░
    'shade-medium' => "\x{2592}",  # ▒
    'shade-dark'   => "\x{2593}",  # ▓

    # Blocks
    'block-full'        => "\x{2588}",  # █
    'block-half-top'    => "\x{2580}",  # ▀
    'block-half-bottom' => "\x{2584}",  # ▄
    'block-half-left'   => "\x{258C}",  # ▌
    'block-half-right'  => "\x{2590}",  # ▐

    # Decorative
    'bullet'       => "\x{2219}",  # ∙
    'diamond'      => "\x{2666}",  # ♦
    'arrow-left'   => "\x{25C4}",  # ◄
    'arrow-right'  => "\x{25BA}",  # ►
    'arrow-up'     => "\x{25B2}",  # ▲
    'arrow-down'   => "\x{25BC}",  # ▼
  };
}

1;
