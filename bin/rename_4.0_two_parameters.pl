#!usr/bin/perl -w
use strict;

die "Usage: perl $0 [.fa] [out.fa]\n" unless (@ARGV == 2);
open (FA, $ARGV[0]) or die "$ARGV[0] $!\n";
open OUT, ">$ARGV[1]" or die "$ARGV[2] $!\n";
open CAST, ">$ARGV[1].cast" or die "$ARGV[2] $!\n";
my $pre = $ARGV[0];
my @pre = split /\./, $pre;
$pre = $pre[0];

$/=">";
my $seq;
my @raw;
my $c;
if($pre eq 0){
        $c = "00000000000000000001";
        my $null = <FA>;
        while(<FA>){
                chomp;
		s/\r//g;
                @raw = split /\n/;
                my $name = shift @raw;
                $seq = join "", @raw;
                print OUT ">$c\n$seq\n";
                print CAST "$name\t$c\n";
                $c++;
        }
}else{
        $c = 1;
        my $null = <FA>;
        while(<FA>){
                chomp;
		s/\r//g;
                @raw = split /\n/;
                my $name = shift @raw;
                $seq = join "", @raw;
		$seq =~ tr/[a-z]/[A-Z]/;
                print OUT ">$pre\_$c\n$seq\n";
                print CAST "$name\t$pre\_$c\n";
                $c++;
        }
}

close FA;
close OUT;
close CAST;
print "DONE!";
