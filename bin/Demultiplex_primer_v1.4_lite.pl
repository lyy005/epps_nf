#!usr/bin/perl -w
use strict;

die "Usage: perl $0 [1.fq] [2.fq] [primer_set.fas] [output forward] [output reverse] [report]\n" unless (@ARGV == 6);

my (%hash, $line1, $line2);
open (PRI, $ARGV[2]) or die "$ARGV[2] $!\n";
open (DE, ">$ARGV[5]") or die "$ARGV[4] $!\n";

open (OT1, ">$ARGV[3]") or die "$ARGV[4] $!\n";
open (OT2, ">$ARGV[4]") or die "$ARGV[4] $!\n";
$/ = '>';
<PRI>;
while(<PRI>){
	chomp;
	my @line = split /\n+/;

# To remove weird linebreaks
	$line[0] =~ s/\s//g;
	$line[1] =~ s/\s//g;

	my @id = split /\_/, $line[0];
	$hash{$id[0]}{$id[1]} = $line[1];

}
close PRI;
$/ = "\n";

#print "Primers\t1.fastq\t2.fastq\tpaired_reads\n";
print DE "Primers\t1.fastq\t2.fastq\tpaired_reads\n";

foreach my $k (sort keys %hash){
	if ($ARGV[0] =~ /gz$/){
		open (FQ1, "gzip -dc $ARGV[0] |") or die "$ARGV[0] $!\n";
	}else{
		open (FQ1, $ARGV[0]) or die "$ARGV[0] $!\n";
	}

	if ($ARGV[1] =~ /gz$/){
		open (FQ2, "gzip -dc $ARGV[1] |") or die "$ARGV[1] $!\n";
	}else{
		open (FQ2, $ARGV[1]) or die "$ARGV[1] $!\n";
	}

print "$k\t";
print DE "$k\t";

my ($fq1_F, $fq1_R, $fq2_F, $fq2_R);
my $fq1 = 0;
my $fq2 = 0;
my $pd = 0;

	while(my $forward1 = <FQ1>){
		my $forward2 = <FQ1>;
		my $forward3 = <FQ1>;
		my $forward4 = <FQ1>;

		my $reverse1 = <FQ2>;
		my $reverse2 = <FQ2>;
		my $reverse3 = <FQ2>;
		my $reverse4 = <FQ2>;

my $F1 = 0;
my $R1 = 0;
my $F2 = 0;
my $R2 = 0;		

		if($forward2 =~ /^(\w{0,5})$hash{$k}{F}/){
			$forward2 = substr($forward2, $+[0], 1000);
			$forward4 = substr($forward4, $+[0], 1000);
			$F1 = 1;
#print "###$k\t$1###\n";

$fq1_F ++;
$fq1 ++;
			print LG "$k\_F\t$forward1";
		}

		if($reverse2 =~ /^(\w{0,5})$hash{$k}{R}/){
			$reverse2 = substr($reverse2, $+[0], 1000);
			$reverse4 = substr($reverse4, $+[0], 1000);
			$R1 = 1;
# print "$1\n";
$fq2_R ++;
$fq2 ++;
			print LG "$k\_R\t$reverse1";
		}

		if(($F1 == 1)&&($R1 == 1)&&(length($forward2) > 10)&&(length($reverse2) > 10)){
			print OT1 "$forward1$forward2$forward3$forward4";
			print OT2 "$reverse1$reverse2$reverse3$reverse4";
$pd ++;
		}
		
		if($forward2 =~ /^(\w{0,5})$hash{$k}{R}/){
			$forward2 = substr($forward2, $+[0], 1000);
			$forward4 = substr($forward4, $+[0], 1000);
			$F2 = 1;
$fq1_R ++;
$fq1 ++;
			print LG "$k\_R\t$forward1";
		}

		if($reverse2 =~ /^(\w{0,5})$hash{$k}{F}/){
			my $end = $+[0] + 1;
			$reverse2 = substr($reverse2, $+[0], 1000);
			$reverse4 = substr($reverse4, $+[0], 1000);
			$R2 = 1;
$fq2_F ++;
$fq2 ++;
			print LG "$k\_F\t$reverse1";
		}

		if(($F2 == 1)&&($R2 == 1)&&(length($forward2) > 10)&&(length($reverse2) > 10)){
$pd ++;			
			print OT1 "$forward1$reverse2$reverse3$reverse4";
			print OT2 "$reverse1$forward2$forward3$forward4";
		}
	}
#print "$ARGV[3]_$k\t1.fq\t$fq1_F\t$fq1_R\n$ARGV[3]_$k\t2.fq\t$fq2_F\t$fq2_R\n";
#$line1 .= "1.fastq: Number of reads:".$fq1."\t"."paired reads:".$pd."\t";
#$line2 .= "2.fastq: Number of reads:".$fq2."\t"."paired reads:".$pd."\t";

# print "$fq1\t$fq2\t$pd\n";
print DE "$fq1\t$fq2\t$pd\n";

	close OT1;
	close OT2;


}

#print "$line1\n$line2\n";
close FQ1;
close FQ2;
