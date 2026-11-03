package ANSILL::Backend::ANSI;
# ABSTRACT: ANSI escape sequence backend for ANSILL

our $VERSION = '0.001';

use Moo;
use Types::Standard qw( InstanceOf Str Bool );

has grid => (
  is => 'ro',
  isa => InstanceOf['ANSILL::Grid'],
  required => 1,
);

has sgr_mode => (
  is => 'ro',
  isa => Str,
  default => '16color',
);

has optimize => (
  is => 'ro',
  isa => Str,
  default => 'sgr',
);

has sauce => (
  is => 'ro',
  isa => Bool,
  default => 0,
);

has meta => (
  is => 'ro',
  default => sub { {} },
);

sub emit {
  my ($self) = @_;
  my $grid = $self->grid;
  my $output = '';

  my ($prev_fg, $prev_bg, $prev_bold) = (-1, -1, -1);

  for my $y (1 .. $grid->height) {
    for my $x (1 .. $grid->width) {
      my $cell = $grid->get($x, $y);

      my $fg = $cell->fg // 7;
      my $bg = $cell->bg // 0;
      my $bold = $cell->bold ? 1 : 0;

      if ($self->optimize eq 'sgr') {
        # Only emit SGR when attributes change
        if ($fg != $prev_fg || $bg != $prev_bg || $bold != $prev_bold) {
          $output .= $self->_sgr($fg, $bg, $bold);
          $prev_fg = $fg;
          $prev_bg = $bg;
          $prev_bold = $bold;
        }
      } else {
        $output .= $self->_sgr($fg, $bg, $bold);
      }

      $output .= $cell->glyph;
    }

    # Reset at end of line and add newline
    $output .= "\e[0m\n";
    ($prev_fg, $prev_bg, $prev_bold) = (-1, -1, -1);
  }

  # Reset terminal
  $output .= "\e[0m";

  # SAUCE record
  if ($self->sauce) {
    $output .= $self->_sauce_record;
  }

  return $output;
}

sub _sgr {
  my ($self, $fg, $bg, $bold) = @_;

  my @codes;
  push @codes, 0; # reset

  push @codes, 1 if $bold;

  # Foreground
  if ($fg < 8) {
    push @codes, 30 + $fg;
  } elsif ($fg < 16) {
    push @codes, 90 + ($fg - 8);
  }

  # Background
  if ($bg < 8) {
    push @codes, 40 + $bg;
  } elsif ($bg < 16) {
    push @codes, 100 + ($bg - 8);
  }

  return "\e[" . join(';', @codes) . "m";
}

sub _sauce_record {
  my ($self) = @_;
  my $meta = $self->meta;

  my $sauce = "\x1a";  # EOF marker
  $sauce .= "SAUCE";
  $sauce .= "00";      # version
  $sauce .= _sauce_pad($meta->{title} // '', 35);
  $sauce .= _sauce_pad($meta->{author} // '', 20);
  $sauce .= _sauce_pad($meta->{group} // '', 20);
  $sauce .= _sauce_pad($meta->{date} // '20260305', 8);
  # Remaining SAUCE fields as zeros
  $sauce .= "\0" x 24;
  # DataType=1 (Character), FileType=1 (ANSi)
  $sauce .= pack("CC", 1, 1);
  # TInfo1=width, TInfo2=height
  $sauce .= pack("vv", $self->grid->width, $self->grid->height);
  $sauce .= "\0" x 4;  # TInfo3, TInfo4
  $sauce .= "\0";       # Comments
  $sauce .= "\0";       # TFlags
  $sauce .= _sauce_pad('', 22); # TInfoS

  return $sauce;
}

sub _sauce_pad {
  my ($str, $len) = @_;
  $str = substr($str, 0, $len) if length($str) > $len;
  return $str . ("\0" x ($len - length($str)));
}

1;
