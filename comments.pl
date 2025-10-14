#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use feature 'say';
use Getopt::Long;
use File::Copy;
use File::Basename;

sub usage {
    my ($exit) = @_;
    $exit = 0 unless $exit;
    my $prog = basename($0);
    
    say "usage: $prog <command> [options]\n";
    say << "USAGE";
list comments in a file or remove them

commands:
    ls  <path>  list comments in a given file
    rm  <path>  remove comments from a given file

options:
    -d, --dry       dry run
    -c, --comment   comment delineator, default '#'
    -m, --multi     include multi-lined comments, currently just /* ... */
    -i, --ignore    regex for things to ignore, (//go:generate, etc). flag can be used multiple times
USAGE
    exit $exit;
}

my ($dry, $comment, $multi, @ignore);
GetOptions(
    "dry|d" => \$dry,
    "comment|c=s" => \$comment,
    "multi|m" => \$multi,
    "ignore|i=s" => \@ignore,
);

my %commands = (
    ls => \&list,
    rm => \&remove,
);

my $cmd = shift;
usage(1) unless $cmd;
usage(0) if lc $cmd eq 'help';

my $path = shift;

if (exists $commands{$cmd}) {
    $commands{$cmd}->(
        $path,
        dry => $dry,
        comment => $comment,
        multi => $multi,
        ignore => \@ignore,
    )
} else {
    usage(1);
}

sub list {
    my ($path, %opts) = @_;

    my $comment = $opts{comment} // "#";
    my $multi = $opts{multi} // 0;
    my $ignore_ref = $opts{ignore};
    my @ignore = @{ $ignore_ref };

    open(my $fh, '<', $path);
    my $in_block = 0;
    while (my $line = <$fh>) {
        chomp $line;
        if ($in_block && $multi) {
            $in_block = 0 if $line =~ /\*\//;
            say $line; 
            next;
        }
        if ($line =~ /\/\*/ && $multi) {
            $in_block = 1;
            say $line;
            next;
        }
        next if grep { $line =~ /$_/ } @ignore;
        say $1 if $line =~ /($comment.*$)/;
    }
    close $fh;
}

sub remove {
    my ($path, %opts) = @_;

    my $comment = $opts{comment} // "#";
    my $multi = $opts{multi} // 0;
    my $ignore_ref = $opts{ignore};
    my @ignore = @{ $ignore_ref };

    my $tmp = "$path.tmp";    
    my $in_block = 0;

    open(my $in, '<', $path);
    open(my $out, '>', $tmp);
    while (my $line = <$in>) {
        chomp $line;

        if ($in_block && $multi) {
            $in_block = 0 if $line =~ /\*\//;
            next;
        }        
        if ($line =~ /\/\*/ && $multi) {
            $in_block = 1;
            next;
        } 
        $line =~ s/($comment.*$)// unless grep { $line =~ /$_/ } @ignore;
        say $out $line;
    }
    close $in;
    close $out;

    move($tmp, $path);
}