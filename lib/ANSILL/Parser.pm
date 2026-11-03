package ANSILL::Parser;
# ABSTRACT: Line-oriented parser for ANSILL source files

our $VERSION = '0.001';

use Moo;
use Types::Standard qw( Str ArrayRef );
use ANSILL::AST;
use Carp qw( croak );

has source => (
  is => 'ro',
  isa => Str,
  required => 1,
);

has _lines => (
  is => 'lazy',
  builder => sub { [split /\n/, $_[0]->source] },
);

has _pos => (
  is => 'rw',
  default => 0,
);

has _diagnostics => (
  is => 'ro',
  isa => ArrayRef,
  default => sub { [] },
);

sub diagnostics { $_[0]->_diagnostics }

sub parse {
  my ($self) = @_;
  my $ast = ANSILL::AST->new;

  while ($self->_pos < scalar @{$self->_lines}) {
    my $line = $self->_current_line;
    $self->_advance;

    # Skip empty lines and comments
    next if $line =~ /^\s*$/;
    next if $line =~ /^\s*#/;

    # Strip inline comments (not inside strings)
    $line = $self->_strip_comment($line);
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    my $node = $self->_parse_statement($line);
    $ast->add_node($node) if $node;
  }

  return $ast;
}

sub _current_line {
  my ($self) = @_;
  return $self->_lines->[$self->_pos];
}

sub _advance {
  my ($self) = @_;
  $self->_pos($self->_pos + 1);
}

sub _strip_comment {
  my ($self, $line) = @_;
  my $in_string = 0;
  my $escaped = 0;

  for my $i (0 .. length($line) - 1) {
    my $ch = substr($line, $i, 1);
    if ($escaped) {
      $escaped = 0;
      next;
    }
    if ($ch eq '\\') {
      $escaped = 1;
      next;
    }
    if ($ch eq '"') {
      $in_string = !$in_string;
      next;
    }
    if ($ch eq '#' && !$in_string) {
      return substr($line, 0, $i);
    }
  }
  return $line;
}

sub _parse_statement {
  my ($self, $line) = @_;

  my ($cmd, $rest) = $line =~ /^(\S+)\s*(.*)/;
  return unless $cmd;

  my $method = "_parse_cmd_$cmd";
  $method =~ s/-/_/g;

  if ($self->can($method)) {
    return $self->$method($rest);
  }

  $self->_diag(warning => "Unknown command: '$cmd'");
  return undef;
}

# --- Declaration parsers ---

sub _parse_cmd_ansill {
  my ($self, $rest) = @_;
  return ANSILL::AST::Version->new(version => $rest);
}

sub _parse_cmd_canvas {
  my ($self, $rest) = @_;
  my ($w, $h) = $rest =~ /^(\d+)x(\d+)/
    or croak "Invalid canvas size: '$rest'";

  my %opts;
  if ($rest =~ /wrap=(\S+)/) {
    $opts{wrap} = $1;
  }

  return ANSILL::AST::Canvas->new(
    width => $w, height => $h, %opts,
  );
}

sub _parse_cmd_profile {
  my ($self, $rest) = @_;
  my ($name) = $rest =~ /^(\S+)/;
  return ANSILL::AST::Profile->new(name => $name);
}

sub _parse_cmd_colors {
  my ($self, $rest) = @_;
  my ($sys) = $rest =~ /^(\S+)/;
  return ANSILL::AST::Colors->new(system => $sys);
}

sub _parse_cmd_policy {
  my ($self, $rest) = @_;
  my ($level) = $rest =~ /^(\S+)/;
  return ANSILL::AST::Policy->new(level => $level);
}

sub _parse_cmd_layer {
  my ($self, $rest) = @_;
  my ($name) = $rest =~ /^(\S+)/;
  return ANSILL::AST::Layer->new(name => $name);
}

sub _parse_cmd_let {
  my ($self, $rest) = @_;
  my ($name, $value) = $rest =~ /^(\S+)\s*=\s*(.+)/
    or croak "Invalid let statement: '$rest'";
  return ANSILL::AST::Let->new(name => $name, value => $value);
}

sub _parse_cmd_meta {
  my ($self, $rest) = @_;
  my ($key, $value) = $rest =~ /^(\S+)\s*=\s*"?([^"]*)"?\s*$/
    or croak "Invalid meta statement: '$rest'";
  return ANSILL::AST::Meta->new(key => $key, value => $value);
}

sub _parse_cmd_import {
  my ($self, $rest) = @_;
  my ($file) = $rest =~ /^"([^"]+)"/
    or croak "Invalid import: '$rest'";
  my ($ns) = $rest =~ /\bas\s+(\S+)/;
  return ANSILL::AST::Import->new(file => $file, namespace => $ns);
}

