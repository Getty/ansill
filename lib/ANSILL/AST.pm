package ANSILL::AST;
# ABSTRACT: AST node types for ANSILL documents

our $VERSION = '0.001';

use Moo;
use Types::Standard qw( Str Int ArrayRef HashRef Maybe );

has nodes => (
  is => 'ro',
  isa => ArrayRef,
  default => sub { [] },
);

sub add_node {
  my ($self, $node) = @_;
  push @{$self->nodes}, $node;
}

# --- Node classes ---

package ANSILL::AST::Version;
use Moo;
has version => (is => 'ro', required => 1);

package ANSILL::AST::Canvas;
use Moo;
has width  => (is => 'ro', required => 1);
has height => (is => 'ro', required => 1);
has wrap   => (is => 'ro', default => 'clip');

package ANSILL::AST::Profile;
use Moo;
has name => (is => 'ro', required => 1);

package ANSILL::AST::Colors;
use Moo;
has system => (is => 'ro', required => 1);

package ANSILL::AST::Policy;
use Moo;
has level => (is => 'ro', required => 1);

package ANSILL::AST::Palette;
use Moo;
use Types::Standard qw( Str HashRef );
has name    => (is => 'ro', isa => Str, required => 1);
has entries => (is => 'ro', isa => HashRef, required => 1);

package ANSILL::AST::Style;
use Moo;
use Types::Standard qw( Str HashRef );
has name  => (is => 'ro', isa => Str, required => 1);
has props => (is => 'ro', isa => HashRef, required => 1);

package ANSILL::AST::Layer;
use Moo;
use Types::Standard qw( Str );
has name => (is => 'ro', isa => Str, required => 1);

package ANSILL::AST::Symbol;
use Moo;
use Types::Standard qw( Str Int ArrayRef HashRef Maybe );
has name     => (is => 'ro', isa => Str, required => 1);
has width    => (is => 'ro', isa => Int, required => 1);
has height   => (is => 'ro', isa => Int, required => 1);
has commands => (is => 'ro', isa => ArrayRef, default => sub { [] });
has variants => (is => 'ro', isa => HashRef, default => sub { {} });

package ANSILL::AST::Macro;
use Moo;
use Types::Standard qw( Str ArrayRef );
has name   => (is => 'ro', isa => Str, required => 1);
has params => (is => 'ro', isa => ArrayRef, required => 1);
has body   => (is => 'ro', isa => ArrayRef, required => 1);

package ANSILL::AST::Let;
use Moo;
use Types::Standard qw( Str );
has name  => (is => 'ro', isa => Str, required => 1);
has value => (is => 'ro', required => 1);

package ANSILL::AST::Meta;
use Moo;
use Types::Standard qw( Str );
has key   => (is => 'ro', isa => Str, required => 1);
has value => (is => 'ro', isa => Str, required => 1);

package ANSILL::AST::Import;
use Moo;
use Types::Standard qw( Str Maybe );
has file      => (is => 'ro', isa => Str, required => 1);
has namespace => (is => 'ro', isa => Maybe[Str], default => undef);

# --- Drawing command nodes ---

package ANSILL::AST::Put;
use Moo;
use Types::Standard qw( HashRef );
has x     => (is => 'ro', required => 1);
has y     => (is => 'ro', required => 1);
has attrs => (is => 'ro', isa => HashRef, default => sub { {} });

package ANSILL::AST::Text;
use Moo;
use Types::Standard qw( Str HashRef );
has x     => (is => 'ro', required => 1);
has y     => (is => 'ro', required => 1);
has text  => (is => 'ro', isa => Str, required => 1);
has attrs => (is => 'ro', isa => HashRef, default => sub { {} });

package ANSILL::AST::Fill;
use Moo;
use Types::Standard qw( HashRef );
has x1    => (is => 'ro', required => 1);
has y1    => (is => 'ro', required => 1);
has x2    => (is => 'ro', required => 1);
has y2    => (is => 'ro', required => 1);
has attrs => (is => 'ro', isa => HashRef, default => sub { {} });

package ANSILL::AST::Line;
use Moo;
use Types::Standard qw( HashRef );
has x1    => (is => 'ro', required => 1);
has y1    => (is => 'ro', required => 1);
has x2    => (is => 'ro', required => 1);
has y2    => (is => 'ro', required => 1);
has attrs => (is => 'ro', isa => HashRef, default => sub { {} });

package ANSILL::AST::Box;
use Moo;
use Types::Standard qw( HashRef );
has x1    => (is => 'ro', required => 1);
has y1    => (is => 'ro', required => 1);
has x2    => (is => 'ro', required => 1);
has y2    => (is => 'ro', required => 1);
has attrs => (is => 'ro', isa => HashRef, default => sub { {} });

package ANSILL::AST::Panel;
use Moo;
use Types::Standard qw( HashRef );
has x1    => (is => 'ro', required => 1);
has y1    => (is => 'ro', required => 1);
has x2    => (is => 'ro', required => 1);
has y2    => (is => 'ro', required => 1);
has attrs => (is => 'ro', isa => HashRef, default => sub { {} });

package ANSILL::AST::Repeat;
use Moo;
use Types::Standard qw( HashRef );
has x1    => (is => 'ro', required => 1);
has y1    => (is => 'ro', required => 1);
has x2    => (is => 'ro', required => 1);
has y2    => (is => 'ro', required => 1);
has attrs => (is => 'ro', isa => HashRef, default => sub { {} });

package ANSILL::AST::Blit;
use Moo;
use Types::Standard qw( Str HashRef );
has symbol => (is => 'ro', isa => Str, required => 1);
has x      => (is => 'ro', required => 1);
has y      => (is => 'ro', required => 1);
has attrs  => (is => 'ro', isa => HashRef, default => sub { {} });

package ANSILL::AST::Clear;
use Moo;
has x1 => (is => 'ro', required => 1);
has y1 => (is => 'ro', required => 1);
has x2 => (is => 'ro', required => 1);
has y2 => (is => 'ro', required => 1);

1;
