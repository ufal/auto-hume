#!/usr/bin/env perl

use strict;
use warnings;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";

my $current_sent = 0;
my $sum_chrF = 0;
my $count_chrF = 0;

while(<>) {
    chomp;
    my ($sent_num, $weight, $ref, $trans, $chrF) = split (/\t/, $_);
    if ($sent_num == $current_sent) {
        $sum_chrF += $weight * $chrF;
        $count_chrF += $weight;
    }
    else {
        my $score = $sum_chrF / $count_chrF;
        print "$score\n";
        $sum_chrF = 0;
        $count_chrF = 0;
        $current_sent = $sent_num;
    }
}
my $score = $sum_chrF / $count_chrF;
print "$score\n";
