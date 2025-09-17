#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use autodie qw(:all);
use Time::Piece;
use Getopt::Long;
use File::Copy;
use File::Spec::Functions qw(catfile catdir);

sub usage {
    my ($exit) = @_;

    say << "USAGE";
usage: $0 [options] 

move files in a directory to a backup folder (formatted as iso8601.bak)

options:
    -m, --match       pattern for files to include (defaults to all)
    -i, --ignore      pattern for files to ignore
    -f, --files       only move files
    -o, --out-dir=s   destination directory for backup (default is current)
    -d, --dry         dry run
    -h, --help        show this help

USAGE
    exit $exit;
}


my ($match, $ignore, $files, $dry, $dest);

GetOptions(
    "match|m=s" => \$match,
    "ignore|i=s" => \$ignore,
    "files|f" => \$files,
    "out|out-dir|o=s" => \$dest,
    "dry|d" => \$dry,
);

die "destination dir $dest not found" if $dest && !(-d $dest);

my $t = localtime;
my $time = $t->datetime =~ s/:/-/gr;
my $backup = "$time.bak";
$backup = catdir($dest, $backup) if $dest;

mkdir $backup unless $dry or -d $backup;

opendir(my $dh, ".");
while (my $file = readdir $dh) {
    next if $file eq $backup;
    next if $file eq '.' or $file eq '..';
    next if $files && -d $file;
    next if $ignore && $file =~ /$ignore/; 
    next if $match && $file !~ /$match/;

    my $current = catfile(".", $file);
    my $moved = catfile($backup, $file);
    if ($dry) {
       say "dry: $current -> $moved";
       next;
    }
    move $current, $moved; 
}
closedir $dh;