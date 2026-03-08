package ANSILL::Color;
# ABSTRACT: Color parsing, naming, and degradation for ANSILL

use Moo;
use Types::Standard qw( Str Int HashRef );
use Carp qw( croak );

my %ANSI16_NAMES = (
  'black'          => 0,
  'red'            => 1,
  'green'          => 2,
  'yellow'         => 3,
  'blue'           => 4,
  'magenta'        => 5,
  'cyan'           => 6,
  'white'          => 7,
  'bright-black'   => 8,
  'bright-red'     => 9,
  'bright-green'   => 10,
  'bright-yellow'  => 11,
  'bright-blue'    => 12,
  'bright-magenta' => 13,
  'bright-cyan'    => 14,
  'bright-white'   => 15,
);

my %ANSI16_INDEX_TO_NAME = reverse %ANSI16_NAMES;

sub parse_color {
  my ($class, $value, $palette) = @_;

  return undef unless defined $value;

  # Numeric index
  return 0 + $value if $value =~ /^\d+$/;

  # Hex RGB
  if ($value =~ /^#([0-9a-fA-F]{6})$/) {
    my ($r, $g, $b) = map { hex($_) } unpack("A2A2A2", $1);
    return { r => $r, g => $g, b => $b };
  }

  # Named ANSI16 color
  if (exists $ANSI16_NAMES{$value}) {
    return $ANSI16_NAMES{$value};
  }

  # Palette reference
  if ($palette && exists $palette->{$value}) {
    return $class->parse_color($palette->{$value}, undef);
  }

  croak "Unknown color: '$value'";
}

sub color_name {
  my ($class, $index) = @_;
  return $ANSI16_INDEX_TO_NAME{$index} // $index;
}

sub degrade_to_ansi16 {
  my ($class, $color) = @_;

  return $color unless ref $color;

  # RGB to nearest ANSI16
  my ($r, $g, $b) = @{$color}{qw(r g b)};

  my @ansi16_rgb = (
    [0,0,0],       [170,0,0],     [0,170,0],     [170,85,0],
    [0,0,170],     [170,0,170],   [0,170,170],   [170,170,170],
    [85,85,85],    [255,85,85],   [85,255,85],   [255,255,85],
    [85,85,255],   [255,85,255],  [85,255,255],  [255,255,255],
  );

  my $best = 0;
  my $best_dist = _color_dist($r, $g, $b, @{$ansi16_rgb[0]});

  for my $i (1..15) {
    my $dist = _color_dist($r, $g, $b, @{$ansi16_rgb[$i]});
    if ($dist < $best_dist) {
      $best = $i;
      $best_dist = $dist;
    }
  }

  return $best;
}

sub _color_dist {
  my ($r1, $g1, $b1, $r2, $g2, $b2) = @_;
  return ($r1-$r2)**2 + ($g1-$g2)**2 + ($b1-$b2)**2;
}

sub ansi16_names { return { %ANSI16_NAMES } }

1;
