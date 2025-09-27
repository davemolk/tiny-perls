#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use JSON;
use HTTP::Tiny;
use autodie;
use File::Basename;

sub usage {
    my ($exit) = @_;
    my $prog = basename($0);

    say "usage: $prog [option]\n";
    say "get newest feed from lobste.rs. use 'hot' argument for hottest.";
    exit $exit;
}

my $hottest = "https://lobste.rs/hottest.json";
my $newest = "https://lobste.rs/newest.json";

usage(0) if $ARGV[0] && $ARGV[0] =~ /h|help/i;

my $url = ($ARGV[0] && $ARGV[0] =~ /hot/i) ? $hottest : $newest;

sub request {
    my ($url) = @_;
    
    my $ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:133.0) Gecko/20100101 Firefox/133.0";
    my $http = HTTP::Tiny->new(
        "agent" => $ua,
    );
    my $res = $http->get($url, {
        headers => {
            "Accept" => "application/json",
        }
    });

    my $status = $res->{status};
    my $reason = $res->{reason};
    die "failed: $status, $reason" unless $res->{success};

    return $res->{content};
}

my $json = request($url);

my $array_ref = decode_json $json;
foreach my $item ( @$array_ref ) {
    say "title: $item->{'title'}";
    say "url: $item->{'url'}";
    say "tags: " . join(', ', @{ $item->{'tags'} });
    say "comment count: $item->{'comment_count'}";
    say "id: $item->{'short_id'}\n";
}

say "type the <id> to see the post's comments, 'open <id>' to open the url in a browser, or 'exit' to quit.";
say "note: you can enter a fragment of a post's title instead of the id.";
my $input = <STDIN>;
chomp $input;

exit 0 if $input =~ /exit/i;
if ($input =~ /^open [a-z0-9]+/i) {
    my $fragment = lc substr $input, 5;
    say $fragment;
    my $match = find_match($fragment, $array_ref);
    if ($match) {
        system("open $match->{'url'}");
    } else {
        warn "no matches found for $fragment\n"; 
        exit 1;
    }
} else {
    my $fragment = lc $input;
    say $fragment;
    my $match = find_match($fragment, $array_ref);
    if (!$match) {
        warn "no matches found for $fragment\n"; 
        exit 1;
    }
    if ($match->{'comment_count'} == 0) {
        warn "no comments for $match->{'title'}\n";
        exit 1; 
    } 
    my $comment_url = "https://lobste.rs/s/$match->{'short_id'}.json";
    my $comments = request($comment_url);
    my $parsed_comments = decode_json($comments);
    my %comment_depth;
    foreach my $c (@{$parsed_comments->{'comments'}}) {
        my $parent = $c->{'parent_comment'};
        $comment_depth{$c->{'short_id'}} = 
            (defined $parent && exists $comment_depth{$parent} ? $comment_depth{$parent} : -1) + 1;
    }

    foreach my $c (@{$parsed_comments->{'comments'}}) {
        my $depth = $comment_depth{$c->{'short_id'}};
        my $prefix = "\t" x $depth;
        my $text = $c->{'comment_plain'};
        $text =~ s/\r\n\r\n/ /g;
        say "\n$prefix* $text";
    }
}

sub find_match {
    my ($frag, $array_ref) = @_;
    my ($match) = grep { 
        lc($_->{'short_id'}) =~ /^\Q$frag\E/ || lc($_->{'title'}) =~ /^\Q$frag\E/ 
    } @{$array_ref};
    return $match;
}
