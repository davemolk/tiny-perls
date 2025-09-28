#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use feature 'say';
use JSON;
use Getopt::Long;
use File::Basename;

my %commands = (
    two => \&two,
    map => \&map,
    help => \&help,
    h => \&help,
);

my $cmd = shift @ARGV;

unless (defined $cmd) {
    arr();
    exit 0;
}

if (exists $commands{$cmd}) {
    $commands{$cmd}->(
        @ARGV,
    )
} else {
    help();
}

sub help {
    say "turn stdin to json. defaults to array of lines.\n";
    say "use arg 'two' to split the fields of each line for a two-dimensional array";
    say "use arg 'map' plus keys to treat each entity on stdin as value for the given keys";
    say "e.g. echo 'jan 1 1970' | tojson map month day year";
    exit 0;
}    

sub arr {
    my @arr;
    while (my $line = <STDIN>) {
        chomp $line;
        push(@arr, $line);
    }
    my $json = JSON->new->pretty->encode(\@arr);
    say $json;
}

sub two {
    my @arr;
    while (my $line = <STDIN>) {
        chomp $line;
        my @a = split(' ', $line);
        push(@arr, \@a);
    }
    my $json = JSON->new->pretty->encode(\@arr);
    say $json;
}

sub map {
    my (@keys) = @_;

    my @arr;
    while (my $line = <STDIN>) {
        chomp $line;
        my @values = split(' ', $line);
        die "unequal keys/values" unless scalar @keys == scalar @values;
        my %hash;
        @hash{@keys} = @values;
        push(@arr, \%hash);
    }
    my $json = JSON->new->pretty->encode(\@arr);
    say $json;
}