# --- Block parsers ---

sub _parse_cmd_palette {
  my ($self, $rest) = @_;
  my ($name) = $rest =~ /^(\S+)/
    or croak "Palette needs a name";

  my $entries = $self->_parse_block;
  my %parsed;
  for my $line (@$entries) {
    if ($line =~ /^\s*(\S+)\s*=\s*(.+?)\s*$/) {
      $parsed{$1} = $2;
    }
  }

  return ANSILL::AST::Palette->new(name => $name, entries => \%parsed);
}

sub _parse_cmd_style {
  my ($self, $rest) = @_;
  my ($name) = $rest =~ /^(\S+)/
    or croak "Style needs a name";

  my $entries = $self->_parse_block;
  my %props;
  for my $line (@$entries) {
    if ($line =~ /^\s*(\S+)\s*=\s*(.+?)\s*$/) {
      my ($k, $v) = ($1, $2);
      $k =~ s/-/_/g;
      $props{$k} = $v eq 'true' ? 1 : $v eq 'false' ? 0 : $v;
    }
  }

  return ANSILL::AST::Style->new(name => $name, props => \%props);
}

sub _parse_cmd_symbol {
  my ($self, $rest) = @_;
  my ($name, $w, $h) = $rest =~ /^(\S+)\s+(\d+)x(\d+)/
    or croak "Symbol needs name and dimensions: '$rest'";

  my $body = $self->_parse_block;
  my @commands;
  for my $line (@$body) {
    $line =~ s/^\s+//;
    next unless $line;
    my $node = $self->_parse_statement($line);
    push @commands, $node if $node;
  }

  return ANSILL::AST::Symbol->new(
    name => $name, width => $w, height => $h,
    commands => \@commands,
  );
}

sub _parse_cmd_macro {
  my ($self, $rest) = @_;
  my @tokens = $self->_tokenize($rest);
  my $name = shift @tokens;

  # Params are everything before the opening brace
  my @params;
  while (@tokens && $tokens[0] ne '{') {
    push @params, shift @tokens;
  }

  my $body_lines = $self->_parse_block;

  return ANSILL::AST::Macro->new(
    name => $name,
    params => \@params,
    body => $body_lines,
  );
}

sub _parse_block {
  my ($self) = @_;
  my @lines;

  # Current line should have ended with {, or next line starts block
  while ($self->_pos < scalar @{$self->_lines}) {
    my $line = $self->_current_line;
    $self->_advance;

    $line = $self->_strip_comment($line);
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    next if $line eq '{';
    last if $line eq '}';

    push @lines, $line if $line;
  }

  return \@lines;
}

# --- Drawing command parsers ---

sub _parse_cmd_put {
  my ($self, $rest) = @_;
  my @tokens = $self->_tokenize($rest);
  my ($x, $y) = $self->_parse_coord(shift @tokens);
  my %attrs = $self->_parse_kvpairs(@tokens);

  return ANSILL::AST::Put->new(x => $x, y => $y, attrs => \%attrs);
}

sub _parse_cmd_text {
  my ($self, $rest) = @_;
  my @tokens = $self->_tokenize($rest);
  my ($x, $y) = $self->_parse_coord(shift @tokens);
  my $text = shift @tokens // '';
  my %attrs = $self->_parse_kvpairs(@tokens);

  return ANSILL::AST::Text->new(
    x => $x, y => $y, text => $text, attrs => \%attrs,
  );
}

sub _parse_cmd_fill {
  my ($self, $rest) = @_;
  my @tokens = $self->_tokenize($rest);
  my ($x1, $y1) = $self->_parse_coord(shift @tokens);
  my ($x2, $y2) = $self->_parse_coord(shift @tokens);
  my %attrs = $self->_parse_kvpairs(@tokens);

  return ANSILL::AST::Fill->new(
    x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2, attrs => \%attrs,
  );
}

sub _parse_cmd_line {
  my ($self, $rest) = @_;
  my @tokens = $self->_tokenize($rest);
  my ($x1, $y1) = $self->_parse_coord(shift @tokens);
  my ($x2, $y2) = $self->_parse_coord(shift @tokens);
  my %attrs = $self->_parse_kvpairs(@tokens);

  return ANSILL::AST::Line->new(
    x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2, attrs => \%attrs,
  );
}

sub _parse_cmd_box {
  my ($self, $rest) = @_;
  my @tokens = $self->_tokenize($rest);
  my ($x1, $y1) = $self->_parse_coord(shift @tokens);
  my ($x2, $y2) = $self->_parse_coord(shift @tokens);
  my %attrs = $self->_parse_kvpairs(@tokens);

  return ANSILL::AST::Box->new(
    x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2, attrs => \%attrs,
  );
}

