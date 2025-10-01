#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use feature 'say';
use JSON;
use File::Spec::Functions;
use Getopt::Long;
use Text::ParseWords qw(shellwords);
use File::Basename;

sub usage {
    my ($exit) = @_;
    my $prog = basename($0);
    
    say "usage: $prog [options]\n";
    say << 'USAGE';
practice your perl one-liners. you'll need a data.txt file that you'll run your scripts against
and a prompts.json file, formatted like so:

{
    "1" : {
      "prompt" : "number each line.",
      "answer" : "perl -ne 'print \"$.: $_\"'"
    },
    "2" : {
      "answer" : "perl -ne '@w = split; print \"$w[1] $w[3]\\n\" if @w > 3'",
      "prompt" : "print the second and fourth word of each line, if they exist."
   }
}

options:
    -d, --dir       use a custom directory (default is ~/.olp )
    -h, --help      display this help
    
USAGE
    exit $exit;
}

my ($dir, $help);
GetOptions(
    "help|h" => \$help,
    "dir|d=s" => \$dir,
);

usage(0) if $help;

my $home = $ENV{HOME};
$dir = $dir // ".olp";
my $path = catfile($home, $dir);
mkdir $path unless -d $path;

my $prompts_file = catfile($path, "prompts.json");
my $json = read_file($prompts_file);

my $data_file = catfile($path, "data.txt");
my $data = read_file($data_file);

sub read_file {
    my ($path) = @_;

    my $data;
    open(my $fh, '<', $path);
    local $/;
    $data = <$fh>;
    close $fh;
    return $data;
}

say "one-liner practice: enter 's' to skip or 'q' to quit.\n";

my $json_ref = decode_json($json);
my $quit = "q";
my $skip = "s";

foreach my $key (keys %{$json_ref}) {
    say "*** your data file contents ***";
    say $data;
    say "$key: $json_ref->{$key}->{'prompt'}";
    my $input = <STDIN>;
    chomp $input;
    exit 0 if $input eq 'q';
    next if $input eq 's';
    my @parts = shellwords($input);
    die "format as [options] [cmd]" unless scalar @parts == 2;
    test_command($parts[0], $parts[1], $data_file);
    say "one possible answer: $json_ref->{$key}->{'answer'}";
    say "continue practicing? y/n";
    my $cont = <STDIN>;
    chomp $cont;
    exit 0 unless $cont eq 'y';
    say "";
}

sub test_command {
    my ($args, $liner, $data_file) = @_;
    say "\n*** command result ***";
    my $status = system("perl", "-$args", "$liner", $data_file);
    say "error running one-liner" if $status != 0;
    say "";
}
