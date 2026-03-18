package App::Workflow::Lint::Rule;

use strict;
use warnings;
use Carp qw(croak carp);

=head1 DESCRIPTION

Base class for all lint rules. Subclasses must implement:

  id()
  description()
  check($workflow, $context)

=cut

sub new {
    my ($class, %opts) = @_;
    return bless { %opts }, $class;
}

sub id          { croak "id() not implemented in " . ref($_[0]) }
sub description { croak "description() not implemented in " . ref($_[0]) }

sub check {
    croak "check() not implemented in " . ref($_[0]);
}

1;

