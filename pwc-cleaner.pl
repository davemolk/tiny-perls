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
  opendir(my $ch, catfile($target_dir, $contributor));
  my @files = sort readdir $ch;
  say $contributor if defined $lang && grep { /$lang/i } @files;

  # template is just a readme, plus . and ..
  next unless scalar @files == 3;
  next if grep { -d $_ } @files;
  
  my $full_path = catfile($target_dir, $contributor);
  
  remove_tree($full_path, {
    verbose => 1,
    safe => 1,
  });

  closedir $ch;
}
closedir $dh;
