package ANSILL::Grid;
# ABSTRACT: 2D cell grid for ANSILL rendering

use Moo;
use Types::Standard qw( Int ArrayRef Str );
use ANSILL::Cell;
use Carp qw( croak );

has width => (
  is => 'ro',
  isa => Int,
  required => 1,
);

has height => (
  is => 'ro',
  isa => Int,
  required => 1,
);

has wrap => (
  is => 'ro',
  isa => Str,
  default => 'clip',
);

has _cells => (
  is => 'lazy',
  isa => ArrayRef,
  builder => '_build_cells',
);

sub _build_cells {
  my ($self) = @_;
  my @grid;
  for my $y (0 .. $self->height - 1) {
    my @row;
    for my $x (0 .. $self->width - 1) {
      push @row, ANSILL::Cell->new;
    }
    push @grid, \@row;
  }
  return \@grid;
}

sub in_bounds {
  my ($self, $x, $y) = @_;
  return $x >= 1 && $x <= $self->width && $y >= 1 && $y <= $self->height;
}

sub _check_bounds {
  my ($self, $x, $y) = @_;
  if (!$self->in_bounds($x, $y)) {
    if ($self->wrap eq 'error') {
      croak "Coordinates ($x,$y) out of bounds (canvas: "
        . $self->width . "x" . $self->height . ")";
    }
    return 0; # clip
  }
  return 1;
}

sub get {
  my ($self, $x, $y) = @_;
  return undef unless $self->_check_bounds($x, $y);
  return $self->_cells->[$y-1][$x-1];
}

sub put {
  my ($self, $x, $y, %attrs) = @_;
  return unless $self->_check_bounds($x, $y);

  my $cell = $self->_cells->[$y-1][$x-1];
  return if $cell->protect;

  for my $attr (keys %attrs) {
    $cell->$attr($attrs{$attr}) if $cell->can($attr);
  }
}

sub fill_rect {
  my ($self, $x1, $y1, $x2, $y2, %attrs) = @_;
  for my $y ($y1 .. $y2) {
    for my $x ($x1 .. $x2) {
      $self->put($x, $y, %attrs);
    }
  }
}

sub put_text {
  my ($self, $x, $y, $text, %attrs) = @_;
  my @chars = split //, $text;
  for my $i (0 .. $#chars) {
    my $cx = $x + $i;
    if ($attrs{transparent} && $chars[$i] eq ' ') {
      next;
    }
    $self->put($cx, $y, glyph => $chars[$i], %attrs);
  }
}

sub to_text {
  my ($self) = @_;
  my @lines;
  for my $y (0 .. $self->height - 1) {
    my $line = '';
    for my $x (0 .. $self->width - 1) {
      $line .= $self->_cells->[$y][$x]->glyph;
    }
    $line =~ s/\s+$//;
    push @lines, $line;
  }
  # Remove trailing empty lines
  pop @lines while @lines && $lines[-1] eq '';
  return join("\n", @lines) . "\n";
}

1;
