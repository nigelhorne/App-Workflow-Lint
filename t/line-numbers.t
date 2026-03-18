#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

use File::Temp qw(tempfile);

use_ok('App::Workflow::Lint::YAML');
use_ok('App::Workflow::Lint::Rule::MissingTimeout');
use_ok('App::Workflow::Lint::Engine');

#----------------------------------------------------------------------
# Create a temporary workflow file with known line numbers
#----------------------------------------------------------------------

my ($fh, $filename) = tempfile();

print $fh <<'YAML';
name: Test Workflow

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Step One
        run: echo "hello"
YAML

close $fh;

# Line numbers (1-based):
#  1: name: Test Workflow
#  2:
#  3: jobs:
#  4:   build:
#  5:     runs-on: ubuntu-latest
#  6:     steps:
#  7:       - name: Step One
#  8:         run: echo "hello"

#----------------------------------------------------------------------
# Load workflow with position tracking
#----------------------------------------------------------------------

my ($wf, $pos) = App::Workflow::Lint::YAML->load_with_positions($filename);

ok($wf, 'workflow loaded');
ok($pos, 'position map returned');

#----------------------------------------------------------------------
# Verify line numbers for key paths
#----------------------------------------------------------------------

is $pos->{'/name'}, 1, 'top-level name is on line 1';
is $pos->{'/jobs'}, 3, 'jobs key is on line 3';
is $pos->{'/jobs/build'}, 4, 'build job is on line 4';
is $pos->{'/jobs/build/runs-on'}, 5, 'runs-on is on line 5';
is $pos->{'/jobs/build/steps/0/name'}, 7, 'first step name is on line 7';
is $pos->{'/jobs/build/steps/0/run'}, 8, 'first step run is on line 8';

#----------------------------------------------------------------------
# Verify that a rule diagnostic includes the correct line number
#----------------------------------------------------------------------

my $rule   = new_ok('App::Workflow::Lint::Rule::MissingTimeout');
my $engine = new_ok('App::Workflow::Lint::Engine');

# Inject the position map into the engine (normally done by load_workflow)
$engine->{_positions}{$filename} = $pos;

# Run rule directly
my @diags = $rule->check($wf, { file => $filename, engine => $engine });

# MissingTimeout should fire because build has no timeout-minutes
is scalar(@diags), 1, 'one diagnostic returned';

my $d = $diags[0];

ok($d->{line}, 'diagnostic has a line number');
is $d->{line}, 4, 'diagnostic line number matches job definition line';

done_testing;

