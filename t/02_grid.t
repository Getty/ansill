#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use ANSILL::Grid;

my $grid = ANSILL::Grid->new(width => 10, height => 5);
is $grid->width, 10;
is $grid->height, 5;

ok $grid->in_bounds(1, 1), '1,1 in bounds';
ok $grid->in_bounds(10, 5), '10,5 in bounds';
ok !$grid->in_bounds(0, 1), '0,1 out of bounds';
ok !$grid->in_bounds(11, 1), '11,1 out of bounds';

$grid->put(1, 1, glyph => 'X', fg => 14);
my $cell = $grid->get(1, 1);
is $cell->glyph, 'X', 'put/get glyph';
is $cell->fg, 14, 'put/get fg';

$grid->put_text(3, 2, "HI", fg => 10);
is $grid->get(3, 2)->glyph, 'H';
is $grid->get(4, 2)->glyph, 'I';
is $grid->get(3, 2)->fg, 10;

$grid->fill_rect(1, 4, 5, 5, glyph => '#', fg => 1);
is $grid->get(1, 4)->glyph, '#';
is $grid->get(5, 5)->glyph, '#';

my $text = $grid->to_text;
ok length($text) > 0, 'to_text produces output';

# Clip mode: out of bounds writes are silently ignored
$grid->put(100, 100, glyph => 'Z');
ok 1, 'out of bounds put does not die in clip mode';

done_testing;
