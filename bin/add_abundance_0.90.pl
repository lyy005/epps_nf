#!usr/bin/perl -w
use strict;

die "Usage: perl $0 [.fa] [.uc] [length cutoff Min:Max] [out.fa]\n" unless (@ARGV == 4);
open (FA, $ARGV[0]) or die "$ARGV[0] $!\n";
open (AB, $ARGV[1]) or die "$ARGV[1] $!\n";
open OT, ">$ARGV[3]" or die "$ARGV[3] $!\n";

my $len = $ARGV[2];
my @len = split /\:/, $len;
my $min = $len[0];
my $max = $len[1];

my %hash;
while(<AB>){
	chomp;
	my @line = split /\s+/;
	if($line[-1] ne "*"){
		$hash{$line[-1]} ++;
	}
}
close AB;
#foreach my $k (sort {$hash{$b}<=>$hash{$a}} keys %hash){
#	print "$k\t$hash{$k}\n";
#}


$/ = ">";
<FA>;

if ($ARGV[2] eq "NA"){
	while(<FA>){
		chomp;
		my @line = split /\n+/;
		my $name = shift @line;
		my $seq = join "", @line;
		if($hash{$name}){
			print OT ">$name;size=$hash{$name};\n$seq\n";
		}else{
			print "Abundance not found: $name\n";
		}
	}
}else{
	while(<FA>){
		chomp;
		my @line = split /\n+/;
		my $name = shift @line;
		my $seq = join "", @line;
		my $length = length $seq; 
		if(($length >= $min)&&($length <= $max)){
			print OT ">$name;size=$hash{$name};\n$seq\n";
		}else{
			print ">$name;size=$hash{$name};\t$length is removed\n";
		}
	}
}

close FA;
close OT;
print "DONE!\n";
