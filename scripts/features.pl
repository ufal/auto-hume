#!/usr/bin/env perl

use strict;
use warnings;
use List::Util qw(min max);
use utf8;

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
binmode STDIN, ":utf8";

my @form;
my @lemma;
my @tag;
my @feat;
my @formeme;
my @par;
my @ali;

foreach my $f (0, 1) {
    open (CONLL, "<:utf8", $ARGV[$f]) or die;
    my $sent_count = 0;
    while (<CONLL>) {
        chomp;
        if ($_ =~ /^\d/) {
            my @items = split /\t/, $_;
            $form[$sent_count][$f][$items[0]-1] = $items[1];
            $lemma[$sent_count][$f][$items[0]-1] = $items[2] eq '_' ? lc($items[1]) : $items[2];
            $tag[$sent_count][$f][$items[0]-1] = $items[3];
            $par[$sent_count][$f][$items[0]-1] = $items[6];
            if ($items[5] =~ /=/) {
                my @features = split /\|/, $items[5];
                foreach my $feature (@features) {
                    my ($name, $value) = split /=/, $feature;
                    $feat[$sent_count][$f][$items[0]-1]{$name} = $value;
                }
            }
        }
        else {
            $sent_count++;
        }
    }
    close CONLL;
}
open (ALIGNMENT, "<:utf8", $ARGV[2]) or die;
my $sent_count = 0;
while(<ALIGNMENT>) {
    chomp;
    @{$ali[$sent_count]} = split /\s/, $_;
    $sent_count++;
}
close ALIGNMENT;

foreach my $s (0 .. $#form) {
    foreach my $f (0, 1) {
        foreach my $w (0 .. $#{$form[$s][$f]}) {
            my $formeme;
            if ($tag[$s][$f][$w] =~ /^(NOUN|PROPN)$/) {
                $formeme = 'n:';
                my @formeme_parts;
                foreach my $wp (0 .. $#{$form[$s][$f]}) {
                    if ($par[$s][$f][$wp] == $w && $tag[$s][$f][$wp] eq 'ADP') {
                        push @formeme_parts, $lemma[$s][$f][$wp];
                    }
                    if ($wp == $w) {
                        push @formeme_parts, ($feat[$s][$f][$w]{'Case'} || 'X');
                    }
                }
                $formeme .= join("+", @formeme_parts);
            }
            elsif ($tag[$s][$f][$w] eq 'VERB') {
                my $verbform = 
                $formeme = 'v:' . ($feat[$s][$f][$w]{'VerbForm'} || '');
            }
            elsif ($tag[$s][$f][$w] eq 'ADJ') {
                $formeme = 'adj:';
            }
            elsif ($tag[$s][$f][$w] eq 'ADV') {
                $formeme = 'adv:';
            }
            #elsif ($tag[$s][$f][$w] eq 'PRON') {
            #    $formeme = 'n:';
            #}
            $formeme[$s][$f][$w] = ($formeme || undef);
            print STDERR "$formeme " if $formeme;
        }
    }
}

#print "eq_forms\teq_lemmas\teq_cont_forms\teq_cont_lemmas\teq_formemes\teq_tense\teq_number\n";
my $null_value = 1;

foreach my $s (0 .. $#form) {
    my $total = 0;
    my $total_content = 0;
    my $eq_forms = 0;
    my $eq_content_forms = 0;
    my $eq_lemmas = 0;
    my $eq_content_lemmas = 0;
    my $eq_formemes = 0;
    my $total_number = 0;
    my $eq_number = 0;
    my $total_tense = 0;
    my $eq_tense = 0;
    foreach my $link (@{$ali[$s]}) {
        my ($w0, $w1) = split /-/, $link;
        $total++;
        $eq_forms++ if lc($form[$s][0][$w0]) eq lc($form[$s][1][$w1]);
        $eq_lemmas++ if $lemma[$s][0][$w0] eq $lemma[$s][1][$w1];
        if ($tag[$s][0][$w0] =~ /^(NOUN|PROPN|ADJ|VERB|ADV)$/ && $tag[$s][1][$w1] =~ /^(NOUN|PROPN|ADJ|VERB|ADV)$/) {
            $total_content++;
            $eq_content_forms++ if lc($form[$s][0][$w0]) eq lc($form[$s][1][$w1]);
            $eq_content_lemmas++ if $lemma[$s][0][$w0] eq $lemma[$s][1][$w1];
            $eq_formemes++ if (defined $formeme[$s][0][$w0] && defined $formeme[$s][1][$w1] && $formeme[$s][0][$w0] eq $formeme[$s][1][$w1]);
            if (defined $feat[$s][0][$w0]{'Number'} && defined $feat[$s][1][$w1]{'Number'}) {
                $total_number++;
                $eq_number++ if $feat[$s][0][$w0]{'Number'} eq $feat[$s][1][$w1]{'Number'};
            }
            if (defined $feat[$s][0][$w0]{'Tense'} && defined $feat[$s][1][$w1]{'Tense'}) {
                $total_tense++;
                $eq_tense++ if $feat[$s][0][$w0]{'Tense'} eq $feat[$s][1][$w1]{'Tense'};
            }
        }
    }
    printf "%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\n",
        $total ? ($eq_forms/($total + 1)) : $null_value,
        $total ? ($eq_lemmas/($total + 1)) : $null_value,
        $total_content ? ($eq_content_forms/($total_content + 1)) : $null_value,
        $total_content ? ($eq_content_lemmas/($total_content + 1)) : $null_value,
        $total_content ? ($eq_formemes/($total_content + 1)) : $null_value,
        $total_tense ? ($eq_tense/($total_tense + 1)) : $null_value,
        $total_number ? ($eq_number/($total_number + 1)) : $null_value;
}

