#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use feature 'say';
use JSON;
use Getopt::Long;
use HTTP::Tiny;
use File::Spec::Functions qw (catfile);
use File::Basename;

sub usage {
    my ($exit) = @_;
    $exit = 0 unless $exit;
    my $prog = basename($0);
    
    say "usage: $prog <command> [options]\n";
    say << "USAGE";
search phish.in API v2 for songs or shows. choose to listen or download.

commands:
    song     <slug>             list versions of your favorite song
    shows                       list shows
    show     <YYYY-MM-DD>       get info for a show
    listen   <YYYY-MM-DD|id>    listen to a track (provide id) or a show (provide date), opens browser
    download <YYYY-MM-DD|id>    (use date for show, track id for track)
    help                        show this help

options:
    -p,   --page         page number, default 1
    --pp, --per-page     items per page [1..1000], default 10
    -y,   --year         filter by year
    --yy, --year-range   filter by year range, e.g. 1987-1988
    -s,   --start-date   filter by start date, format as 1994-10-31
    -e,   --end-date     filter by end date, format as 1994-10-31
    -d,   --dir          directory for downloads (uses current directory otherwise)
USAGE
    exit $exit;
}

my ($page, $pp, $year, $years, $start, $end, $dir);
GetOptions(
    "page|p=i" => \$page,
    "per-page|pp=i" => \$pp,
    "year|y=s" => \$year,
    "years|yy=s" => \$years,
    "start-date|start|s=s" => \$start,
    "end-date|end|e=s" => \$end,
    "dir|d=s" => \$dir,
);

$page = 1 unless $page;
$pp = 10 unless $pp;

my %commands = (
    song => \&get_tracks,
    shows => \&get_shows,
    show => \&get_show,
    listen => \&handle_listen,
    download => \&handle_download,
);

my $cmd = shift @ARGV;
usage(1) unless $cmd;
usage (0) if $cmd eq 'help';

$dir = catfile($ENV{HOME},"/Desktop", "phish") unless defined $dir;
if ($cmd eq "download") {
    mkdir $dir unless -d  $dir;
}

my $http = http();

if (exists $commands{$cmd}) {
    $commands{$cmd}->(
        @ARGV,
        page => $page,
        pp => $pp,
        year => $year,
        years => $years,
        start => $start,
        end => $end,
        http => $http,
        dir => $dir,
    );
} else {
    usage(1);
}

sub get_tracks {
    my ($slug, %opts) = @_;
    my $year = $opts{year};
    my $years = $opts{years};
    my $start = $opts{start};
    my $end = $opts{end};
    my $http = $opts{http};

    my $url = "https://phish.in/api/v2/tracks?page=$page&per_page=$pp&audio_status=complete_or_partial&sort=date%3Adesc&song_slug=$slug";
    $url .= "&year=$year" if $year;
    $url .= "&year_range=$years" if $years;
    $url .= "&end_date=$end" if $end;
    $url .= "&start_date=$start" if $start;

    my $res = request($http, $url);
    my $ref = decode_json($res);

    say "#" x 20;
    say "Current Page: $ref->{current_page}";
    say "Total Pages: $ref->{total_pages}";
    say "Total Entries: $ref->{total_entries}";
    say "#" x 20;
    say "";
    for my $track (@ { $ref->{tracks}}) {
        say "Venue: $track->{show}->{venue}->{name} ($track->{show}->{venue}->{city})";
        say "Date: $track->{show_date}";
        say "Likes: $track->{show}->{likes_count}";
        if (@ { $track->{tags}} != 0) {
            my $tags = extract_tags($track);
            say "Tags: $tags";
        } 
        say "Track ID: $track->{id}";
        say "Listen: $track->{mp3_url}";
        say "";
    }
}

sub get_shows {
    my (%opts) = @_;
    my $year = $opts{year};
    my $years = $opts{years};
    my $start = $opts{start};
    my $end = $opts{end};
    my $http = $opts{http};

    $start = '1970-01-01' unless $start;
    $end = '2070-01-01' unless $end;

    my $url = "https://phish.in/api/v2/shows?page=$page&per_page=$pp&audio_status=complete_or_partial&sort=date%3Adesc";
    $url .= "&year=$year" if $year;
    $url .= "&year_range=$years" if $years;
    $url .= "&end_date=$end" if $end;
    $url .= "&start_date=$start" if $start;

    my $res = request($http, $url);

    my $ref = decode_json($res);
    say "#" x 20;
    say "Total Pages: $ref->{total_pages}";
    say "Current Page: $ref->{current_page}";
    say "Total Entries: $ref->{total_entries}";
    say "#" x 20;
    say "";
    for my $show (@ { $ref->{shows}}) {
        say "Venue: $show->{venue_name} ($show->{venue}->{city})";
        say "Date: $show->{date}";
        say "Likes: $show->{likes_count}";
        if (@ { $show->{tags}} != 0) {
            my $tags = extract_tags($show);
            say "Tags: $tags";
        } 
        say "";
    }
}

