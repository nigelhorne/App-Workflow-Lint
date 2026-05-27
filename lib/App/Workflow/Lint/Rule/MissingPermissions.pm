package App::Workflow::Lint::Rule::MissingPermissions;

use strict;
use warnings;
use parent 'App::Workflow::Lint::Rule';

sub id          { 'missing-permissions' }
sub description { 'Workflow should define a top-level permissions block' }

sub check_workflow {
    my ($self, $wf, $ctx) = @_;

    return () if exists $wf->{permissions};

    return $self->diag(
        message => 'Workflow is missing a top-level permissions block',
        path    => '/',
        file    => $ctx->{file},
    );
}

1;

