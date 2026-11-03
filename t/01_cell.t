#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use ANSILL::Cell;

my $cell = ANSILL::Cell->new;
is $cell->glyph, ' ', 'default glyph is space';
is $cell->fg, 7, 'default fg is 7';
is $cell->bg, 0, 'default bg is 0';
ok !$cell->bold, 'default bold is false';
ok !$cell->protect, 'default protect is false';

$cell->glyph('A');
$cell->fg(14);
$cell->bold(1);
is $cell->glyph, 'A', 'glyph set';
is $cell->fg, 14, 'fg set';
ok $cell->bold, 'bold set';

my $clone = $cell->clone;
is $clone->glyph, 'A', 'clone preserves glyph';
is $clone->fg, 14, 'clone preserves fg';

$clone->glyph('B');
is $cell->glyph, 'A', 'clone is independent';

ok $cell->attrs_equal($cell->clone), 'attrs_equal on identical';

my $diff = ANSILL::Cell->new(fg => 1);
ok !$cell->attrs_equal($diff), 'attrs_equal on different';

done_testing;
