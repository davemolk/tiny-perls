#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use feature 'say';
use JSON;

my $json;
if (@ARGV) {
    open(my $fh, '<', $ARGV[0]);
    local $/;
    $json = <$fh>;
    close $fh;
} else {
    local $/;
    $json = <STDIN>;
}

my $data = decode_json($json);
my $pp = JSON->new->pretty->encode($data);
say $pp;