#!/usr/bin/perl

# https://github.com/tomnomnom/anew

use strict;
use warnings;
use feature 'say';
use Getopt::Long;

sub usage {
    my ($exit) = @_;

    say << "USAGE";
usage: $0 [file]

appends lines from stdin to a file if they aren't already
there and also sends the lines to stdout.

options:
        -d, --dry        send to stdout, don't append
        -q, --quiet      append to file, don't send to stdout
        -t, --trim       trim whitespace of input before comparing
        -h, --help       show this help msg

port of https://github.com/tomnomnom/anew
USAGE
    exit $exit;
}

my ($dry, $quiet, $trim, $help);

GetOptions(
    "dry|d" => \$dry,
    "quiet|q" => \$quiet,
    "trim|t" => \$trim,
    "help|h" => \$help
) or die "parsing opts: $1";

usage(0) if $help;
usage(2) if !@ARGV;

my $file = shift;
my %hash;

open(my $fh, '<', $file) or die "open to read: $!";
while (my $line = <$fh>) {
    chomp $line;
    $line =~ s/^\s+|\s+$//g if $trim;
    $hash{$line} = 1;
}
close $fh or die "close after read: $1";

open ($fh, '>>', $file) or die "open to write: $1";
while (my $line = <STDIN>) {
    chomp $line;
    $line =~ s/^\s+|\s+$//g if $trim;
    next if exists ($hash{$line});
    $hash{$line} = 1; 
    say $fh $line unless $dry;
    say $line unless $quiet;
}
close $fh or die "close after write: $1";