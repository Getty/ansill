#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  ANSILL
  ANSILL::AST
  ANSILL::Backend::ANSI
  ANSILL::Backend::HTML
  ANSILL::Backend::JSON
  ANSILL::Backend::PlainText
  ANSILL::Cell
  ANSILL::Color
  ANSILL::Grid
  ANSILL::Parser
  ANSILL::Profile
  ANSILL::Profile::ASCII
  ANSILL::Profile::CP437
  ANSILL::Profile::Unicode
  ANSILL::Renderer
  ANSILL::Resolver
  ANSILL::Validator
)) {
  use_ok($_);
}

done_testing;
