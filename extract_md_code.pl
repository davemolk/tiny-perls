#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use autodie;
use Getopt::Long;
use File::Basename;

sub usage {
    my ($exit) = @_;
    my $prog = basename($0);

    say "usage: $prog [options]\n";
    say << "USAGE";
extract code from markdown. reads stdin or a file

options:
    -l, --language  only extract blocks from this language
    -v, --verbose   include language on output (default is just code blocks)
    -h, --help      show this help
USAGE
    exit $exit;
}

my ($help, $extract_lang, $verbose);
GetOptions(
    "help|h" => \$help,
    "verbose|v" => \$verbose,
    "language|l=s" => \$extract_lang,
);

usage(0) if $help;

my $in_block;
my $language;
my @code_block;
while (my $line = <>) {
    chomp $line;
    if ($line =~ /^```(\w*)\s*$/) {
        if (!$in_block) {
            $in_block = 1;
            $language = $1;
            @code_block = ();
        } else {
            $in_block = 0;
            say "language: $language" if $language && $verbose;
            say join("\n", @code_block) if scalar @code_block;
            say "" if scalar @code_block;
            $language = '';
        }
    } elsif ($in_block) {
        next if $extract_lang && $extract_lang ne $language;
        push @code_block, $line;
    }
}
