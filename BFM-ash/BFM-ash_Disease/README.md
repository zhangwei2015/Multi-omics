Manual of Multi-omics
Introduction

	Multi-omics-- This program is used to calculate the distance of different groups(patients & peer) based on multi-omics network, 
	including distance calculation of BFM and sub-BFM.

System Requirement
	It runs on 64-bit Linux systems. 
	Python and R need to be installed for your system. 

Installation

	1.Before use it, Python(https://www.python.org/)
	2.Before use it, R(http://www.r-project.org/) need to be installed. 
	3.Download the Multi-omics to your directory.(BFM)

Version 1.0.0
Usage

	1. Create shell
		python step1_cal_distance.py female test
		python step2_cal_subdistance.py female test
		Rscript dist_peer_density.R test
		
	<parameters>
		male/female <> The sex of the sample 
		test		<> Output file path 
		(All parameters can be modified according to user own needs)
	2. Run shell
		1.It can easy to run the sh 'run.sh'
			sh run.sh


Input

The input file is divided into two parts:

	1.Input data includes multi omics data of patient group and health background;

	data format
	
		Case&Control data:<Name,Gender,Age,Multi_omics_Features,disease_name>
		Backgroud data:<OUTER_CUSTOMER_ID,sex,Age,Multi_omics_Features>
	
	
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

	
	BFM-ash_Disease
		step1_cal_distance.py: This script is used to calculate the euclidean distances between patients and healthy by multi-omics.
		step2_cal_subdistance.py: This script is used to calculate the euclidean distances between patients and healthy by sub-BFM.
		dist_peer_density.R: Visualization of results ,density plot.


Output
1. Directory

the output details as follow:

        |-- test
        |-- Distance_result
        |   |-- 5A3D4475B11F0D83E053A83CA8C03B4F(Note: Named by patient ID)
        |   	|-- BFM0_dist.tsv
        |   	|-- ...
        |   	|-- ...
        |   	|-- BFM11_dist.tsv
        |   |-- ...
        |-- sub_Distance_result
        |   |-- 5A3D4475B11F0D83E053A83CA8C03B4F
        |   	|-- BFM_0_92_97
					|-- sub_BFM0
					|-- ...
					|-- sub_BFM4
        |   	|-- BFM_1_120_120
        |   	|-- ...
        |   	|-- BFM_11_101_102
			|-- ...
        


2. file format

test/Distance_result/*_dist.tsv
	0	1 ... 528	state	community	inter_number	all_number