sub _parse_cmd_panel {
  my ($self, $rest) = @_;
  my @tokens = $self->_tokenize($rest);
  my ($x1, $y1) = $self->_parse_coord(shift @tokens);
  my ($x2, $y2) = $self->_parse_coord(shift @tokens);
  my %attrs = $self->_parse_kvpairs(@tokens);

  return ANSILL::AST::Panel->new(
    x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2, attrs => \%attrs,
  );
}

sub _parse_cmd_repeat {
  my ($self, $rest) = @_;
  my @tokens = $self->_tokenize($rest);
  my ($x1, $y1) = $self->_parse_coord(shift @tokens);
  my ($x2, $y2) = $self->_parse_coord(shift @tokens);
  my %attrs = $self->_parse_kvpairs(@tokens);

  return ANSILL::AST::Repeat->new(
    x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2, attrs => \%attrs,
  );
}

sub _parse_cmd_blit {
  my ($self, $rest) = @_;
  my @tokens = $self->_tokenize($rest);
  my $symbol = shift @tokens;

  # Skip "at" keyword
  shift @tokens if @tokens && $tokens[0] eq 'at';

  my ($x, $y) = $self->_parse_coord(shift @tokens);
  my %attrs = $self->_parse_kvpairs(@tokens);

  return ANSILL::AST::Blit->new(
    symbol => $symbol, x => $x, y => $y, attrs => \%attrs,
  );
}

sub _parse_cmd_clear {
  my ($self, $rest) = @_;
  my @tokens = $self->_tokenize($rest);
  my ($x1, $y1) = $self->_parse_coord(shift @tokens);
  my ($x2, $y2) = $self->_parse_coord(shift @tokens);

  return ANSILL::AST::Clear->new(
    x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2,
  );
}

sub _parse_cmd_center_text {
  my ($self, $rest) = @_;
  my @tokens = $self->_tokenize($rest);

  # center-text y=N "text" attrs...
  my %initial = $self->_parse_kvpairs(grep { /=/ } @tokens);
  my @non_kv = grep { !/=/ } @tokens;

  my $y = delete $initial{y} // croak "center-text requires y=N";
  my $text = $non_kv[0] // '';
  $initial{align} = 'center';

  return ANSILL::AST::Text->new(
    x => 0, y => $y, text => $text, attrs => \%initial,
  );
}

sub _parse_cmd_right_text {
  my ($self, $rest) = @_;
  my @tokens = $self->_tokenize($rest);
  my ($x, $y) = $self->_parse_coord(shift @tokens);
  my $text = shift @tokens // '';
  my %attrs = $self->_parse_kvpairs(@tokens);
  $attrs{align} = 'right';

  return ANSILL::AST::Text->new(
    x => $x, y => $y, text => $text, attrs => \%attrs,
  );
}

# --- Utility methods ---

sub _tokenize {
  my ($self, $str) = @_;
  my @tokens;
  $str //= '';

  while ($str =~ /\S/) {
    $str =~ s/^\s+//;

    # key="quoted value"
    if ($str =~ s/^([A-Za-z_][A-Za-z0-9_-]*)="((?:[^"\\]|\\.)*)"//) {
      my ($key, $val) = ($1, $2);
      $val =~ s/\\"/"/g;
      $val =~ s/\\\\/\\/g;
      $val =~ s/\\n/\n/g;
      $val =~ s/\\t/\t/g;
      push @tokens, "$key=$val";
    }
    # standalone "quoted string"
    elsif ($str =~ s/^"((?:[^"\\]|\\.)*)"//) {
      my $val = $1;
      $val =~ s/\\"/"/g;
      $val =~ s/\\\\/\\/g;
      $val =~ s/\\n/\n/g;
      $val =~ s/\\t/\t/g;
      push @tokens, $val;
    } elsif ($str =~ s/^(\S+)//) {
      push @tokens, $1;
    }
  }

  return @tokens;
}

sub _parse_coord {
  my ($self, $token) = @_;
  croak "Expected coordinate, got nothing" unless defined $token;
  my ($x, $y) = $token =~ /^(\d+),(\d+)$/
    or croak "Invalid coordinate: '$token'";
  return ($x, $y);
}

sub _parse_kvpairs {
  my ($self, @tokens) = @_;
  my %kv;
  for my $token (@tokens) {
    if ($token =~ /^([^=]+)=(.*)$/) {
      my ($k, $v) = ($1, $2);
      $k =~ s/-/_/g;
      $v = 1 if $v eq 'true';
      $v = 0 if $v eq 'false';
      $kv{$k} = $v;
    }
  }
  return %kv;
}

sub _diag {
  my ($self, $level, $msg) = @_;
  push @{$self->_diagnostics}, {
    level => $level,
    line  => $self->_pos,
    message => $msg,
  };
}

1;
