#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use File::Basename qw( basename );
use ANSILL;

my @examples = glob("examples/*.ansill");

for my $file (sort @examples) {
  my $name = basename($file, '.ansill');
  my $expected_file = "t/expected/$name.txt";

  SKIP: {
    skip "No reference output for $name", 1 unless -f $expected_file;

    my $got = ANSILL->compile_file($file, backend => 'plaintext');

    open my $fh, '<:utf8', $expected_file or die "Cannot read $expected_file: $!";
    my $expected = do { local $/; <$fh> };
    close $fh;

    is($got, $expected, "$name renders correctly");
  }
}

done_testing;
