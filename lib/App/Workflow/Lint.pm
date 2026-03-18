package App::Workflow::Lint;

use strict;
use warnings;
use Carp qw(croak carp);

# VERSION MUST be simple for MakeMaker to parse
our $VERSION = '0.01';

=head1 NAME

App::Workflow::Lint - Lint and analyze GitHub Actions workflows

=head1 DESCRIPTION

This module provides the programmatic API for linting GitHub Actions
workflows. The CLI wrapper is installed as C<workflow-lint>.

=cut

use App::Workflow::Lint::Engine;

#----------------------------------------------------------------------
# Constructor
#----------------------------------------------------------------------
sub new {
    my ($class, %opts) = @_;
    return bless { %opts }, $class;
}

#----------------------------------------------------------------------
# check_file($path)
#
# Convenience wrapper around the engine. Loads the workflow file,
# runs all rules, and returns a list of diagnostics.
#----------------------------------------------------------------------
sub check_file {
    my ($self, $file) = @_;
    croak "check_file() requires a filename" unless defined $file;

    my $engine = App::Workflow::Lint::Engine->new(%$self);
    return $engine->check_file($file);
}

1;

