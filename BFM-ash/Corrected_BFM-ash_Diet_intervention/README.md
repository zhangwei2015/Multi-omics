Manual of Corrected_BFM-ash_Diet_intervention 

Introduction

This program is used to calculate the distance of different groups(case & control) based on multi-omics network, including distance calculation of BFM and sub-BFM. 
In addition, the program is also used to calculate changes in indicators in the multi-omics network. 


System Requirement

It runs on 64-bit Linux systems.  
Python and R need to be installed for your system.  


Installation

1. Before use it, Python(https://www.python.org/). 
2. Before use it, R(http://www.r-project.org/) need to be installed.  
3. Download the Multi-omics to your directory(BFM).  

Version 1.0.0

Usage

	1. Create shell
		python step1_file_process.py female 20 30 test
		python step2_cal_distance.py female test
		python step3_cal_sub_distance.py female test
		python step4_cal_featurediff.py female test
		Rscript step5_figure.R test
		
	<parameters>
		male/female <> The sex of the sample 
		20			<> Minimum age of background data 
		30			<> Maximum age of background data 
		test		<> Output file path 
		(All parameters can be modified according to user own needs)
	2. Run shell
		1.It can easy to run the sh 'run.sh'
		 sh run.sh

Input

The input file is divided into two parts:

1.Input data includes multi omics data of case group, control group and health background;

	data format
	
		Case&Control data:<Name,Gender,Age,HAID,SampleID,Group,Round,Multi_omics_Features>
		Backgroud data:<OUTER_CUSTOMER_ID,OUTER_CUSTOMER_ID,sex,Age,Multi_omics_Features>
	
	
2.Input BFM for each sex;
		
	code(Take the female sample for example)
	
		dictpath="BFM/Female_BFM"
		with open("BFM/female_BFM_dict",'rb') as louvain_dict:
			louvain_Dict = pickle.load(louvain_dict,encoding='latin1')
		for comID in louvain_Dict:
			path=dictpath+"/"+"BFM"+comID.split('_')[2]+"_nodes.tsv"
			comx=pd.read_csv(path,sep='\t',header=0)
			
		

Note:
	Please take sex difference into consideration when applying BFM to your own dataset.



Script description

step1_file_process.py: Preprocess the input data such as standardization.  
step2_cal_distance.py: This script is used to calculate the Euclidean distance between the experimental group(case & control) and the background group by multi-omics.  
step3_cal_sub_distance.py: This script is used to calculate the Euclidean distance between the experimental group(case & control) and the background data by sub-BFM.  
step4_cal_featurediff.py: This script uses the multi-omics network to calculate the relative change ratio(RCR) between the round0(T0) and round1(T1) data for every node.  
step5_figure.R: Visualization of results,including boxplot and error scatter plot. 
	

Output
1. Directory

the output details as follow:

        |-- test
        |-- Distance_result
        |   |-- BFM_0_92_97_dist.tsv
        |   |-- BFM_1_120_120_dist.tsv
        |   |-- ...
        |   |-- ...
        |   |-- ...
        |   |-- BFM_11_101_102_dist.tsv
        |-- sub_Distance_result
        |   |-- BFM_0_92_97
        |   	|-- sub_BFM_0_13_nodes.tsv
			|-- sub_BFM_1_12_nodes.tsv
			|-- ...
        |   |-- BFM_1_120_120
        |   |-- ...
        |   |-- ...
        |-- feature_change
        |   |-- BFM_0_92_97_stat.tsv
        |   |-- BFM_1_120_120_stat.tsv
        |   |-- ...
        |   |-- ...
        |   |-- BFM_11_101_102_stat.tsv

2. file format

test/Distance_result/*_dist.tsv
	0	1 ... 528	Round	Group	Name	Community