sub get_show {
    my ($date, %opts) = @_;
    my $http = $opts{http};

    my $url = "https://phish.in/api/v2/shows/$date?audio_status=complete_or_partial";

    my $res = request($http, $url);
    my $ref = decode_json($res);

    say "Venue: $ref->{venue_name} ($ref->{venue}->{city})";
    say "Date: $ref->{date}";
    say "Likes: $ref->{likes_count}";
    if (@ { $ref->{tags}} != 0) {
        my $tags = extract_tags($ref);
        say "Tags: $tags";
    }
    say "";

    my $set = "Set 1";
    say "$set";
    for my $track ( @{ $ref->{tracks}}) {
        if ($track->{set_name} ne $set) {
            say "\n$track->{set_name}";
            $set = $track->{set_name}; 
        }
        my $tags = extract_tags($track);
        if ($tags) {
            say "$track->{title} ($tags)";
        } else {
            say "$track->{title}";
        }
    }
}

sub request {
    my ($http, $url) = @_;

    my $res = $http->get($url);

    die "failed: $res->{status}\n$res->{reason}\n" unless $res->{success};
    die "no response body" unless length $res->{content};

    return $res->{content};
}

sub http {
    my $ua = "github.com/davemolk/tiny-perls";
    my $http = HTTP::Tiny->new(
        "agent" => $ua,
        default_headers => {
            "Accept" => "application/json",
        }
    );
    return $http;
}

sub handle_download {
    my ($identifier, %opts) = @_;
    my $http = $opts{http};
    my $dir = $opts{dir};

    if ($identifier !~ /\d{4}-\d{2}-\d{2}/) {
        # track id
        my $res = request($http, "https://phish.in/api/v2/tracks/$identifier");
        my $ref = decode_json($res);
        die "no mp3 available" unless $ref->{mp3_url};
        my $filename = "$ref->{slug}-$ref->{show_date}.mp3";
        $filename = catfile($dir, $filename);
        download_media($http, $ref->{mp3_url}, $filename);
        return;
    } 
    # show id
    my $downloaded = check_for_download($http, $identifier, $dir);
    return if $downloaded;
    say "show is not currently available, requesting download";
    request_album_zip($http, "https://phish.in/api/v2/shows/request_album_zip", $identifier);
    say "requested, waiting a moment";
    sleep(2);
    for (0..5) {
        say "checking for download";
        my $downloaded = check_for_download($http, $identifier, $dir);
        return if $downloaded;
        sleep(2);
    }
    say "unable to download, try again later";
}

sub check_for_download {
    my ($http, $identifier, $dir) = @_;
    
    my $res = request($http, "https://phish.in/api/v2/shows/$identifier?audio_status=complete_or_partial");
    my $ref = decode_json($res);
    return 0 unless $ref->{album_zip_url};
    say "media is available!";
    my $filename = $ref->{date};
    $filename = catfile($dir, "$filename.zip");
    download_media($http, $ref->{album_zip_url}, $filename);
    return 1;
}

sub download_media {
    my ($http, $url, $filename) = @_;

    say "requesting media to download";
    my $res = $http->get($url);
    die "failed: $res->{status}\n$res->{reason}\n" unless $res->{success};
    die "no response body" unless length $res->{content};  

    say "writing media to $filename";
    open(my $fh, '>', $filename);
    binmode $fh;
    print $fh $res->{content};
    close $fh;
    say "saved media to $filename (", -s $filename, " bytes)";
}

sub request_album_zip {
    my ($http, $url, $identifier) = @_;

    my $json = encode_json({ date => $identifier });
    my $res = $http->post($url, {
        headers => {
            'Content-Type' => 'application/json',
        },
        content => $json,
    });

    die "failed: $res->{status}\n$res->{reason}\n" unless $res->{success};
    say "album zip request successful";
}

sub handle_listen {
    my ($identifier, %opts) = @_;
    my $http = $opts{http};

    if ($identifier =~ /\d{4}-\d{2}-\d{2}/) {
        my $url = "https://phish.in/$identifier";
        system("open $url");
    } else {
        my $url = "https://phish.in/api/v2/tracks/$identifier";
        my $res = request($http, $url);
        my $ref = decode_json($res);
        my $mp3 = $ref->{mp3_url};
        system("open $mp3");
    }
}

sub extract_tags {
    my ($ref) = @_;

    my @tags;
    for my $tag (@ { $ref->{tags} }) {
        push(@tags, $tag->{name});
    }
    my $tag_str = join(', ', @tags);
    return $tag_str;
}