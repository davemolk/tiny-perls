#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use feature 'say';
use IO::Socket::INET;
use File::Spec::Functions;
use File::Path qw(make_path);

$| = 1;

my $upload_dir = 'uploads';
make_path($upload_dir) unless -d $upload_dir;

my $port = shift // 5000;

my $server = IO::Socket::INET->new(
    LocalHost => 'localhost',
    LocalPort => $port,
    Proto => 'tcp',
    Listen => 5,
    Reuse => 1,
);

say "file server listening on $port";

while (my $client = $server->accept()) {
    $client->autoflush(1);
    my $peer_host = $client->peerhost;
    my $peer_port = $client->peerport;

    say "[INFO] connection established from $peer_host:$peer_port"; 
    
    my $req = <$client>;
    chomp($req);

    my ($action, $file, $size) = split(/\s+/, $req);
    my $res;
    if (lc $action eq "upload") {
        $res = upload_handler($client, $file, $size);
    } elsif (lc $action eq "download") {
        $res = download_handler($client, $file);
    } else {
        say $client "ERR invalid action";
    }
    close $client;
}

sub upload_handler {
    my ($sock, $file, $size) = @_;
    my $path = catfile($upload_dir, $file);

    open (my $fh, '>', $path) or do {
        say $sock "ERR failed to open file for writing";
        return;
    };
    binmode($fh);
    binmode($sock);
    
    my $remaining = $size;
    my $buf;
    while ($remaining > 0) {
        my $read = read($sock, $buf, $remaining > 4096 ? 4096 : $remaining);
        last unless $read;
        print $fh $buf;
        $remaining -= $read;
    }
    close $fh;

    if ($remaining == 0) {
        say $sock "OK upload complete";
        say "[INFO] upload of $file complete";
    } else {
        say $sock "ERR incomplete upload";
        unlink $path;
    }
}

sub download_handler {
    my ($sock, $file) = @_;
    my $path = catfile($upload_dir, $file);

    unless (-e $path) {
        say $sock "ERR file not found";
        return;
    }
    
    open (my $fh, '<', $path) or do {
        say $sock "ERR failed to read file";
        return;
    };
    binmode($fh);
    binmode($sock);

    my $size = -s $path;
    say $sock "OK $size";

    my $buf;
    while (read($fh, $buf, 4096)) {
        print $sock $buf;
    }
    close $fh; 
    say "[INFO] download of $file successful";
}