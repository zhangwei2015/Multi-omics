#!/usr/bin/python3
#coding=utf-8

#Description
'''
        This script is used to calculate the Euclidean distance between the experimental group and the background data by multi-omics.
        Input: round012_scale.csv
               bg_young_data.csv
		(These two files were generated in the first step)
	       female_association_0.001_louvain_p_cleanDict_allow2
	       male_association_0.001_louvain_p_cleanDict_allow2
                (multi-omics dictionary)
'''
#Version
'''
        Version: 1.0.0    Date: 2021 Author: lixiaoyu1@genomics.cn;
'''
#
#-----------import package & input parameter
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
output_path=sys.argv[2]+"/Distance_result"
#-----------input file
round012_scale=pd.read_csv("input_case_control_data.csv",sep=",")
bg_young_data=pd.read_csv("bg_young_data.csv",sep="\t")
# input multi-omics net dictionary
if gender=="female":
	dictpath="Female_louvain_community_allow2_001"
	with open("female_association_0.001_louvain_p_cleanDict_allow2",'rb') as louvain_dict:
		louvain_Dict = pickle.load(louvain_dict,encoding='latin1')
else:
	dictpath="Male_louvain_community_allow2_001"
	with open("male_association_0.001_louvain_p_cleanDict_allow2",'rb') as louvain_dict:
                louvain_Dict = pickle.load(louvain_dict,encoding='latin1')
#function of  the distance calculation
#dataframe:DataFrame  to be calculated;
#comID:The name of each module of the network
def round_health_dist(dataframe,comID):
    path=dictpath+"/"+comID+"_nodes.tsv"
    comx=pd.read_csv(path,sep='\t',header=0)
    ec=pd.DataFrame(comx.loc[:,'weighted_eigenvector_centrality'].values,index=comx['feature'],columns=['weighted_eigenvector_centrality'])
    inter=ec.index & dataframe.columns
    ec_inter=ec.reindex(index=inter)
    x=dataframe.reindex(index =dataframe.index, columns = inter)
    x_trans=x.transpose()
    x_ec=x_trans.mul(ec_inter.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
    bg_young_data_trans=bg_young_data.reindex(columns=inter).transpose()
    bg_young_data_ec=bg_young_data_trans.mul(ec_inter.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
    dist=nan_euclidean_distances(X=x_ec, Y=bg_young_data_ec)
    dist_df=pd.DataFrame(dist, index=x_ec.index, columns=bg_young_data_ec.index)
    inter_df=pd.DataFrame(inter)
    inter_number=len(inter)
    all_number=len(ec.index)
    return(dist_df,inter_df)

#output result file
if not os.path.exists(output_path):
        os.mkdir(output_path)
for comID in louvain_Dict:
        dist_file=output_path+"/"+"BFM"+comID.split('_')[2]+"_dist.tsv"
        dist,inter=round_health_dist(round012_scale,comID)
        dist['Round']=round012_scale['Round']
        dist['Group']=round012_scale['Group']
        dist['Name']=round012_scale['Name']
        dist['Community']="BFM"+comID.split('_')[2]
        dist.to_csv(path_or_buf=dist_file, sep="\t")



