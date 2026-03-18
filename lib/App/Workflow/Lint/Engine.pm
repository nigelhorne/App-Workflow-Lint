package App::Workflow::Lint::Engine;

use strict;
use warnings;
use Carp qw(croak carp);

use YAML::XS qw(LoadFile DumpFile);
use App::Workflow::Lint::Rule::MissingPermissions;
use App::Workflow::Lint::Rule::MissingTimeout;
use App::Workflow::Lint::Rule::UnpinnedActions;
use App::Workflow::Lint::Rule::MissingConcurrency;
use App::Workflow::Lint::Rule::DeprecatedSetEnv;
use App::Workflow::Lint::Rule::MissingRunsOn;

#----------------------------------------------------------------------

sub new {
    my ($class, %opts) = @_;
    return bless { %opts }, $class;
}

#----------------------------------------------------------------------

sub load_workflow {
    my ($self, $file) = @_;
    croak "No workflow file provided" unless defined $file;

	my $wf = LoadFile($file);
    croak "Failed to load workflow '$file': $@" if $@;

    return $wf;
}

#----------------------------------------------------------------------

sub save_workflow {
	my ($self, $file, $wf) = @_;

	DumpFile($file, $wf);

	return 1;
}

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

#----------------------------------------------------------------------
# apply_fixes($workflow, @diagnostics)
#
# Applies all fix coderefs returned by rules.
#----------------------------------------------------------------------

sub apply_fixes {
    my ($self, $wf, @diags) = @_;

    for my $d (@diags) {
        next unless $d->{fix};
        $d->{fix}->($wf);   # Execute the fix
    }

    return $wf;
}

#----------------------------------------------------------------------
# fix_file($file)
#
# Loads workflow, runs rules, applies fixes, returns modified workflow.
#----------------------------------------------------------------------

sub fix_file {
	my ($self, $file) = @_;

	my $wf = $self->load_workflow($file);
	my @diags = $self->check_file($file);

	$self->apply_fixes($wf, @diags);

	return ($wf, \@diags);
}

1;
