#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use feature 'say';
use IO::Socket::INET;

$| = 1;

my $addr = shift // 'localhost';
my $port = shift // 5000;

my $client = IO::Socket::INET->new(
    PeerAddr => $addr,
    PeerPort => $port,
    Proto => 'tcp',
);

while (1) {
    say "enter something:";
    my $data = <STDIN>;
    chomp $data;
    if ($data) {
        $client->send($data);
        my $res;
        $client->recv($res, 1024);
        say "got $res" if $res;
    }
}