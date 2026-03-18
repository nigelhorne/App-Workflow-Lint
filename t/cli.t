use strict;
use warnings;
use Test::More;
use File::Temp qw/tempfile/;

my $CLI = 'bin/workflow-lint';

ok( -x $CLI, "CLI script exists and is executable" )
    or plan skip_all => "CLI script not found or not executable";

# Create a temporary workflow file
my ($fh, $filename) = tempfile();
print $fh <<'YAML';
name: Test Workflow
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Say hello
        run: echo Hello
YAML
close $fh;

# Run the CLI
my $cmd = "$CLI check $filename";
my $output = qx{$cmd 2>&1};
my $exit   = $? >> 8;

# EXPECT: non-zero exit because warnings were found
isnt($exit, 0, "CLI exits non-zero when workflow has issues");

# EXPECT: diagnostics appear
like($output, qr/missing-permissions/i, "Output includes missing-permissions warning");
like($output, qr/missing-timeout/i,     "Output includes missing-timeout warning");
like($output, qr/missing-concurrency/i, "Output includes missing-concurrency info");

done_testing;

