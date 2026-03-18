package App::Workflow::Lint::YAML;

use strict;
use warnings;
use YAML::PP;

# ----------------------------------------------------------------------
# load_yaml
#
# Loads a GitHub Actions workflow YAML file/string and returns:
#   - $data : the parsed Perl structure
#   - {}    : an empty position map (line numbers removed)
#
# This keeps the API stable for callers that expect two return values,
# but no longer attempts to compute line numbers.
# ----------------------------------------------------------------------

sub load_yaml {
    my ($class, $yaml_text) = @_;

    my $ypp = YAML::PP->new;
    my $data = $ypp->load_string($yaml_text);

    # No line numbers available → return empty map
    my %positions;

    return ($data, \%positions);
}

1;
