package ANSILL::Backend::JSON;
# ABSTRACT: JSON cell grid export backend for ANSILL

our $VERSION = '0.001';

use Moo;
use Types::Standard qw( InstanceOf );
use JSON::MaybeXS qw( encode_json );

has grid => (
  is => 'ro',
  isa => InstanceOf['ANSILL::Grid'],
  required => 1,
);

# The JSON encoders decide number or string from the scalar's flags, and a
# value that came out of a regex capture keeps its string flag when it is only
# used as a number. Adding zero yields a pure number, so the contract (numbers
# for sizes and ANSI16 indices) holds with every encoder and version.
sub _color {
  my ($color) = @_;
  return ref $color ? $color : 0 + $color;
}

sub emit {
  my ($self) = @_;
  my $grid = $self->grid;

  my @rows;
  for my $y (1 .. $grid->height) {
    my @row;
    for my $x (1 .. $grid->width) {
      my $cell = $grid->get($x, $y);
      my %c = (
        glyph => $cell->glyph,
        fg    => _color($cell->fg),
        bg    => _color($cell->bg),
      );
      $c{bold}      = 1 if $cell->bold;
      $c{dim}       = 1 if $cell->dim;
      $c{italic}    = 1 if $cell->italic;
      $c{underline} = 1 if $cell->underline;
      $c{blink}     = 1 if $cell->blink;
      $c{inverse}   = 1 if $cell->inverse;
      push @row, \%c;
    }
    push @rows, \@row;
  }

  return encode_json({
    width  => 0 + $grid->width,
    height => 0 + $grid->height,
    cells  => \@rows,
  });
}

1;
