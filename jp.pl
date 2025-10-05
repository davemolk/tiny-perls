#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use feature 'say';
use JSON;
use Getopt::Long;
use Data::Dumper;
use File::Basename;

sub usage {
    my ($exit) = @_;
    my $prog = basename($0);

    say "usage: $prog [options] [target]\n";
    say << "USAGE";
search json by key, value, or both. run without argument to pretty-print input.

options:
        -e, --exact     exact matching (case-sensitive)
        -k, --key       search keys (default keys and values)
        -v, --value     search values (default keys and values)
        -h, --help      show this help msg
USAGE
    exit $exit;
}

my ($exact, $key, $value, $sort, $help);
GetOptions(
    "exact|e" => \$exact,
    "key|k" => \$key,
    "value|v" => \$value,
    "sort|s" => \$sort,
    "help|h" => \$help,
);

my %opts = (
    exact => $exact,
    match_key => $key,
    match_value => $value,
);

my $target = shift;

my $json_text = do { local $/; <STDIN> };
my $data = decode_json($json_text);

sub ppj {
    my ($data, $sort) = @_;
    
    my $pp;
    if ($sort) {
        $pp = JSON->new->canonical([1])->pretty->encode($data);
    } else {
        $pp = JSON->new->pretty->encode($data);
    }
    
    say $pp;
}

sub find_paths {
    my ($data, $path, $target, %opts) = @_;
    my $match_keys = $opts{match_key};
    my $match_values = $opts{match_value};

    if (ref $data eq 'HASH') {
        if ($match_keys) {
            search_keys($data, $path, $target, %opts);
        } elsif ($match_values) {
            search_values($data, $path, $target, %opts);
        } else {
            search_both($data, $path, $target, %opts);
        }        
    } elsif (ref $data eq 'ARRAY') {
        for (my $i = 0; $i < @$data; $i++) {
            my $new_path = [@$path, "[$i]"];
            find_paths($data->[$i], $new_path, $target, %opts);
        }
    }
}

sub search_keys {
    my ($data, $path, $target, %opts) = @_;
    
    foreach my $key (keys %{ $data }) {
        my $new_path = [@$path, $key];
        
        if ($opts{exact}) {
            print_results($new_path, $data->{$key}) if $key eq $target;
        } else {
            print_results($new_path, $data->{$key}) if $key =~ /$target/i;
        }
        
        find_paths($data->{$key}, $new_path, $target, %opts);
    }
}

sub search_values {
    my ($data, $path, $target, %opts) = @_;
 
    keys %{ $data };
    while (my($key, $value) = each %{ $data }) {
        my $new_path = [@$path, $key];

        if ($opts{exact}) {
            print_results($new_path, $value) if !ref($value) && $value eq $target;
        } else {
            print_results($new_path, $value) if !ref($value) && $value =~ /$target/i;
        }

        find_paths($data->{$key}, $new_path, $target, %opts);
    }
}

sub search_both {
    my ($data, $path, $target, %opts) = @_;
 
    # https://stackoverflow.com/questions/3033/whats-the-safest-way-to-iterate-through-the-keys-of-a-perl-hash#3360
    keys %{ $data };
    while (my($key, $value) = each %{ $data }) {
        my $new_path = [@$path, $key];
        
        if ($opts{exact}) {
            print_results($new_path, $value) if $key eq $target or (!ref($value) && $value eq $target);
        } else {
            print_results($new_path, $value) if $key =~ /$target/i or (!ref($value) && $value =~ /$target/i);
        }
        
        find_paths($data->{$key}, $new_path, $target, %opts);
    }
}

sub print_results {
    my ($path, $value) = @_;
    my $joined_path = join(' -> ', @$path);
    say "$joined_path";
    say ref $value ? Dumper($value) : $value;
    say "";
}

if ($help) {
    usage(0);
} elsif ($target) {
    find_paths($data, [], $target, %opts);
} else {
    ppj($data, $sort);
}
