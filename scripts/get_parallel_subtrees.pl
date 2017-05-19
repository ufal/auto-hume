#!/usr/bin/env perl

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";

use strict;
use warnings;
use Getopt::Long;
use List::Uniq;


my $REF_TREES_FILENAME = undef;
my $ALIGNMENT_FILENAME = undef;
my $TRANSLATION_FILENAME = undef;

GetOptions ("ref-trees=s" => \$REF_TREES_FILENAME,
            "alignment=s" => \$ALIGNMENT_FILENAME,
            "translation=s" => \$TRANSLATION_FILENAME
           ) or die("Error in command line arguments\n");

my @children;
my @ref_words;
my $sent_num = 0;

open(CONLLU, "<:utf8", $REF_TREES_FILENAME) or die;
while(<CONLLU>) {
    chomp;
    if ($_ =~ /^\d/) {
        my @items = split(/\t/, $_);
        push @{$children[$sent_num][$items[6]]}, $items[0];
        $ref_words[$sent_num][$items[0]] = $items[1];
    }
    else {
        $sent_num++;
    }
}
close CONLLU;
print STDERR "Trees sentences: $sent_num\n";

sub get_descendants {
    my ($s, $w) = @_;
    my @descendants = ($w);
    if (defined $children[$s][$w]) {
        foreach my $c (@{$children[$s][$w]}) {
            push @descendants, get_descendants($s, $c);
        }
    }
    return @descendants;
}

$sent_num = 0;
my @alignment;
open(ALI, "<:utf8", $ALIGNMENT_FILENAME) or die;
while(<ALI>) {
    chomp;
    my @pairs = split(/\s/, $_);
    foreach my $pair (@pairs) {
        my ($ref, $tgt) = split(/-/, $pair);
        $alignment[$sent_num][$ref + 1] = $tgt + 1;
    }
    $sent_num++;
}
close ALI;
print STDERR "Alignment sentences: $sent_num\n";

$sent_num = 0;
my @tgt_words;
open(TRANSLATION, "<:utf8", $TRANSLATION_FILENAME) or die;
while(<TRANSLATION>) {
    chomp;
    my @words = split(/\s/, $_);
    unshift @words, "";
    $tgt_words[$sent_num] = \@words;
    $sent_num++;
}
print STDERR "Translation sentences: $sent_num\n";

foreach my $s (0 .. $sent_num - 1) {
    foreach my $w (0 .. $#{$ref_words[$s]}) {
        my @tgt_w;
        my @ref_w;
        foreach my $d (get_descendants($s, $w)) {
            if (defined $alignment[$s][$d]) {
                push @ref_w, $d;
                push @tgt_w, $alignment[$s][$d];
            }
        }
        my @ref_subtree = map{$ref_words[$s][$_]} List::Uniq::uniq(sort {$a <=> $b} @ref_w);
        my @tgt_subtree = map{$tgt_words[$s][$_]} List::Uniq::uniq(sort {$a <=> $b} @tgt_w);
        my $weight = scalar(@ref_subtree) + scalar(@tgt_subtree);
        print "$s\t$weight\t";
        print join(" ", @ref_subtree);
        print "\t";
        print join(" ", @tgt_subtree);
        print "\n";
    }
}
