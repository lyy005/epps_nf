#!usr/bin/perl -w
use strict;

die "Usage: perl $0 [.fa] [out.fa]\n" unless (@ARGV == 2);
open (FA, $ARGV[0]) or die "$ARGV[0] $!\n";
open OUT, ">$ARGV[1]" or die "$ARGV[1] $!\n";
open OUT2, ">$ARGV[1].cast" or die "$ARGV[1].cast $!\n";
$/=">";
my (%abund, %name, %collapse);
<FA>;
while(<FA>){
	chomp;
	my @line = split /\n+/;	
	my $name = shift @line;
	my $seq = join "", @line;

	my $length = length ($seq);
	next if ($length <32);

	if($abund{$seq}){
		$abund{$seq} ++;
		$collapse{$seq} .= $name."\n";
	}else{
		$abund{$seq} = 1;
		$name{$seq} = $name;
		$collapse{$seq} = $name."\n";
	}
}

foreach my $k (sort keys %abund){
	print OUT ">$name{$k};size=$abund{$k};\n$k\n";
	print OUT2 ">$name{$k};size=$abund{$k}\n$collapse{$k}";
	
}
print "Unique DONE!\n";
