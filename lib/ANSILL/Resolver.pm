package ANSILL::Resolver;
# ABSTRACT: Resolve styles, palettes, symbols, macros in ANSILL AST

our $VERSION = '0.001';

use Moo;
use Types::Standard qw( HashRef InstanceOf );
use ANSILL::Color;
use Carp qw( croak );

has palette => (
  is => 'ro',
  isa => HashRef,
  default => sub { {} },
);

has styles => (
  is => 'ro',
  isa => HashRef,
  default => sub { {} },
);

has symbols => (
  is => 'ro',
  isa => HashRef,
  default => sub { {} },
);

has macros => (
  is => 'ro',
  isa => HashRef,
  default => sub { {} },
);

has variables => (
  is => 'ro',
  isa => HashRef,
  default => sub { {} },
);

has layers => (
  is => 'ro',
  isa => HashRef,
  default => sub { {} },
);

has meta => (
  is => 'ro',
  isa => HashRef,
  default => sub { {} },
);

has canvas_width  => (is => 'rw', default => 80);
has canvas_height => (is => 'rw', default => 25);
has canvas_wrap   => (is => 'rw', default => 'clip');
has profile_name  => (is => 'rw', default => 'cp437');
has color_system  => (is => 'rw', default => 'ansi16');
has policy_level  => (is => 'rw', default => 'warn-fallback');

sub resolve {
  my ($self, $ast) = @_;

  my @draw_commands;

  for my $node (@{$ast->nodes}) {
    my $type = ref $node;

    if ($type eq 'ANSILL::AST::Canvas') {
      $self->canvas_width($node->width);
      $self->canvas_height($node->height);
      $self->canvas_wrap($node->wrap);
    }
    elsif ($type eq 'ANSILL::AST::Profile') {
      $self->profile_name($node->name);
    }
    elsif ($type eq 'ANSILL::AST::Colors') {
      $self->color_system($node->system);
    }
    elsif ($type eq 'ANSILL::AST::Policy') {
      $self->policy_level($node->level);
    }
    elsif ($type eq 'ANSILL::AST::Palette') {
      # Merge palette entries into the main palette
      my $entries = $node->entries;
      for my $key (keys %$entries) {
        $self->palette->{$key} = $entries->{$key};
      }
    }
    elsif ($type eq 'ANSILL::AST::Style') {
      $self->styles->{$node->name} = $node->props;
    }
    elsif ($type eq 'ANSILL::AST::Symbol') {
      $self->symbols->{$node->name} = $node;
    }
    elsif ($type eq 'ANSILL::AST::Macro') {
      $self->macros->{$node->name} = $node;
    }
    elsif ($type eq 'ANSILL::AST::Layer') {
      my $order = scalar keys %{$self->layers};
      $self->layers->{$node->name} = $order;
    }
    elsif ($type eq 'ANSILL::AST::Let') {
      $self->variables->{$node->name} = $self->_eval_expr($node->value);
    }
    elsif ($type eq 'ANSILL::AST::Meta') {
      $self->meta->{$node->key} = $node->value;
    }
    elsif ($type eq 'ANSILL::AST::Version') {
      # Validated but not stored further
    }
    elsif ($type eq 'ANSILL::AST::Import') {
      # TODO: import resolution
    }
    else {
      # Drawing command - resolve style and palette references
      push @draw_commands, $self->_resolve_command($node);
    }
  }

  return \@draw_commands;
}

sub _resolve_command {
  my ($self, $node) = @_;

  my $type = ref $node;

  if ($node->can('attrs')) {
    my $attrs = { %{$node->attrs} };

    # For box/line/panel, 'style' means line-set, not a style reference
    my %line_set_cmds = map { $_ => 1 } qw(
      ANSILL::AST::Box ANSILL::AST::Line ANSILL::AST::Panel
    );

    # Apply style if referenced (but not for commands where style=line-set)
    if (my $style_name = delete $attrs->{style}) {
      if ($line_set_cmds{$type}) {
        # Preserve as line_set for the renderer
        $attrs->{style} = $style_name;
      } elsif (my $style = $self->styles->{$style_name}) {
        # Style provides defaults, explicit attrs override
        for my $key (keys %$style) {
          $attrs->{$key} //= $style->{$key};
        }
      } else {
        croak "Unknown style: '$style_name'";
      }
    }

    # Resolve palette color references
    for my $color_key (qw(fg bg)) {
      if (defined $attrs->{$color_key}) {
        $attrs->{$color_key} = ANSILL::Color->parse_color(
          $attrs->{$color_key}, $self->palette
        );
      }
    }

    # Return a copy of the node with resolved attrs
    my $class = ref $node;
    my %args;
    for my $method (qw(x y x1 y1 x2 y2 text symbol)) {
      if ($node->can($method)) {
        my $val = $node->$method;
        # Resolve variable references in coordinates
        if (defined $val && !ref $val && $val =~ /\$/) {
          $val = $self->_eval_expr($val);
        }
        $args{$method} = $val;
      }
    }
    $args{attrs} = $attrs;

    return $class->new(%args);
  }

  return $node;
}

sub _eval_expr {
  my ($self, $expr) = @_;

  # Replace variable references
  $expr =~ s/\$(\w+)/$self->variables->{$1} \/\/ croak "Undefined variable: '\$$1'"/ge;

  # Simple arithmetic evaluation (safe: only digits and operators)
  if ($expr =~ /^[\d\s+\-*\/()]+$/) {
    my $result = eval $expr;
    croak "Expression error: $@" if $@;
    return int($result);
  }

  return $expr;
}

1;
