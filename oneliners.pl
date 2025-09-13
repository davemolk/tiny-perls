#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use JSON;
use Getopt::Long;
use File::Spec::Functions;
use File::Path qw(make_path);

sub usage {
    my ($exit) = @_;

    say << "USAGE";
usage: $0 <command> [options] 

run your saved your perl one-liners

commands:
    list                            list one-liners by name
    save <name> <cmd> [-f,--flags]  save one-liner
    delete <name>                   delete 
    <name>                          run saved command
    help                            show this help

options:
    -d, --dry                       print command but don't run
USAGE
    exit $exit;
}

my ($flags, $dry);

GetOptions(
    "flags|f=s" => \$flags,
    "dry|d" => \$dry,
) or die "parsing opts: $!";

my $parsed_flags = $flags // "pe";

my %commands = (
    save => \&cmd_save,
    delete => \&cmd_delete,
    list => \&cmd_list,
    help => \&usage,
);

my $cmd = shift @ARGV;
usage(1) unless $cmd;

my $dir_path = catfile($ENV{"HOME"}, ".oneliners");
make_path($dir_path) unless (-d $dir_path);

if (exists $commands{$cmd}) {
    $commands{$cmd}->(
        @ARGV,
        dir_path => $dir_path,
        flags => $parsed_flags,
        dry => $dry,
    );
} else {
    run_saved($cmd, 
        ,@ARGV,
        dir_path => $dir_path,
        flags => $parsed_flags,
        dry => $dry, 
    );
}

sub path_from_name {
    my ($name, $dir_path) = @_;
    my $file_name = "$name.json";
    my $file_path = catfile($dir_path, $file_name);
    return $file_path;
}

sub cmd_list {
    my (%opts) = @_;
    my $dir_path = $opts{dir_path};
    opendir(my $dh, $dir_path) or die "list: $!";
    my $count = 0;
    for my $file (readdir $dh) {
        next unless $file =~ /\.json$/;
        say $file;
        $count++;
    }
    closedir $dh;
    say "no files found" if $count == 0;
}

sub cmd_delete {
    my ($name, %opts) = @_;
    my $dir_path = $opts{dir_path}; 
    my $path = path_from_name($name, $dir_path);
    unlink $path or die "deleting $path: $!";
    say "deleted $path";
}

sub cmd_save {
    my ($name, $cmd, %opts) = @_;
    my $dir_path = $opts{dir_path};
    my $flags = $opts{flags};
    my $path = path_from_name($name, $dir_path);
    my %hash = (
        "name" => $name,
        "cmd" => $cmd,
        "flags" => $flags
    );
    my $json = encode_json(\%hash);
    open(my $fh, '>', $path) or die "open for write: $!";
    say $fh $json;
    close $fh;
    say "$name saved";
}

sub run_saved {
    my ($name, %opts) = @_;
    my $dir_path = $opts{dir_path};
    my $dry = $opts{dry};
    my $file_path = path_from_name($name, $dir_path);
    
    my $json;
    {
        open(my $fh, '<', $file_path) or die "opening $file_path: $!";
        local $/;
        $json = <$fh>;
        close $fh;
    }

    my $hash = decode_json($json);
    my $cmd = $hash->{cmd};
    my $flags = $hash->{flags};
    if ($dry) {
       say "perl -$flags '$cmd'";    
       return;
    }
    system('perl', "-$flags", $cmd);
}
