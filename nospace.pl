#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use Getopt::Long;
use File::Spec::Functions qw(catfile);
use File::Basename;

sub usage {
    my ($exit) = @_;
    my $prog = basename($0);

    say "usage: $prog [options] [dir]\n";
    say << "USAGE";
remove spaces from the contents of a given directory. 
operates on current directory if none is provided.

options:
        -d, --dry          dry run (don't rename files)
        -i, --ignore REG   ignore files matching this pattern
        -s, --separator S  use S to replace whitespace (default: "")
        -v, --verbose      verbose output
        -h, --help         show this help msg
USAGE
    exit $exit;
}

my ($dry, $help, $verbose);
my ($ignore, $sep) = ("", "");

GetOptions(
    "dry|d" => \$dry,
    "help|h" => \$help,
    "ignore|i=s" => \$ignore,
    "verbose|v" => \$verbose,
    "separator|s=s" => \$sep
) or die "failed to parse opts: $!";

usage(0) if $help;

my $dir = shift // ".";

opendir my $dh, $dir or die "failed to open $dir: $!";
while (my $file = readdir $dh) {
    next unless $file =~ /\s/;

    if ($ignore && $file =~ /$ignore/) {
        say "ignoring $file" if $verbose;
        next;
    }
    
    (my $renamed = $file) =~ s/\s+/$sep/g;
    
    my $old = catfile($dir, $file);
    my $new = catfile($dir, $renamed);

    if ($dry) {
        say "$file -> $renamed";
    } else {
        say "renaming $file -> $renamed" if $verbose;
        rename $old, $new or warn "rename failed: $old -> $new: $!";
    }
}
closedir $dh;