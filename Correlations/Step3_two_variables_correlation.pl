#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin $Script);

die "perl $0 <in><out><dir.Rscript>\n" unless(@ARGV==3);
my $in_file = $ARGV[0];
my $out_file = $ARGV[1];
my $Rscript = $ARGV[2];

open O, ">$out_file" or die;


open I, "$in_file" or die;
my $Rand_num = 501;
my $select_num = 1000;

my $flag = 0;
while(<I>)
{
	chomp;
	$flag++;
	my @line = split /,/,$_;
	my $V1 = shift @line;
	my $V2 = shift @line;
	my $gender = shift @line;
	my ($V1_type, $V2_type) = split /:/,$line[0];
	shift @line;
	my $tmp_f = "$in_file.data.rand";
	if($V1_type eq "Continuous_variable" && $V2_type eq "Continuous_variable"){
		&Random_select_repeat($tmp_f,@line);
	}else{
		my $v1_t =0;
		my $v2_t =0;
		$v1_t = 2 if($V1_type eq "Binary_discrete_variable");
		$v1_t = 3 if($V1_type eq "Multiple_ordered_discrete_variable" || $V1_type eq "Multiple_unordered_discrete_variable");

		$v2_t = 2 if($V2_type eq "Binary_discrete_variable");
		$v2_t = 3 if($V2_type eq "Multiple_ordered_discrete_variable" || $V2_type eq "Multiple_unordered_discrete_variable");

		&Random_select_repeat_discrete($tmp_f,$v1_t,$v2_t,@line);
	}


	my $type1 = "TRUE";  
	my $type2 = "FALSE";
	if($V1_type eq "Continuous_variable" || $V2_type eq "Continuous_variable")
	{
		if($V1_type eq "Continuous_variable"){
			$type1 = "FALSE" if($V2_type eq "Continuous_variable");
			$type2 = "TRUE" if($V2_type eq "Multiple_ordered_discrete_variable");
		#linear
			`$Rscript $Bin/Linear_reg.R $tmp_f 1 $type1 $type2`;
		}else{
			$type1 = "FALSE" if($V1_type eq "Continuous_variable");
			$type2 = "TRUE" if($V1_type eq "Multiple_ordered_discrete_variable");
			`$Rscript $Bin/Linear_reg.R $tmp_f 2 $type1 $type2`;
		}
	}elsif($V1_type eq "Binary_discrete_variable" || $V2_type eq "Binary_discrete_variable")
	{
		if($V1_type eq "Binary_discrete_variable"){
			$type2 = "TRUE" if($V2_type eq "Multiple_ordered_discrete_variable");
			 `$Rscript $Bin/Binarylogistic_reg.R $tmp_f 1 $type2`;
		}else{
			$type2 = "TRUE" if($V1_type eq "Multiple_ordered_discrete_variable");
			`$Rscript $Bin/Binarylogistic_reg.R $tmp_f 2 $type2`;
		}
	}elsif(($V1_type eq "Multiple_ordered_discrete_variable" || $V1_type eq "Multiple_unordered_discrete_variable") && ($V2_type eq "Multiple_ordered_discrete_variable" || $V2_type eq "Multiple_unordered_discrete_variable"))
	{
		if($V1_type eq "Multiple_ordered_discrete_variable"){
			$type1 = "TRUE";
		}else{
			$type1 = "FALSE";
		}
		if($V2_type eq "Multiple_ordered_discrete_variable"){
			$type2 = "TRUE";
		}else{
			$type2 = "FALSE";
		}
		`$Rscript $Bin/Multi_order_unorder_logistic_reg.R $tmp_f $type1 $type2`;
	}
	else{
		print "Error: Unexpected data type! @line\n";
	}
	
#	elsif($V1_type eq "Multiple_ordered_discrete_variable" || $V2_type eq "Multiple_ordered_discrete_variable")
#	{
#		if($V1_type eq "Multiple_ordered_discrete_variable"){
#			$type2 = "TRUE" if($V2_type eq "Multiple_ordered_discrete_variable");
#			`$Rscript $Bin/Ordlogistic_reg.R $tmp_f 1 $type2`;
#		}else{
#			$type2 = "TRUE" if($V1_type eq "Multiple_ordered_discrete_variable");
#			`$Rscript $Bin/Ordlogistic_reg.R $tmp_f 2 $type2`;
#		}
#	}elsif($V1_type eq "Multiple_unordered_discrete_variable" && $V2_type eq "Multiple_unordered_discrete_variable")
#	{
#		`$Rscript $Bin/Multinom_reg.R $tmp_f`;
#	}
	
	open P, "$tmp_f.median" or die;
	chomp(my $fir = <P>);
	my @p = split /\s+/,$fir;
	my $p_m = shift @p;
	chomp(my $sec = <P>);
	my @Beta = split /\s+/,$sec;
	my $beta_m = shift @Beta;
	print O "$V1\t$V2\t$gender\t$V1_type:$V2_type\t$p_m\t$beta_m\t",join ":",@p,"\t",join ":",@Beta,"\n";
	close P;
	
#	unlink "$tmp_f";
#	unlink "$tmp_f.median";
}
close I;
close O;
unlink "$in_file.data.rand";
unlink "$in_file.data.rand.median";


