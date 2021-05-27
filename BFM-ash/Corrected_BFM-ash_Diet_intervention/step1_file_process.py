#!/usr/bin/python3
#coding=utf-8

#Description
'''
	This script is used to process and generate profile.
	Input: Case&Control data
	       Backgroud data
'''
#Version
'''
        Version: 1.0.0    Date: 2021 Author: lixiaoyu1@genomics.cn;
'''
#Input File Example
'''
	Case&Control data:<Name,Gender,Age,HAID,SampleID,Group,Round,Multi_omics_Features>
	Backgroud data:<OUTER_CUSTOMER_ID,OUTER_CUSTOMER_ID,gender,Age,Multi_omics_Features>
	
'''	
#	
#-----------import package & input parameter
import pandas as pd
import numpy as np
import sys
import os
from sklearn import preprocessing
inputfile=sys.argv[1]
gender=sys.argv[2]
outpath=sys.argv[3]
#-----------input case&control data and input background data
round_012=pd.read_csv(inputfile,sep=",")
round012_row_num=round_012.shape[0]
if gender=="male":
	bg_data=pd.read_csv("database/combined_data17_v1.58_male_uniq_rm.csv",sep=",")
else:
	bg_data=pd.read_csv("database/combined_data17_v1.58_female_uniq_rm.csv",sep=",")
        
#1. data scale
intersect_feature=bg_data.iloc[:,4:].columns & round_012.iloc[:,7:].columns#bg data has 4 personal feature;round_012 data has 7 personal feature
round012_inter=round_012.loc[:,intersect_feature]
bg_data_inter=bg_data.loc[:,intersect_feature]
data_all=pd.concat([round012_inter,bg_data_inter])
data_all_scale=pd.DataFrame(preprocessing.scale(data_all))
round012_scale=data_all_scale.iloc[:round012_row_num,:]
round012_scale.index=round_012['SampleID']
round012_scale.columns=intersect_feature
round012_scale['Gender']=round_012['Gender'].values
round012_scale['Round']=round_012['Round'].values
round012_scale['Name']=round_012['Name'].values
round012_scale['Group']=round_012['Group'].values
bg_data_scale=pd.DataFrame(preprocessing.scale(data_all.iloc[round012_row_num:,:]))
bg_data_scale.index=bg_data['OUTER_CUSTOMER_ID']
bg_data_scale.columns=intersect_feature
bg_data_scale['Gender']=bg_data['gender'].values
bg_data_scale['Age']=bg_data['Age'].values
#2. find young sample of bg data
bg_young_data=bg_data_scale.loc[(bg_data_scale['Age']<30)&(bg_data_scale['Age']>20),:]
#3. output file
if not os.path.exists(outpath):
        os.mkdir(outpath)
round_filename=outpath+"/"+"round012_scale.csv"
bg_data=outpath+"/"+"bg_young_data.csv"
round012_scale.to_csv(path_or_buf=round_filename, sep="\t")
bg_young_data.to_csv(path_or_buf=bg_data,sep="\t")


