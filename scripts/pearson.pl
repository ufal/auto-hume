#!/usr/bin/perl
# calculates pearson correlation for two columns of numbers

use strict;
use warnings;

my $sumxy = 0;
my $sumx = 0;
my $sumx2 = 0;
my $sumy = 0;
my $sumy2 = 0;
my $n = 0;

while (<>) {
  $n ++;
  chomp;
  my ($x, $y) = split /\t/;
  $sumx += $x;
  $sumy += $y;
  $sumxy += $x*$y;
  $sumx2 += $x**2;
  $sumy2 += $y**2;
};

print STDOUT ($n*$sumxy - $sumx*$sumy)
    / sqrt($n*$sumx2 - $sumx**2)
    / sqrt($n*$sumy2 - $sumy**2);
print "\n";
