use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'App::Workflow::Lint',
    VERSION_FROM => 'lib/App/Workflow/Lint.pm',
    ABSTRACT     => 'Lint GitHub Actions workflows',
    AUTHOR       => 'Nigel Horne',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'YAML::PP' => 0,
        'Carp'     => 0,
        'Test::Most' => 0,
    },
    EXE_FILES    => ['bin/workflow-lint'],
);