# select random data and output into a file
sub Random_select_repeat
{
	my ($name,@data) = @_;
	open O2, ">$name" or die;
	my $sum = scalar(@data);
	my $tot_data;

	for(my $j=0;$j<$Rand_num;$j++)
	{
		my @random;
		for(my $i=0;$i<$select_num; $i++)
		{
			my $f = int rand($sum);
			push @random, $f;
		}#print "@random\n";
		my ($d1,$d2,$d3);
		for(@random){
			my ($t1, $t2, $t3) = split /:/,$data[$_];
			if(defined($d1)){
				$d1 .= " $t1";
				$d2 .= " $t2";
				$d3 .= " $t3";
			}else{
				$d1 = $t1;
				$d2 = $t2;
				$d3 = $t3;
			}
		}
#print O2 "$d1\n$d2\n$d3\n";
		if(defined($tot_data)){
			$tot_data .= "$d1\n$d2\n$d3\n";
		}else{
			$tot_data = "$d1\n$d2\n$d3\n";
		}
	}
	print O2 "$tot_data";
	close O2;
}

# Discrete: select random data and output into a file
sub Random_select_repeat_discrete
{
        my ($name,$v1_t,$v2_t,@data) = @_;
        open O2, ">$name" or die;
        my $sum = scalar(@data);
	my $tot_data;

        for(my $j=0;$j<$Rand_num;$j++)
        {
                my @random;
		while(1)
		{
			@random = ();
			my %h_t_1;
			my %h_t_2;
                	for(my $i=0;$i<$select_num; $i++)
                	{
                        	my $f = int rand($sum);
                        	push @random, $f;
				my ($t1, $t2, $t3) = split /:/,$data[$f];
				$h_t_1{$t1} = 1;
				$h_t_2{$t2} = 1;
                	}#print "@random\n";
			if($v1_t !=0 && $v2_t != 0){
				last if(scalar(keys %h_t_1) >= $v1_t && scalar(keys %h_t_2) >= $v2_t);
			}elsif($v1_t != 0){
				last if(scalar(keys %h_t_1) >= $v1_t);
			}elsif($v2_t != 0){
				last if(scalar(keys %h_t_2) >= $v2_t);
			}
		}

                my ($d1,$d2,$d3);
                for(@random){
                        my ($t1, $t2, $t3) = split /:/,$data[$_];
                        if(defined($d1)){
                                $d1 .= " $t1";
                                $d2 .= " $t2";
                                $d3 .= " $t3";
                        }else{
                                $d1 = $t1;
                                $d2 = $t2;
                                $d3 = $t3;
                        }
                }
#                print O2 "$d1\n$d2\n$d3\n";
		if(defined($tot_data)){
			$tot_data .= "$d1\n$d2\n$d3\n";
		}else{
			$tot_data = "$d1\n$d2\n$d3\n";
		}
	}
	print O2 "$tot_data";
        close O2;
}

