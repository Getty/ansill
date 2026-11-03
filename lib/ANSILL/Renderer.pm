package ANSILL::Renderer;
# ABSTRACT: Render resolved ANSILL commands into a Grid

our $VERSION = '0.001';

use Moo;
use Types::Standard qw( InstanceOf );
use ANSILL::Grid;
use ANSILL::Profile;
use Carp qw( croak );

has grid => (
  is => 'lazy',
  isa => InstanceOf['ANSILL::Grid'],
);

has profile => (
  is => 'lazy',
  isa => InstanceOf['ANSILL::Profile'],
);

has resolver => (
  is => 'ro',
  isa => InstanceOf['ANSILL::Resolver'],
  required => 1,
);

has _diagnostics => (
  is => 'ro',
  default => sub { [] },
);

sub diagnostics { $_[0]->_diagnostics }

sub _build_grid {
  my ($self) = @_;
  return ANSILL::Grid->new(
    width  => $self->resolver->canvas_width,
    height => $self->resolver->canvas_height,
    wrap   => $self->resolver->canvas_wrap,
  );
}

sub _build_profile {
  my ($self) = @_;
  return ANSILL::Profile->load($self->resolver->profile_name);
}

sub render {
  my ($self, $commands) = @_;

  for my $cmd (@$commands) {
    my $type = ref $cmd;
    $type =~ s/.*:://;
    my $method = "_render_" . lc($type);

    if ($self->can($method)) {
      $self->$method($cmd);
    } else {
      $self->_diag(warning => "No renderer for command type: $type");
    }
  }

  return $self->grid;
}

sub _cell_attrs {
  my ($self, $attrs) = @_;
  my %cell;
  for my $key (qw(fg bg bold dim italic underline blink inverse protect layer tag)) {
    $cell{$key} = $attrs->{$key} if defined $attrs->{$key};
  }
  return %cell;
}

sub _resolve_glyph {
  my ($self, $glyph) = @_;
  return $self->profile->resolve_glyph($glyph);
}

sub _render_put {
  my ($self, $cmd) = @_;
  my %attrs = $self->_cell_attrs($cmd->attrs);
  if (my $g = $cmd->attrs->{glyph}) {
    $attrs{glyph} = $self->_resolve_glyph($g);
  }
  $self->grid->put($cmd->x, $cmd->y, %attrs);
}

sub _render_text {
  my ($self, $cmd) = @_;
  my %attrs = $self->_cell_attrs($cmd->attrs);

  my $text = $cmd->text;
  my $x = $cmd->x;
  my $y = $cmd->y;

  my $align = $cmd->attrs->{align} // 'left';
  if ($align eq 'center') {
    $x = $x - int(length($text) / 2);
    $x = 1 if $x < 1;
  } elsif ($align eq 'right') {
    $x = $x - length($text) + 1;
    $x = 1 if $x < 1;
  }

  my $transparent = $cmd->attrs->{transparent} // 0;
  $self->grid->put_text($x, $y, $text, %attrs, transparent => $transparent);
}

sub _render_fill {
  my ($self, $cmd) = @_;
  my %attrs = $self->_cell_attrs($cmd->attrs);
  if (my $g = $cmd->attrs->{glyph}) {
    $attrs{glyph} = $self->_resolve_glyph($g);
  }
  $self->grid->fill_rect($cmd->x1, $cmd->y1, $cmd->x2, $cmd->y2, %attrs);
}

sub _render_line {
  my ($self, $cmd) = @_;
  my %attrs = $self->_cell_attrs($cmd->attrs);
  my $line_set = $cmd->attrs->{style} // $cmd->attrs->{line_set} // 'single';
  my $glyphs = $self->profile->line_set_glyphs($line_set);

  if ($cmd->y1 == $cmd->y2) {
    # Horizontal line
    for my $x ($cmd->x1 .. $cmd->x2) {
      $self->grid->put($x, $cmd->y1, glyph => $glyphs->{h}, %attrs);
    }
  } elsif ($cmd->x1 == $cmd->x2) {
    # Vertical line
    for my $y ($cmd->y1 .. $cmd->y2) {
      $self->grid->put($cmd->x1, $y, glyph => $glyphs->{v}, %attrs);
    }
  } else {
    $self->_diag(error => "Diagonal lines not supported");
  }
}

