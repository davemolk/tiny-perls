#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use autodie;
use IO::Socket::INET;

# autoflush
$| = 1;

my $port = shift // 5000;

my $server = IO::Socket::INET->new(
    LocalHost => '0.0.0.0',
    LocalPort => $port,
    Proto => 'tcp',
    Reuse => 1,
    Listen => 1,
);

$SIG{INT} = sub { say "closing server"; $server->close(); exit 0; };

say "listening on port $port";

while (my $client = $server->accept()) {
    my $data = "";
    $client->recv($data, 1024);
    say $data;
}