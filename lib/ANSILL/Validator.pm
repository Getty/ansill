package ANSILL::Validator;
# ABSTRACT: Validate ANSILL grid and AST against profile and policy

use Moo;
use Types::Standard qw( Str InstanceOf ArrayRef );
use Carp qw( croak );

has profile => (
  is => 'ro',
  isa => InstanceOf['ANSILL::Profile'],
  required => 1,
);

has policy => (
  is => 'ro',
  isa => Str,
  default => 'warn-fallback',
);

has _diagnostics => (
  is => 'ro',
  isa => ArrayRef,
  default => sub { [] },
);

sub diagnostics { $_[0]->_diagnostics }

sub has_errors {
  my ($self) = @_;
  return grep { $_->{level} eq 'error' } @{$self->_diagnostics};
}

sub validate_ast {
  my ($self, $ast) = @_;

  my $has_version = 0;
  my $has_canvas = 0;

  for my $node (@{$ast->nodes}) {
    my $type = ref $node;
    $has_version = 1 if $type eq 'ANSILL::AST::Version';
    $has_canvas = 1 if $type eq 'ANSILL::AST::Canvas';
  }

  $self->_diag(error => "Missing 'ansill' version declaration") unless $has_version;
  $self->_diag(error => "Missing 'canvas' declaration") unless $has_canvas;

  # Check that version is first non-meta node
  if ($has_version && ref $ast->nodes->[0] ne 'ANSILL::AST::Version') {
    $self->_diag(warning => "'ansill' version should be the first statement");
  }

  return !$self->has_errors;
}

sub validate_grid {
  my ($self, $grid) = @_;

  for my $y (1 .. $grid->height) {
    for my $x (1 .. $grid->width) {
      my $cell = $grid->get($x, $y);
      next unless $cell;

      my $glyph = $cell->glyph;
      next if $glyph eq ' ';

      unless ($self->profile->glyph_allowed($glyph)) {
        if ($self->policy eq 'strict') {
          $self->_diag(error =>
            "Glyph '$glyph' at ($x,$y) not allowed in profile '"
            . $self->profile->name . "'");
        } elsif ($self->policy eq 'warn-fallback') {
          $self->_diag(warning =>
            "Glyph '$glyph' at ($x,$y) not allowed in profile '"
            . $self->profile->name . "'; using fallback");
          # Apply fallback (replace with #)
          $cell->glyph('#');
        } else {
          # best-effort: silently replace
          $cell->glyph('#');
        }
      }
    }
  }

  return !$self->has_errors;
}

sub _diag {
  my ($self, $level, $msg) = @_;
  push @{$self->_diagnostics}, { level => $level, message => $msg };
}

1;
