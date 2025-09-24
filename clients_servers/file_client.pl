#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use IO::Socket::INET;
use Getopt::Long;
use File::Basename;
use autodie;

$| = 1;

my ($host, $port, $file, $download);
$host = 'localhost';
$port = 5000;

GetOptions(
    "host|h=s" => \$host,
    "port|p=i" => \$port,
    "file|f=s" => \$file,
    "download|d=s" => \$download,
);

die "specify --file to upload or --download to download\n" unless $file || $download; 

my $client = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Proto => 'tcp',
);

$client->autoflush(1);
binmode $client;

if ($file) {
    upload_file($client, $file);
} elsif ($download) {
    download_file($client, $download);
}

close $client;

sub upload_file {
    my ($sock, $path) = @_;
    die "$path not found\n" unless -e $path;

    my $filename = basename($path);
    my $size = -s $path;

    open(my $fh, '<', $path);
    binmode($fh);

    say $sock "upload $filename $size";

    my $buf;
    while (read($fh, $buf, 4096)) {
        print $sock $buf;
    }
    close $fh;

    my $res = <$sock>;
    chomp $res;
    say "server: $res";
}

sub download_file {
    my ($sock, $filename) = @_;

    say $sock "download $filename";

    my $res = <$sock>;
    chomp $res;

    if ($res =~ /^OK (\d+)$/) {
        my $size = $1;
        open(my $fh, '>', $filename);
        binmode($fh);

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
            say "downloaded $filename successfully";
        } else {
            say "error: incomplete download";
            unlink $filename;
        }
    } else {
        say "server error: $res";
    }
}
