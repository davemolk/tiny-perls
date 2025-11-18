#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use feature 'say';
use File::Path qw(remove_tree);
use File::Spec::Functions qw(catfile);

# https://theweeklychallenge.org/

my $target_dir = shift @ARGV // ".";
my $lang = shift @ARGV;
say "searching for $lang" if defined $lang;

opendir(my $dh, $target_dir);
my @contributors = sort readdir $dh;
foreach my $contributor (@contributors) {
  next if $contributor eq '.' or $contributor eq '..';

  my $contrib_path = catfile($target_dir, $contributor);
  next unless -d $contrib_path;
  
  opendir(my $ch, $contrib_path);
  my @files = grep { $_ ne '.' && $_ ne '..' } sort readdir $ch;

  say $contributor if defined $lang && grep { /$lang/i } @files;

  # template is just a readme, plus . and ..
  next if grep { -d catfile($contrib_path, $_) } @files;
  next unless scalar @files == 1;
  
  remove_tree($contrib_path, {
    verbose => 1,
    safe => 1,
  });

  closedir $ch;
}
closedir $dh;
