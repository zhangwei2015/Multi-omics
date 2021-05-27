#!/usr/bin/python3
# coding=utf-8

# Description
'''
        This script is used to calculate the Euclidean distance between the experimental group and the background data by sub louvain.
        Input: round012_scale.csv
               bg_young_data.csv
                (These two files were generated in the first step)
               female_BFM_dict
               male_BFM_dict
                (multi-omics dictionary)
'''
# Version
'''
        Version: 1.0.0    Date: 2021 Author: lixiaoyu1@genomics.cn;
'''
# 
# import package & input parameter
from sklearn.metrics.pairwise import nan_euclidean_distances
from sklearn.metrics.pairwise import cosine_similarity
from sklearn import preprocessing
import pandas as pd
import numpy as np
import os
import dill
import pickle
import sys

gender=sys.argv[1]
output_path=sys.argv[2]+"/sub_Distance_result"
# input file
round012_scale=pd.read_csv("input_case_control_data.csv",sep=",")
bg_young_data=pd.read_csv("bg_young_data.csv",sep="\t")
# input multi-omics net dictionary
if gender=="female":
        dictpath="BFM/Female_BFM"
        with open("BFM/female_BFM_dict",'rb') as louvain_dict:
                louvain_Dict = pickle.load(louvain_dict,encoding='latin1')
else:
        dictpath="BFM/Male_BFM"
        with open("BFM/male_BFM_dict",'rb') as louvain_dict:
                louvain_Dict = pickle.load(louvain_dict,encoding='latin1')
# function of  the distance calculation of sub-com
# dataframe:DataFrame  to be calculated;
# comID:The name of each module of the network
def round_health_subdist(dataframe,comID):
        sub_file=pd.read_csv(com_path+"/"+filename,sep='\t', header=0)
        ec_sub=pd.DataFrame(sub_file.loc[:,'weighted_eigenvector_centrality'].values,index=sub_file['feature'],columns=['weighted_eigenvector_centrality'])
        inter=ec_sub.index & dataframe.columns
        if len(inter)>0:
                ec_inter=ec_sub.reindex(index=inter)
                x=dataframe.reindex(index =dataframe.index, columns = inter)
                x_trans=x.transpose()
                x_ec=x_trans.mul(ec_inter.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
                bg_young_data_trans=bg_young_data.reindex(columns=inter).transpose()
                bg_young_data_ec=bg_young_data_trans.mul(ec_inter.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
                dist=nan_euclidean_distances(X=x_ec, Y=bg_young_data_ec)
                dist_df=pd.DataFrame(dist,index=x_ec.index, columns=bg_young_data_ec.index)
                dist_df['Round']=round012_scale['Round']
                dist_df['Group']=round012_scale['Group']
                dist_df['Name']=round012_scale['Name']
                dist_df['Community']="Sub_BFM"+filename.split('_')[3]
                return(dist_df)
        else:
                return(sub_file['feature'])
def file_name(file_dir):
        L = []
        for root, dirs, files in os.walk(file_dir):
                for file in files:
                        if file.split("_")[5]=='nodes.tsv':
                                 L.append(os.path.join(file))
                return L

if not os.path.exists(output_path):
        os.mkdir(output_path)
for comID in louvain_Dict:
        sub_path=output_path+"/"+"BFM"+comID.split('_')[2]
        if not os.path.exists(sub_path):
                os.mkdir(sub_path)
        com_path=dictpath+"/"+"BFM"+comID.split('_')[2]
        filelist=file_name(com_path)
        for filename in filelist:
                dist_file=sub_path+"/"+"Sub_BFM"+filename.split('_')[3]
                dist=round_health_subdist(round012_scale,comID)
                dist.to_csv(path_or_buf=dist_file, sep="\t")

