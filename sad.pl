#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use feature 'say';
use Getopt::Long;
use File::Basename;
use File::Spec::Functions qw(catfile);

sub usage {
    my ($exit) = @_;
    my $prog = basename($0);

    printf <<'USAGE', $prog, $prog;
usage: %s [option] [dir]

%s -p "\.txt$" "." 

seek and destroy files

options:
        -p, --pattern REG  pattern used to delete files
        -d, --dry          dry run
        -i, --ignore REG   ignore files matching this pattern
        -q, --quiet        don't report what was deleted
        -h, --help         show this helpful help

USAGE
    exit $exit;
}

my ($dry, $ignore, $quiet, $help, $pattern);
GetOptions(
    "dry|d" => \$dry,
    "ignore|i=s" => \$ignore,
    "quiet|q" => \$quiet,
    "help|h" => \$help,
    "pattern|p=s" => \$pattern,
);

usage(0) if $help;
$ignore = defined $ignore ? $ignore : "";

my $dir = shift;
usage(1) unless defined $dir && defined $pattern;

opendir(my $dh, $dir);
while (my $file = readdir $dh) {
    next unless $file =~ /$pattern/;
    if ($ignore && $file =~ /$ignore/) {
        say "ignoring $file" unless $quiet;
        next;
    }
    if ($dry) {
        say "[SAD] $file";
        next;
    }
    say "[SAD] $file" unless $quiet;
    unlink catfile($dir, $file);
}
closedir $dh;
