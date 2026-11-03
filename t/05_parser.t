#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use ANSILL::Parser;

my $source = <<'ANSILL';
ansill 0.2
canvas 80x25
profile cp437
colors ansi16
policy warn-fallback

palette retro {
  border = bright-cyan
  bg-main = blue
}

style titlebar {
  fg = bright-white
  bg = blue
  bold = true
}

layer background
layer content

fill 1,1 80,25 glyph=" " fg=7 bg=0
box 1,1 80,25 style=double fg=14
text 3,2 "HELLO WORLD" fg=15 bg=1
panel 3,5 35,14 style=single title="STATUS" fg=10 bg=0
put 10,10 glyph="X" fg=14
repeat 3,9 28,9 pattern="-=" fg=11
clear 1,1 10,5

# a comment
let mid = 40

meta title = "TEST"
ANSILL

my $parser = ANSILL::Parser->new(source => $source);
my $ast = $parser->parse;

my @nodes = @{$ast->nodes};
ok @nodes > 0, 'parsed some nodes';

# Check node types
is ref $nodes[0], 'ANSILL::AST::Version', 'first node is version';
is $nodes[0]->version, '0.2';

is ref $nodes[1], 'ANSILL::AST::Canvas', 'canvas node';
is $nodes[1]->width, 80;
is $nodes[1]->height, 25;

is ref $nodes[2], 'ANSILL::AST::Profile', 'profile node';
is $nodes[2]->name, 'cp437';

is ref $nodes[3], 'ANSILL::AST::Colors', 'colors node';
is ref $nodes[4], 'ANSILL::AST::Policy', 'policy node';

is ref $nodes[5], 'ANSILL::AST::Palette', 'palette node';
is $nodes[5]->name, 'retro';
is $nodes[5]->entries->{border}, 'bright-cyan';

is ref $nodes[6], 'ANSILL::AST::Style', 'style node';
is $nodes[6]->name, 'titlebar';
is $nodes[6]->props->{bold}, 1;

is ref $nodes[7], 'ANSILL::AST::Layer', 'layer node';
is ref $nodes[8], 'ANSILL::AST::Layer', 'second layer node';

is ref $nodes[9], 'ANSILL::AST::Fill', 'fill node';
is ref $nodes[10], 'ANSILL::AST::Box', 'box node';
is ref $nodes[11], 'ANSILL::AST::Text', 'text node';
is $nodes[11]->text, 'HELLO WORLD';

is ref $nodes[12], 'ANSILL::AST::Panel', 'panel node';
is $nodes[12]->attrs->{title}, 'STATUS';

is ref $nodes[13], 'ANSILL::AST::Put', 'put node';
is ref $nodes[14], 'ANSILL::AST::Repeat', 'repeat node';
is ref $nodes[15], 'ANSILL::AST::Clear', 'clear node';

is ref $nodes[16], 'ANSILL::AST::Let', 'let node';
is $nodes[16]->name, 'mid';
is $nodes[16]->value, '40';

is ref $nodes[17], 'ANSILL::AST::Meta', 'meta node';
is $nodes[17]->key, 'title';
is $nodes[17]->value, 'TEST';

done_testing;
