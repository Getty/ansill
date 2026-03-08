use strict;
use warnings;
use utf8;
use Test::More;
use ANSILL::Profile;

my $ascii = ANSILL::Profile->load('ascii');
is $ascii->resolve_glyph('line-h'), '-', 'ascii line-h';
is $ascii->resolve_glyph('corner-tl'), '+', 'ascii corner-tl';
is $ascii->resolve_glyph('shade-light'), '.', 'ascii shade-light';
is $ascii->resolve_glyph('block-full'), '#', 'ascii block-full';
ok $ascii->glyph_allowed('A'), 'A allowed in ascii';
ok !$ascii->glyph_allowed("\x{2588}"), 'block not allowed in ascii';

my $cp437 = ANSILL::Profile->load('cp437');
is $cp437->resolve_glyph('line-h'), "\x{2500}", 'cp437 line-h';
is $cp437->resolve_glyph('corner-tl'), "\x{250C}", 'cp437 corner-tl';
is $cp437->resolve_glyph('shade-light'), "\x{2591}", 'cp437 shade-light';

my $unicode = ANSILL::Profile->load('unicode');
ok $unicode->resolve_glyph('round-tl'), 'unicode has round corners';

# Line sets
my $single = $ascii->line_set_glyphs('single');
is $single->{h}, '-';
is $single->{v}, '|';
is $single->{tl}, '+';

my $double = $cp437->line_set_glyphs('double');
is $double->{h}, "\x{2550}", 'double line-h';

done_testing;
