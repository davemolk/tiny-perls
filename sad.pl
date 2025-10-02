#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use feature 'say';
use Getopt::Long;
use File::Basename;
use File::Path qw(remove_tree);
use File::Spec::Functions qw(catfile);

sub usage {
    my ($exit) = @_;
    my $prog = basename($0);

    printf <<'USAGE', $prog, $prog;
seek and destroy => sought and destroyed. 
defaults to files in current directory.

usage: %s [options] <pattern=REGEX> [dir]
%s -c "\.txt$" "foo" 

options:
        -d, --dry           dry run
        --both              delete files and directories that match the pattern
        --dirs              only delete directories
        -i, --ignore REGEX  ignore files matching this pattern
        -q, --quiet         don't report what was deleted
        --nc, --no-confirm  don't confirm, just delete
        -h, --help          show this helpful help

USAGE
    exit $exit;
}


my ($dry, $no_confirm, $ignore, $quiet, $help, $dirs, $both);
GetOptions(
    "dry|d" => \$dry,
    "nc|no-confirm" => \$no_confirm,
    "ignore|i=s" => \$ignore,
    "quiet|q" => \$quiet,
    "both" => \$both,
    "dirs" => \$dirs,
    "help|h" => \$help,
);

usage(0) if $help;

my $pattern = shift @ARGV;
usage(1) unless defined $pattern;

my $target_dir = shift @ARGV // ".";

$ignore = defined $ignore ? $ignore : "";
$both = defined $both ? $both : 0;
$dirs = defined $dirs ? $dirs : 0;
my $confirm = defined $no_confirm ? 0 : 1;

opendir(my $dh, $target_dir);
while (my $file = readdir $dh) {
    next if $file eq '.' or $file eq '..';
    next unless $file =~ /$pattern/;

    my $full_path = catfile($target_dir, $file);
    if (-d $full_path) {
        next unless $both or $dirs;
    }

    if (-f $full_path) {
        next if $dirs; 
    }
    
    if ($ignore && $file =~ /$ignore/) {
        say "ignoring $file" unless $quiet;
        next;
    }
    
    if ($dry) {
        say "[SAD] $file";
        next;
    }
    
    say "[SAD] $file" unless $quiet;
    if ($confirm) {
        say "confirm delete, enter y/n";
        my $input = <STDIN>;
        chomp $input;
        next unless lc $input eq 'y';
        say "";
    }

    my %dir_opts = (safe=>1);
    $dir_opts{verbose} = 1 unless $quiet;

    unlink($full_path) if -f $full_path;
    remove_tree($full_path, \%dir_opts) if -d $full_path;
}
closedir $dh;
