#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use feature 'say';
use Getopt::Long;

sub usage {
    my ($exit) = @_;

    say << "USAGE";
usage: $0 <files..>

search through file to find todos

options:
    -c, --comment      comment separator (default '//')
    -a, --add-word     additional word to search for (fixme, for instance)
    -q, --quiet        suppress file name in output

USAGE
    exit $exit;
}

my ($c, $w, $q);
GetOptions(
    "comment|c=s" => \$c,
    "word|w=s" => \$w,
    "quiet|q" => \$q,
);

@ARGV or usage(1);
my @files = @ARGV;

my $sep = defined $c ? $c : "//";
my $target = defined $w? "todo|$w" : "todo";
$target = "($target)";
my $quoted_sep = quotemeta($sep);

for my $file (@files) {
    open(my $fh, '<', $file);
    say "file: $file" unless $q;
    my $reading_comment;
    while (my $line = <$fh>) {
        if ($line =~ /^\s*$quoted_sep\s*$target\s+(.*)/i) {
            $reading_comment = 1;
            say "$.: $2"; 
        } elsif ($line =~ /^\s*$quoted_sep\s+(.*)/i) {
            say "$.: $1" if $reading_comment;
        } else {
            $reading_comment = 0;
        }
    }
    close $fh;
    say "";
}