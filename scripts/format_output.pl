#!/usr/bin/perl

use strict;
use warnings;

binmode STDOUT, ":utf8";

my ($metric_name, $lang_pair, $test_set, $system, $scores_file, $ensemble, $available) = @ARGV;
open(SCORES, "<:utf8", $scores_file) or die;

my $segment_number = 0;
while(<SCORES>){
    chomp;
    $segment_number++;
    print "$metric_name\t$lang_pair\t$test_set\t$system\t$segment_number\t$_\t$ensemble\t$available\n";
}
close SCORES;


