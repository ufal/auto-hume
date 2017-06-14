#!/usr/bin/env perl

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";

use strict;
use warnings;
use Getopt::Long;
use List::Uniq;
use List::Util qw(min max);


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
        $ref_words[$sent_num][0] = "";
        $sent_num++;
    }
}
close CONLLU;
print STDERR "Trees sentences: $sent_num\n";

sub get_descendants {
    my ($s, $w, $ch) = @_;
    my @descendants = ($w);
    if (defined $ch->[$s][$w]) {
        foreach my $c (@{$ch->[$s][$w]}) {
            push @descendants, get_descendants($s, $c, $ch);
            # push @descendants, get_children_and_self($s, $c, $ch);
        }
    }
    return @descendants;
}

sub get_children_and_self {
    my ($s, $w, $ch) = @_;
    my @descendants = ($w);
    # my @descendants = ();
    if (defined $ch->[$s][$w]) {
        foreach my $c (@{$ch->[$s][$w]}) {
            push @descendants, $c;
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
    $alignment[$sent_num][0] = 0;
    $sent_num++;
}
close ALI;
print STDERR "Alignment sentences: $sent_num\n";

$sent_num = 0;
my @tgt_words;
my @trans_children;
open(TRANSLATION, "<:utf8", $TRANSLATION_FILENAME) or die;
while(<TRANSLATION>) {
    chomp;
    if ($_ =~ /^\d/) {
        my @items = split(/\t/, $_);
        push @{$trans_children[$sent_num][$items[6]]}, $items[0];
        $tgt_words[$sent_num][$items[0]] = $items[1];
    }
    else {
        $tgt_words[$sent_num][0] = "";
        $sent_num++;
    }
}

print STDERR "Translation sentences: $sent_num\n";

foreach my $s (0 .. $sent_num - 1) {
    # first print the whole sentences 
    my $weight = scalar(@{$ref_words[$s]}) + scalar(@{$tgt_words[$s]});
    # my $weight = 1;
    print "$s\t$weight\t";
    print join(" ", @{$ref_words[$s]});
    print "\t";
    print join(" ", @{$tgt_words[$s]});
    print "\n";
    # then print interesting subparts
    #foreach my $w (0 .. $#{$ref_words[$s]}) {
        # my $w = 0; {
        #my @tgt_w;
        #my @ref_w;
        #foreach my $d (get_descendants($s, $w, \@children)) {
        #    if (defined $alignment[$s][$d]) {
        #        push @ref_w, $d;
        #        push @tgt_w, $alignment[$s][$d];
        #    }
        #}

    foreach my $W (get_children_and_self($s, 0, \@children)) { # root children
    foreach my $w (get_children_and_self($s, $W, \@children)) { # root grand-children


        # my $aligned_root = $alignment[$s][$w];
        my @ref_w = get_descendants($s, $w, \@children);
        # my @ref_w = get_children_and_self($s, $w, \@children);
        #{
        #    my $span_start = min @ref_w;
        #    my $span_end = max @ref_w;
        #    @ref_w = ($span_start..$span_end);
        #}
        my @ref_subtree = map{$ref_words[$s][$_]} List::Uniq::uniq(sort {$a <=> $b} @ref_w);
        #next if @ref_subtree <= 1;

        my @tgt_w;
        foreach my $r (@ref_w) {
            if (defined $alignment[$s][$r]) {
                push @tgt_w, $alignment[$s][$r];
            }
        }
        if (@tgt_w) {
            my $span_start = min @tgt_w;
            my $span_end = max @tgt_w;
            @tgt_w = ($span_start..$span_end);
        } else {
            @tgt_w = (0);
        }
        my @tgt_subtree = map{$tgt_words[$s][$_]} List::Uniq::uniq(sort {$a <=> $b} @tgt_w);
        

        # $aligned_root always defined for uni-src alignment
        #my @tgt_subtree = ("");
        #if (defined $aligned_root) {
        #    my @tgt_w = get_descendants($s, $aligned_root, \@trans_children);
        #    # my @tgt_w = get_children_and_self($s, $aligned_root, \@trans_children);
        #    @tgt_subtree = map{$tgt_words[$s][$_]} List::Uniq::uniq(sort {$a <=> $b} @tgt_w);
        #}

        my $weight = scalar(@ref_subtree) + scalar(@tgt_subtree);
        # my $weight = 0.1;
        print "$s\t$weight\t";
        print join(" ", @ref_subtree);
        print "\t";
        print join(" ", @tgt_subtree);
        print "\n";
    }
    }
}
