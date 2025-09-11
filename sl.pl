#!/usr/bin/perl

# get school lunch instead of dealing with the crappy website

use strict;
use warnings;
use File::Spec::Functions;
use feature 'say';
use JSON;
use POSIX qw(strftime);
use HTTP::Tiny;

my @now = localtime;
# wday is at index 6, week starts on sunday and is zero-indexed
if ($now[6] == 6 || $now[6] == 0) {
    say "no school on the weekend!";
    exit 0;
}

my $date_str = strftime("%m/%d/%Y", @now);
my $config_path = catfile($ENV{"HOME"}, ".lunch/config.json");
my $json;
{
    open(my $fh, '<', $config_path) or die "failed to open $config_path: $!";
    local $/;
    $json = <$fh>;
    close $fh;
}
my $hash = decode_json($json);
my $grade = $hash->{grade};
my $id = $hash->{school_id};

my $base = "https://webapis.schoolcafe.com/api/CalendarView/GetDailyMenuitemsByGrade?SchoolId=";
my $url = sprintf("%s%s&ServingDate=%s&ServingLine=Traditional%%20Lunch&MealType=Lunch&Grade=%s&PersonId=null", $base, $id, $date_str, $grade);

say "checking school lunch...";
say '-' x 24;

my $ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:133.0) Gecko/20100101 Firefox/133.0";
my $http = HTTP::Tiny->new(
    "agent" => $ua,
);
my $res = $http->get($url, {
    headers => {
        "Accept" => "application/json",
    }
});

die "failed: $res->{status}\n$res->{reason}\n" unless $res->{success};
die "no response body" unless length $res->{content};

my $lunch = decode_json($res->{content});

foreach my $key ('ENTREE', 'ENTREES') {
    if (exists $lunch->{$key}) {
        foreach my $item (@{$lunch->{$key}}) {
            say $item->{"MenuItemDescription"};
        }
        last;
    }
}
