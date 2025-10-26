#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use feature 'say';
use HTTP::Tiny;
use File::Basename;
use Getopt::Long;

sub usage {
    my ($exit) = @_;
    $exit = 0 unless $exit;
    my $prog = basename($0);
    
    say "usage: $prog <url> [options]\n";
    say << "USAGE";
down detector

options:
    -h      head request (default get)
    -v      print content of response
    --help  display this text
USAGE
    exit $exit;
}

my ($help, $verbose, $head);
GetOptions(
    "h|head" => \$head,
    "v|verbose" => \$verbose,
    "help" => \$help,
);

usage(0) if $help;

my $url = shift @ARGV or die "need a url!";
my $ua = "github.com/davemolk/tiny-perls";
my $http = HTTP::Tiny->new(
    "agent" => $ua,
);

say "requesting $url\n" if $verbose;
my $res = defined $head ? $http->head($url) : $http->get($url); 

say "status: $res->{status}";
say "reason: $res->{reason}" unless $res->{success};
say "headers:";
say "\t$_: $res->{headers}{$_}" for sort keys %{ $res->{headers} };
say "";

say $res->{content} if ($res->{success} && $verbose && defined $res->{content});
