package ANSILL::Profile;
# ABSTRACT: Base profile for abstract glyph mapping in ANSILL

our $VERSION = '0.001';

use Moo;
use Types::Standard qw( Str HashRef );
use Carp qw( croak );
use Module::Runtime qw( use_module );

has name => (
  is => 'ro',
  isa => Str,
  required => 1,
);

has _glyph_map => (
  is => 'lazy',
  isa => HashRef,
  builder => '_build_glyph_map',
);

has _allowed => (
  is => 'ro',
  isa => HashRef,
  default => sub { {} },
);

has _denied => (
  is => 'ro',
  isa => HashRef,
  default => sub { {} },
);

sub _build_glyph_map { {} }

sub resolve_glyph {
  my ($self, $glyph) = @_;
  return $self->_glyph_map->{$glyph} // $glyph;
}

sub is_abstract_glyph {
  my ($self, $name) = @_;
  return exists $self->_glyph_map->{$name};
}

sub glyph_allowed {
  my ($self, $glyph) = @_;
  return 0 if exists $self->_denied->{$glyph};
  return 1 if exists $self->_allowed->{$glyph};
  return $self->_check_glyph($glyph);
}

sub _check_glyph { 1 }

sub load {
  my ($class, $name) = @_;

  my %builtin = (
    ascii   => 'ANSILL::Profile::ASCII',
    cp437   => 'ANSILL::Profile::CP437',
    unicode => 'ANSILL::Profile::Unicode',
  );

  my $pkg = $builtin{$name}
    or croak "Unknown profile: '$name'";

  return use_module($pkg)->new(name => $name);
}

# Line set mappings: style => { abstract_name => abstract_glyph_key }
my %LINE_SETS = (
  ascii => {
    h => 'line-h', v => 'line-v',
    tl => 'corner-tl', tr => 'corner-tr',
    bl => 'corner-bl', br => 'corner-br',
  },
  single => {
    h => 'line-h', v => 'line-v',
    tl => 'corner-tl', tr => 'corner-tr',
    bl => 'corner-bl', br => 'corner-br',
  },
  double => {
    h => 'd-line-h', v => 'd-line-v',
    tl => 'd-corner-tl', tr => 'd-corner-tr',
    bl => 'd-corner-bl', br => 'd-corner-br',
  },
);

sub line_set_glyphs {
  my ($self, $set_name) = @_;
  $set_name //= 'single';
  my $set = $LINE_SETS{$set_name}
    or croak "Unknown line set: '$set_name'";

  my %resolved;
  for my $key (keys %$set) {
    $resolved{$key} = $self->resolve_glyph($set->{$key});
  }
  return \%resolved;
}

1;
