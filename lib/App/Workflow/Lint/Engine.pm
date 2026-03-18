package App::Workflow::Lint::Engine;

use strict;
use warnings;
use Carp qw(croak carp);

use YAML::PP;
use App::Workflow::Lint::Rule::MissingPermissions;
use App::Workflow::Lint::Rule::MissingTimeout;
use App::Workflow::Lint::Rule::UnpinnedActions;
use App::Workflow::Lint::Rule::MissingConcurrency;
use App::Workflow::Lint::Rule::DeprecatedSetEnv;
use App::Workflow::Lint::Rule::MissingRunsOn;

=head1 DESCRIPTION

The Engine loads workflow YAML, normalizes it, runs all rules, and
returns diagnostics. It does not print anything; the CLI handles that.

=cut

#----------------------------------------------------------------------
sub new {
    my ($class, %opts) = @_;
    return bless { %opts }, $class;
}

#----------------------------------------------------------------------
# load_workflow($file)
#
# Loads YAML from disk. Croaks on missing file or YAML errors.
#----------------------------------------------------------------------
sub load_workflow {
    my ($self, $file) = @_;
    croak "No workflow file provided" unless defined $file;

    my $yp = YAML::PP->new;

    my $wf = eval { $yp->load_file($file) };
    croak "Failed to load workflow '$file': $@" if $@;

    return $wf;
}

#----------------------------------------------------------------------
# rules()
#
# Returns the list of rule objects to run. Later this will be dynamic.
#----------------------------------------------------------------------
sub rules {
    return (
        App::Workflow::Lint::Rule::MissingPermissions->new,
        App::Workflow::Lint::Rule::MissingTimeout->new,
        App::Workflow::Lint::Rule::UnpinnedActions->new,
        App::Workflow::Lint::Rule::MissingConcurrency->new,
        App::Workflow::Lint::Rule::DeprecatedSetEnv->new,
        App::Workflow::Lint::Rule::MissingRunsOn->new,
    );
}



#----------------------------------------------------------------------
# check_file($file)
#
# Loads the workflow and runs all rules. Returns a list of diagnostics.
#----------------------------------------------------------------------
sub check_file {
    my ($self, $file) = @_;

    my $wf = $self->load_workflow($file);
    my @results;

    for my $rule ($self->rules) {
        my @r = $rule->check($wf, { file => $file });
        push @results, @r if @r;
    }

    return @results;
}

1;

