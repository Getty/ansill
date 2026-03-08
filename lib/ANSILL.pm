package ANSILL;
# ABSTRACT: ANSI Layout Language - declarative textmode art compiler

use Moo;
use Types::Standard qw( Str InstanceOf );
use ANSILL::Parser;
use ANSILL::Resolver;
use ANSILL::Renderer;
use ANSILL::Validator;
use ANSILL::Backend::PlainText;
use ANSILL::Backend::ANSI;
use ANSILL::Backend::JSON;
use ANSILL::Backend::HTML;
use Carp qw( croak );

our $VERSION = '0.001';

has source => (
  is => 'ro',
  isa => Str,
  required => 1,
);

has backend => (
  is => 'ro',
  isa => Str,
  default => 'ansi',
);

has _parser => (
  is => 'lazy',
  builder => sub { ANSILL::Parser->new(source => $_[0]->source) },
);

has _ast => (
  is => 'lazy',
  builder => sub { $_[0]->_parser->parse },
);

has _resolver => (
  is => 'lazy',
  builder => sub { ANSILL::Resolver->new },
);

has _commands => (
  is => 'lazy',
  builder => sub { $_[0]->_resolver->resolve($_[0]->_ast) },
);

has _renderer => (
  is => 'lazy',
  builder => sub {
    ANSILL::Renderer->new(resolver => $_[0]->_resolver);
  },
);

has _grid => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    # Ensure commands are resolved first (populates resolver)
    my $commands = $self->_commands;
    return $self->_renderer->render($commands);
  },
);

sub compile {
  my ($self) = @_;

  my $grid = $self->_grid;
  my $resolver = $self->_resolver;

  # Validate
  my $validator = ANSILL::Validator->new(
    profile => $self->_renderer->profile,
    policy  => $resolver->policy_level,
  );
  $validator->validate_ast($self->_ast);
  $validator->validate_grid($grid);

  # Emit
  my $backend_class = $self->_backend_class;
  my %backend_args = (grid => $grid);

  if ($self->backend eq 'ansi') {
    $backend_args{meta} = $resolver->meta;
  }
  if ($self->backend eq 'html') {
    $backend_args{title} = $resolver->meta->{title} // 'ANSILL Preview';
  }

  my $emitter = $backend_class->new(%backend_args);
  return $emitter->emit;
}

sub validate {
  my ($self) = @_;

  my $grid = $self->_grid;
  my $resolver = $self->_resolver;

  my $validator = ANSILL::Validator->new(
    profile => $self->_renderer->profile,
    policy  => $resolver->policy_level,
  );

  my @diags;
  $validator->validate_ast($self->_ast);
  push @diags, @{$validator->diagnostics};
  $validator->validate_grid($grid);
  push @diags, @{$validator->diagnostics};
  push @diags, @{$self->_parser->diagnostics};
  push @diags, @{$self->_renderer->diagnostics};

  return \@diags;
}

sub compile_file {
  my ($class, $file, %opts) = @_;
  open my $fh, '<:utf8', $file or croak "Cannot open '$file': $!";
  my $source = do { local $/; <$fh> };
  close $fh;
  return $class->new(source => $source, %opts)->compile;
}

sub _backend_class {
  my ($self) = @_;
  my %map = (
    ansi      => 'ANSILL::Backend::ANSI',
    plaintext => 'ANSILL::Backend::PlainText',
    json      => 'ANSILL::Backend::JSON',
    html      => 'ANSILL::Backend::HTML',
  );
  my $class = $map{$self->backend}
    or croak "Unknown backend: '" . $self->backend . "'";
  return $class;
}

1;
