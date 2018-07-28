#!usr/bin/perl -w
use strict;

die "Usage: perl $0 [uc file] [Output]\n" unless (@ARGV == 2);
open (IN, $ARGV[0]) or die "$ARGV[0] $!\n";
open OUT, ">$ARGV[1]" or die "$ARGV[1] $!\n";

my %hash;
my %sample;
while(<IN>){
	chomp;
	my @line = split/\s+/;
	my @sample = split /\_/, $line[-2];

pop @sample;
my $sample_id = join "\_", @sample;

	$sample{$sample_id} ++;
	if($line[-1] eq "*"){
		next;
	}else{
#		my @otu = split /\_/, $line[-1];
		$line[-1] =~ s/otu//;
		$hash{$line[-1]}{$sample_id} ++;
	}
}

my @samples = sort keys %sample;
my $header = join "\t", @samples;
print OUT "\t$header\n";

foreach my $k (sort {$a<=>$b} keys %hash){
	print OUT "otu$k\t";
#	foreach my $l (sort keys %{$hash{$k}}){
	foreach my $l (@samples){
		if($hash{$k}{$l}){
			print OUT "$hash{$k}{$l}\t";
		}else{
			print OUT "0\t";
		}
	}
	print OUT "\n";
}
print "DONE!";
