#!/usr/bin/python3
#coding=utf-8
#Description
'''
        This script uses the multi-omics network to calculate the relative change ratio(RCR) between the round0(T0) and round1(T1) data for every node.
        Input: round012_scale.csv
               bg_young_data.csv
                (These two files were generated in the first step)
               female_BFM_dict
               male_BFM_dict
                (multi-omics dictionary)
'''

#-----------import package
import pandas as pd
import numpy as np
import os
import dill
import pickle
import sys
#------------input file
round012_scale=pd.read_csv("input_case_control_data.csv",sep=",")
bg_young_data=pd.read_csv("bg_young_data.csv",sep="\t")
gender=sys.argv[1]
output_path=sys.argv[2]
#------------input Dictionary
# input multi-omics net dictionary
if gender=="female":
        dictpath="Female_BFM"
        with open("female_BFM_dict",'rb') as louvain_dict:
                louvain_Dict = pickle.load(louvain_dict,encoding='latin1')
else:
        dictpath="Male_BFM"
        with open("male_BFM_dict",'rb') as louvain_dict:
                louvain_Dict = pickle.load(louvain_dict,encoding='latin1')
#function for calculating feature change(T0,T1)
round_0=round012_scale.loc[(round012_scale['Round']==0),:]
round_1=round012_scale.loc[(round012_scale['Round']==1),:]
group4_0=round_0.loc[round_0['Group']=="g4_case",:].iloc[:,:737].reset_index(drop=True)
group4_1=round_1.loc[round_1['Group']=="g4_case",:].iloc[:,:737].reset_index(drop=True)
group5_0=round_0.loc[round_0['Group']=="g5_control",:].iloc[:,:737].reset_index(drop=True)
group5_1=round_1.loc[round_1['Group']=="g5_control",:].iloc[:,:737].reset_index(drop=True)
case_01=np.sum(abs(group4_1)-abs(group4_0))/group4_1.shape[0]
control_01=np.sum(abs(group5_1)-abs(group5_0))/group5_1.shape[0]
case_control01=pd.concat([case_01,control_01],axis=1)
case_control01.columns=['case','control']
RCR_result=pd.DataFrame(case_01-control_01).transpose()

#
out_dir=output_path+"/"+"feature_change"
if not os.path.exists(out_dir):
        os.mkdir(out_dir)
if gender=="male":
	com_path="Male_BFM"
else:
	com_path="Female_BFM"
for comID in louvain_Dict:
        stat_file=out_dir+"/"+"BFM"+comID.split('_')[2]+"_stat.tsv"
        path=com_path+"/"+comID+"_nodes.tsv"
        comx=pd.read_csv(path,sep='\t', header=0)
        comx.index=comx['feature']
        inter=comx.index & round012_scale.iloc[:,:737].columns
        inter_number=len(inter)
        all_number=len(comx.index)
        RCR_by_BFM=RCR_result.loc[:,inter]
        RCR_by_BFM['inter_number']=inter_number
        RCR_by_BFM['all_number']=all_number
        RCR_by_BFM_trans=RCR_by_BFM.transpose()
        RCR_by_BFM_trans.to_csv(path_or_buf=stat_file, sep="\t")

