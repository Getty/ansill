use strict;
use warnings;
use Test::More;
use ANSILL::Color;

is(ANSILL::Color->parse_color('7'), 7, 'numeric index');
is(ANSILL::Color->parse_color('bright-cyan'), 14, 'named color');
is(ANSILL::Color->parse_color('black'), 0, 'black');
is(ANSILL::Color->parse_color('bright-white'), 15, 'bright-white');

my $rgb = ANSILL::Color->parse_color('#ff0000');
is(ref $rgb, 'HASH', 'hex returns hashref');
is($rgb->{r}, 255);
is($rgb->{g}, 0);
is($rgb->{b}, 0);

# (255,0,0) is closest to index 1 (170,0,0) = red, not bright-red (255,85,85)
is(ANSILL::Color->degrade_to_ansi16({r => 255, g => 0, b => 0}), 1,
  'pure red degrades to ansi red');
is(ANSILL::Color->degrade_to_ansi16({r => 255, g => 85, b => 85}), 9,
  'bright red exact match');

my $palette = { primary => 'bright-yellow' };
is(ANSILL::Color->parse_color('primary', $palette), 11, 'palette lookup');

done_testing;
