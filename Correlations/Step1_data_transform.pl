#!/usr/bin/perl -w
use strict;
use Data::Dumper;



die "perl $0 <in.infile>\n" unless(@ARGV==1);
my $in_file = $ARGV[0];


#  read data
#open I, "combined_data17_v1.58_male_uniq.csv" or die;
open I, "$in_file" or die;

my $fir = <I>;
chomp($fir);
my @Tit = split /,/,$fir;
my %Head;
for(my $i=3; $i<=$#Tit; $i++)
{
        $Tit[$i] =~ s/\s+/_/g;
        my $group = (split /\./,$Tit[$i])[0];
        $Head{$i} = [($group,$Tit[$i])];
#	$Head{$i} = $Tit[$i];        
}

#   store all data in the hash %All
my %All;
my %Overlap_n;
while(<I>)
{
	chomp;
	my @line = split /,/,$_;
	for(my $i=3;$i<=$#line;$i++)
	{
		for(my $j=$i+1;$j<=$#line;$j++)
		{
			next if($Head{$i}->[0] eq $Head{$j}->[0]);
			if($line[$i] ne "NA" && $line[$j] ne "NA"){
				if(exists($All{"$Head{$i}->[1]\t$Head{$j}->[1]\t$line[1]"})){
					$All{"$Head{$i}->[1]\t$Head{$j}->[1]\t$line[1]"} .= ",$line[$i]:$line[$j]:$line[2]";
				}else{
					$All{"$Head{$i}->[1]\t$Head{$j}->[1]\t$line[1]"} = "$line[$i]:$line[$j]:$line[2]";
				}
				$Overlap_n{"$Head{$i}->[1]\t$Head{$j}->[1]\t$line[1]"}++;
			}
		}
	}	
}
close I;
#print Dumper(\%All);

for my $v(keys %All)
{
	print "$v\t$Overlap_n{$v}\t$All{$v}\n";		
}

