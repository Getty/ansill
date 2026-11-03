package ANSILL::Backend::PlainText;
# ABSTRACT: Plain text backend for ANSILL - glyph grid without escape sequences

our $VERSION = '0.001';

use Moo;
use Types::Standard qw( InstanceOf );

has grid => (
  is => 'ro',
  isa => InstanceOf['ANSILL::Grid'],
  required => 1,
);

sub emit {
  my ($self) = @_;
  return $self->grid->to_text;
}

1;
