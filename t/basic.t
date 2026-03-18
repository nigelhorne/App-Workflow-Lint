use strict;
use warnings;
use Test::More;

use App::Workflow::Lint;

my $lint = App::Workflow::Lint->new;

ok($lint, 'constructor works');

done_testing;
