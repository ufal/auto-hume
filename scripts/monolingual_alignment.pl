#!/usr/bin/env perl

use strict;
use warnings;
use Text::JaroWinkler;
use List::Util qw(min max);

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
binmode STDIN, ":utf8";

my @form;
my @tag;

my $type = 'uni-src';

foreach my $f (0, 1) {
    open (CONLL, "<:utf8", $ARGV[$f]) or die;
    my $sent_count = 0;
    while (<CONLL>) {
        chomp;
        if ($_ =~ /^\d+\t/) {
            my @items = split /\t/, $_;
            $form[$sent_count][$f][$items[0]-1] = $items[1];
            $tag[$sent_count][$f][$items[0]-1] = $items[3];
        }
        elsif ($_ =~ /^\s*$/) {
            $sent_count++;
        }
    }
    close CONLL;
}

foreach my $s (0 .. $#form) {
    my @alignment;
    my %candidate_scores;
    foreach my $w0 (0 .. $#{$form[$s][0]}) {
        foreach my $w1 (0 .. $#{$form[$s][1]}) {
            my $jarowinkler = Text::JaroWinkler::strcmp95( lc($form[$s][0][$w0]), lc($form[$s][1][$w1]), 20 ) - 0.6;
            $jarowinkler = 0 if $jarowinkler < 0;
            my $equal_tags = $tag[$s][0][$w0] eq $tag[$s][1][$w1] ? 1 : 0;
            my $relpos = 1 - abs($w0 / $#{$form[$s][0]} - $w1 / $#{$form[$s][1]});
            $candidate_scores{"$w0-$w1"} = $jarowinkler * 8 + $equal_tags * 3 + $relpos * 3;
        }
    }
    if ($type eq 'intersection') {
        my @sorted_candidates = sort{$candidate_scores{$b} <=> $candidate_scores{$a}} keys %candidate_scores;
        my $links_to_do = min($#{$form[$s][0]}, $#{$form[$s][1]}) + 1;
        my @used;
        foreach my $c (@sorted_candidates) {
            last if $candidate_scores{$c} < 4; 
            my ($w0, $w1) = split /-/, $c;
            if (!$used[0][$w0] && !$used[1][$w1]) {
                push @alignment, $c;
                $links_to_do--;
                $used[0][$w0] = 1;
                $used[1][$w1] = 1;
            }
            last if !$links_to_do;
        }
    }
    elsif ($type eq 'union') {
        my %aligned;
        foreach my $w0 (0 .. $#{$form[$s][0]}) {
            my $best_ali = "";
            my $best_score = 0;
            foreach my $w1 (0 .. $#{$form[$s][1]}) {
                if ($candidate_scores{"$w0-$w1"} > $best_score) {
                    $best_ali = "$w0-$w1";
                    $best_score = $candidate_scores{"$w0-$w1"};
                }
            }
            $aligned{$best_ali} = 1;
        }
        foreach my $w1 (0 .. $#{$form[$s][1]}) {
            my $best_ali = "";
            my $best_score = 0;
            foreach my $w0 (0 .. $#{$form[$s][0]}) {
                if ($candidate_scores{"$w0-$w1"} > $best_score) {
                    $best_ali = "$w0-$w1";
                    $best_score = $candidate_scores{"$w0-$w1"};
                }
            }
            $aligned{$best_ali} = 1;
        }
        @alignment = keys %aligned;
    }
    elsif ($type eq 'uni-src') {
        my %aligned;
        foreach my $w0 (0 .. $#{$form[$s][0]}) {
            my $best_ali = "";
            my $best_score = 0;
            foreach my $w1 (0 .. $#{$form[$s][1]}) {
                if ($candidate_scores{"$w0-$w1"} > $best_score) {
                    $best_ali = "$w0-$w1";
                    $best_score = $candidate_scores{"$w0-$w1"};
                }
            }
            $aligned{$best_ali} = 1;
        }
        @alignment = keys %aligned;
    }
    print join " ", @alignment;
    print "\n";
}
