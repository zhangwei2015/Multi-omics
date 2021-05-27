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
# function for calculating feature change(T0,T1)

def change_stat(samplename):
        inter=bg_young_data.columns & round012_scale.iloc[:,7:].columns
        bg_comx=bg_young_data.loc[:,inter]
        person_x_0=round012_scale.loc[(round012_scale['Name']==samplename) & (round012_scale['Round']==0),inter]
        person_x_0_nona=(person_x_0.shape[0]*person_x_0.shape[1])-np.sum(person_x_0.isnull().sum(axis=0))
        difference_0=np.sum(abs(bg_comx-person_x_0.loc[person_x_0.index[0],:]))/person_x_0_nona
        person_x_1=bg_comx=bg_young_data.loc[:,inter]
        person_x_1=round012_scale.loc[(round012_scale['Name']==samplename) & (round012_scale['Round']==1),inter]#similarly for T2
        person_x_1_nona=(person_x_1.shape[0]*person_x_1.shape[1])-np.sum(person_x_1.isnull().sum(axis=0))
        difference_1=np.sum(abs(bg_comx-person_x_1.loc[person_x_1.index[0],:]))/person_x_1_nona
        case_difference=pd.DataFrame(difference_1-difference_0).transpose()
        return(case_difference)

group4_data=round012_scale.loc[round012_scale['Group']=="g4_case",:]#user can change byself
group5_data=round012_scale.loc[round012_scale['Group']=="g5_control",:]
group4_df=pd.DataFrame(columns=group4_data.iloc[:,:737].columns)
group5_df=pd.DataFrame(columns=group5_data.iloc[:,:737].columns)
for samplename in group4_data['Name'].unique():
        dataframe=change_stat(samplename)
        group4_df=group4_df.append(dataframe)
for samplename in group5_data['Name'].unique():
        dataframe=change_stat(samplename)
        group5_df=group5_df.append(dataframe)
group4_mean=np.sum(group4_df)/group4_df.shape[0]
group5_mean=np.sum(group5_df)/group5_df.shape[0]
RCR_result=pd.DataFrame(group4_mean-group5_mean).transpose()

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

