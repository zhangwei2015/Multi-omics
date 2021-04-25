#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use FindBin qw($Bin $Script);


die "perl $0 <in.infile><feature.type><dir.Rscript>\n" unless(@ARGV==3);
my $in_file = $ARGV[0];
my $feature_t_f = $ARGV[1];
my $Rscript = $ARGV[2];


#  read the variable type file
my %Type;
#open I, "/ldfssz1/ST_HEALTH/Immune_And_Health_Lab/PopImmDiv_P17Z10200N0271/zhangwei/Omics_project/data_v1.58/Health_variable_info.txt.new" or die;
open I, "$feature_t_f" or die;
<I>;
while(<I>)
{
	chomp;
	my @line = split;
	$Type{$line[0]} = $line[1];
}
close I;

#  read data
#open I, "combined_data17_v1.58_male_uniq.csv" or die;
open I, "$in_file" or die;
my %All;
my %Overlap_n;
while(<I>)
{
	chomp;
	my @line = split;
	my $id = "$line[0]\t$line[1]\t$line[2]";
	$All{$id} = $line[4];
	$Overlap_n{$id} = $line[3];
}

close I;
# further processing
for my $v (keys %All)
{
	next if($Overlap_n{$v} < 150);
	my ($V1,$V2,$gender) = split /\t/,$v;
	my @data = split /,/,$All{$v};
	my %d1;
	my %d2;
	my @D1;
	my @D2;
	my @D3;
	for(my $i=0;$i<=$#data;$i++){
		my ($t1,$t2,$t3) = split /:/,$data[$i];
		$d1{$t1}++;
		$d2{$t2}++;
		$D1[$i] = $t1;
		$D2[$i] = $t2;
		$D3[$i] = $t3;
	}

	my ($v1_type_new,$v2_type_new);
	$v1_type_new = &Judge_type($Type{$V1},\@D1,%d1);
	$v2_type_new = &Judge_type($Type{$V2},\@D2,%d2);
	next if($v1_type_new eq "single" or $v2_type_new eq "single");# Binary discrete variable have changed to single category
	
	my @data_new;
	for(my $i=0;$i<=$#data;$i++){
		push @data_new, "$D1[$i]:$D2[$i]:$D3[$i]" if($D1[$i] ne "NA" && $D2[$i] ne "NA");
	}
	my $tmp_new = join ",", @data_new;
	print "$V1,$V2,$gender,$v1_type_new:$v2_type_new,$tmp_new\n";
}

# determine the new type for each variable
sub Judge_type
{
	my ($t,$d,%count) = @_;
	if($t eq "Continuous_variable")# for continuous varaible
	{
		if(exists $count{0} && $count{0}/scalar(@$d) > 0.2)# continuous varaible will change to discrete variable
		{
			#split_group($d);
			my $data_min = (sort{$a<=>$b} @$d)[0];
			my $add = -$data_min+1e-10;
			my %count_new;
			for(my $i=0;$i<scalar(@$d);$i++){
				$$d[$i] += $add;
				$count_new{$$d[$i]}++;
			}
			my @new_d = sort{$a<=>$b} @$d;

			my $new_type_num = 0;
			my %new_flag;
			
			# consider plus numbers
			my $max_m=$new_d[-50];
			my $min_m=$new_d[49];
#			for(my $i=1;$i<=50;$i++){
#				$max_m += $new_d[-$i];
#				$min_m += $new_d[$i-1];
#			}
#			$max_m = $max_m/50;
#			$min_m = $min_m/50;
#			my $max_m = ($new_d[-1]+$new_d[-2]+$new_d[-3]+$new_d[-4]+$new_d[-5])/5;
#			my $min_m = ($new_d[0]+$new_d[1]+$new_d[2]+$new_d[3]+$new_d[4])/5;
			my $inter_each;
			my $k;
			for($k = 2;$k<scalar(@$d)/20; $k++)
			{
				my %h;
				$inter_each = ($max_m-$min_m)/$k;
				for(keys %count_new){
					if($_>= $min_m+$inter_each*($k-1)){
						$h{$k-1} += $count_new{$_};
					}elsif($_ < $min_m+$inter_each){
						$h{0} += $count_new{$_};
					}else{
						$h{int(($_-$min_m)/$inter_each)} += $count_new{$_};
					}
				}
				my $f_n = 0;
				for(my $l=0;$l<=$k-1;$l++){
					if(!exists $h{$l} || $h{$l} <20){
						$f_n++;
						last;
					}
				}
				last if($f_n == 1);

			}
			
			if($k-1 == 1){
				return "single";
			}
			
			$inter_each = ($max_m-$min_m)/($k-1);
			$new_type_num = $k-1;
				
			for(my $i=0;$i<=$#new_d; $i++){
				if($new_d[$i] >= $min_m+$inter_each*($k-2)){
					$new_flag{$new_d[$i]} = $k-2;
				}elsif($new_d[$i] < $min_m+$inter_each){
					$new_flag{$new_d[$i]} = 0;
				}else{
					$new_flag{$new_d[$i]} = int(($new_d[$i]-$min_m)/$inter_each);
				}
			}
			# update the array
			for(my $j=0;$j<=$#new_d;$j++){
				$$d[$j] = $new_flag{$$d[$j]};
			}

			# judge type
			if($new_type_num  == 2){
				return "Binary_discrete_variable";
			}else{
				return "Multiple_ordered_discrete_variable";
			}
		}
		else
		{
			#Inverse-rank normal transformation
			open P,">$in_file.tmp.variable.for.norm" or die;
			print P "@$d\n";
			close P;
			`$Rscript $Bin/irnt.R $in_file.tmp.variable.for.norm`;
#			print "@$d\n";
			open P, "$in_file.tmp.variable.for.norm.IRNT" or die;
			my $norm_d = <P>;
			chomp($norm_d);
			@$d = split /\s+/,$norm_d;
			close P;
			return $t;
		}
	}else# for discrete varaible
	{
		my $flag = scalar(keys %count);
		for my $n(keys %count)
		{
			if($count{$n} < 20)# the number of sample for the category is too small and filtered
			{
				for(my $i=0;$i<scalar(@$d);$i++){
					$$d[$i] = "NA" if($$d[$i] eq $n);
				}
				$flag--;
			}
		}
		if($flag <= 1)# discrete variable have changed to single category
		{	
			return "single";
		}elsif($flag == 2){
			return "Binary_discrete_variable";
		}elsif($flag >2){
			return $t;
		}
		
	}
}

