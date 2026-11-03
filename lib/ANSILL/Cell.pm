package ANSILL::Cell;
# ABSTRACT: Single cell in an ANSILL grid

our $VERSION = '0.001';

use Moo;
use Types::Standard qw( Str Int Bool Maybe );

has glyph => (
  is => 'rw',
  isa => Str,
  default => ' ',
);

has fg => (
  is => 'rw',
  isa => Maybe[Int],
  default => 7,
);

has bg => (
  is => 'rw',
  isa => Maybe[Int],
  default => 0,
);

has bold => (
  is => 'rw',
  isa => Bool,
  default => 0,
);

has dim => (
  is => 'rw',
  isa => Bool,
  default => 0,
);

has italic => (
  is => 'rw',
  isa => Bool,
  default => 0,
);

has underline => (
  is => 'rw',
  isa => Bool,
  default => 0,
);

has blink => (
  is => 'rw',
  isa => Bool,
  default => 0,
);

has inverse => (
  is => 'rw',
  isa => Bool,
  default => 0,
);

has protect => (
  is => 'rw',
  isa => Bool,
  default => 0,
);

has layer => (
  is => 'rw',
  isa => Maybe[Str],
  default => undef,
);

has tag => (
  is => 'rw',
  isa => Maybe[Str],
  default => undef,
);

sub clone {
  my ($self) = @_;
  return (ref $self)->new(
    glyph     => $self->glyph,
    fg        => $self->fg,
    bg        => $self->bg,
    bold      => $self->bold,
    dim       => $self->dim,
    italic    => $self->italic,
    underline => $self->underline,
    blink     => $self->blink,
    inverse   => $self->inverse,
    protect   => $self->protect,
    layer     => $self->layer,
    tag       => $self->tag,
  );
}

sub attrs_equal {
  my ($self, $other) = @_;
  return $self->fg == $other->fg
      && $self->bg == $other->bg
      && $self->bold == $other->bold
      && $self->dim == $other->dim
      && $self->italic == $other->italic
      && $self->underline == $other->underline
      && $self->blink == $other->blink
      && $self->inverse == $other->inverse;
}

1;
