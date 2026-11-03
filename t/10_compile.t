#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use ANSILL;

my $source = <<'ANSILL';
ansill 0.2
canvas 20x5
profile ascii
colors ansi16

fill 1,1 20,5 glyph=" " fg=7 bg=0
box 1,1 20,5 style=single fg=14
text 3,2 "HELLO" fg=15
ANSILL

# PlainText backend
{
  my $ansill = ANSILL->new(source => $source, backend => 'plaintext');
  my $output = $ansill->compile;
  ok length($output) > 0, 'plaintext output produced';
  like $output, qr/HELLO/, 'contains text';
  like $output, qr/\+/, 'contains ascii corners';
  like $output, qr/\-/, 'contains ascii horizontal lines';
}

# ANSI backend
{
  my $ansill = ANSILL->new(source => $source, backend => 'ansi');
  my $output = $ansill->compile;
  ok length($output) > 0, 'ansi output produced';
  like $output, qr/\e\[/, 'contains escape sequences';
  like $output, qr/HELLO/, 'contains text';
}

# JSON backend
{
  my $ansill = ANSILL->new(source => $source, backend => 'json');
  my $output = $ansill->compile;
  like $output, qr/"width":20/, 'json has width';
  like $output, qr/"cells"/, 'json has cells';
}

# HTML backend
{
  my $ansill = ANSILL->new(source => $source, backend => 'html');
  my $output = $ansill->compile;
  like $output, qr/<html>/, 'html output';
  like $output, qr/HELLO/, 'html contains text';
}

# Validate
{
  my $ansill = ANSILL->new(source => $source, backend => 'plaintext');
  my $diags = $ansill->validate;
  is ref $diags, 'ARRAY', 'validate returns arrayref';
}

done_testing;
