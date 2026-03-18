package App::Workflow::Lint::YAML;

use strict;
use warnings;
use Carp qw(croak carp);

use YAML::PP;
use YAML::PP::Parser;

#----------------------------------------------------------------------
# load_with_positions($file)
#----------------------------------------------------------------------

sub load_with_positions {
    my ($class, $file) = @_;

    open my $fh, '<', $file or croak "Cannot open '$file': $!";
    local $/;
    my $yaml = <$fh>;
    close $fh;

    my @events;

    my $receiver = bless {
        events => \@events,
    }, 'App::Workflow::Lint::YAML::Receiver';

    my $parser = YAML::PP::Parser->new( receiver => $receiver );
    $parser->parse_string($yaml);

    my $root;
    my %pos;

    # Stack entries: [ \$container, $path, $current_key ]
    my @stack = ( [ \$root, '', undef ] );

    for my $e (@events) {
        my $type = $e->{type};

        #--------------------------------------------------------------
        # SCALAR (only event with start_mark)
        #--------------------------------------------------------------
        if ($type eq 'scalar') {
            my $value = $e->{value};
            my $line  = $e->{start_mark}{line} + 1;

            my ($cref, $path, $key) = @{ $stack[-1] };

            if (ref $$cref eq 'ARRAY') {
                my $idx = @{ $$cref };
                push @{ $$cref }, $value;
                $pos{"$path/$idx"} = $line;
            }
            elsif (ref $$cref eq 'HASH') {
                if (!defined $key) {
                    # This scalar is a key
                    $stack[-1][2] = $value;
                    $pos{"$path/$value"} = $line;
                }
                else {
                    # This scalar is a value
                    $$cref->{$key} = $value;
                    $pos{"$path/$key"} = $line;
                    $stack[-1][2] = undef;
                }
            }
            else {
                $$cref = $value;
                $pos{"/"} = $line;
            }
        }

        #--------------------------------------------------------------
        # MAPPING START
        #--------------------------------------------------------------
        elsif ($type eq 'mapping_start') {
            my ($cref, $path, $key) = @{ $stack[-1] };
            my $new = {};

            if (ref $$cref eq 'ARRAY') {
                my $idx = @{ $$cref };
                push @{ $$cref }, $new;
                push @stack, [ \$new, "$path/$idx", undef ];
            }
            elsif (ref $$cref eq 'HASH') {
                $$cref->{$key} = $new;
                push @stack, [ \$new, "$path/$key", undef ];
                $stack[-2][2] = undef;
            }
            else {
                $$cref = $new;
                push @stack, [ \$new, $path, undef ];
            }
        }

        #--------------------------------------------------------------
        # SEQUENCE START
        #--------------------------------------------------------------
        elsif ($type eq 'sequence_start') {
            my ($cref, $path, $key) = @{ $stack[-1] };
            my $new = [];

            if (ref $$cref eq 'ARRAY') {
                my $idx = @{ $$cref };
                push @{ $$cref }, $new;
                push @stack, [ \$new, "$path/$idx", undef ];
            }
            elsif (ref $$cref eq 'HASH') {
                $$cref->{$key} = $new;
                push @stack, [ \$new, "$path/$key", undef ];
                $stack[-2][2] = undef;
            }
            else {
                $$cref = $new;
                push @stack, [ \$new, $path, undef ];
            }
        }

        #--------------------------------------------------------------
        # END EVENTS
        #--------------------------------------------------------------
        elsif ($type =~ /_end$/) {
            pop @stack;
        }
    }

    return ($root, \%pos);
}

#----------------------------------------------------------------------
# Event receiver — uses real YAML::PP event names
#----------------------------------------------------------------------

package App::Workflow::Lint::YAML::Receiver;

sub stream_start_event  { }
sub stream_end_event    { }
sub document_start_event { }
sub document_end_event   { }

sub mapping_start_event {
    my ($self, $e) = @_;
    $e->{type} = 'mapping_start';
    push @{ $self->{events} }, $e;
}

sub mapping_end_event {
    my ($self, $e) = @_;
    $e->{type} = 'mapping_end';
    push @{ $self->{events} }, $e;
}

sub sequence_start_event {
    my ($self, $e) = @_;
    $e->{type} = 'sequence_start';
    push @{ $self->{events} }, $e;
}

sub sequence_end_event {
    my ($self, $e) = @_;
    $e->{type} = 'sequence_end';
    push @{ $self->{events} }, $e;
}

sub scalar_event {
    my ($self, $e) = @_;
    $e->{type} = 'scalar';
    push @{ $self->{events} }, $e;
}

1;