sub _render_box {
  my ($self, $cmd) = @_;
  my %attrs = $self->_cell_attrs($cmd->attrs);
  my $line_set = $cmd->attrs->{style} // $cmd->attrs->{line_set} // 'single';
  my $glyphs = $self->profile->line_set_glyphs($line_set);

  my ($x1, $y1, $x2, $y2) = ($cmd->x1, $cmd->y1, $cmd->x2, $cmd->y2);

  # Fill interior if bg specified
  if (defined $cmd->attrs->{bg}) {
    $self->grid->fill_rect($x1+1, $y1+1, $x2-1, $y2-1,
      glyph => ' ', bg => $attrs{bg}, fg => $attrs{fg} // 7);
  }

  # Top and bottom borders
  for my $x ($x1+1 .. $x2-1) {
    $self->grid->put($x, $y1, glyph => $glyphs->{h}, %attrs);
    $self->grid->put($x, $y2, glyph => $glyphs->{h}, %attrs);
  }

  # Left and right borders
  for my $y ($y1+1 .. $y2-1) {
    $self->grid->put($x1, $y, glyph => $glyphs->{v}, %attrs);
    $self->grid->put($x2, $y, glyph => $glyphs->{v}, %attrs);
  }

  # Corners
  $self->grid->put($x1, $y1, glyph => $glyphs->{tl}, %attrs);
  $self->grid->put($x2, $y1, glyph => $glyphs->{tr}, %attrs);
  $self->grid->put($x1, $y2, glyph => $glyphs->{bl}, %attrs);
  $self->grid->put($x2, $y2, glyph => $glyphs->{br}, %attrs);
}

sub _render_panel {
  my ($self, $cmd) = @_;

  # Panel = box + optional title
  $self->_render_box($cmd);

  if (my $title = $cmd->attrs->{title}) {
    my %attrs = $self->_cell_attrs($cmd->attrs);
    my $align = $cmd->attrs->{title_align} // 'left';

    my $title_str = " $title ";
    my $x;

    if ($align eq 'center') {
      $x = $cmd->x1 + int(($cmd->x2 - $cmd->x1 - length($title_str)) / 2);
    } elsif ($align eq 'right') {
      $x = $cmd->x2 - length($title_str) - 1;
    } else {
      $x = $cmd->x1 + 2;
    }

    $self->grid->put_text($x, $cmd->y1, $title_str, %attrs);
  }
}

sub _render_repeat {
  my ($self, $cmd) = @_;
  my %attrs = $self->_cell_attrs($cmd->attrs);
  my $pattern = $cmd->attrs->{pattern} // '-';
  my @chars = split //, $pattern;

  my $i = 0;
  for my $y ($cmd->y1 .. $cmd->y2) {
    for my $x ($cmd->x1 .. $cmd->x2) {
      $self->grid->put($x, $y, glyph => $chars[$i % @chars], %attrs);
      $i++;
    }
  }
}

sub _render_clear {
  my ($self, $cmd) = @_;
  $self->grid->fill_rect($cmd->x1, $cmd->y1, $cmd->x2, $cmd->y2,
    glyph => ' ', fg => 7, bg => 0);
}

sub _render_blit {
  my ($self, $cmd) = @_;
  my $sym = $self->resolver->symbols->{$cmd->symbol}
    or do {
      $self->_diag(error => "Unknown symbol: '" . $cmd->symbol . "'");
      return;
    };

  # Render the symbol's commands offset to the blit position
  for my $subcmd (@{$sym->commands}) {
    # TODO: offset coordinates by blit position
    # For now, basic implementation
  }
}

sub _diag {
  my ($self, $level, $msg) = @_;
  push @{$self->_diagnostics}, { level => $level, message => $msg };
}

1;
