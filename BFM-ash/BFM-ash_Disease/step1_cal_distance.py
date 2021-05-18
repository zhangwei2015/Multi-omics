#head1 Description
#   This script use to calculate the euclidean distances beturn disease women ang health women
#   Input:      Disease women ID
#                       Background data
#                       Health young woman ID
#
from sklearn.metrics.pairwise import nan_euclidean_distances
from sklearn.metrics.pairwise import cosine_similarity
from sklearn import preprocessing
import pandas as pd
import numpy as np
import os
import dill
import pickle
import sys
#================input data &scale===============================================
gender=sys.argv[1]
os.mkdir(sys.argv[2])
disease_data=pd.read_csv("database/input_female_diseasedata.csv",sep="\t")
disease_data.index=disease_data['OUTER_CUSTOMER_ID']
if gender=="male":
	bg_data=pd.read_csv("database/health_man_background_data.csv",sep="\t")
else:
	bg_data=pd.read_csv("database/health_woman_background_data.csv",sep="\t")
data_all=pd.concat([disease_data.iloc[:,3:disease_data.shape[1]-1],bg_data.iloc[:,3:]],ignore_index=True)
data_all_scale=pd.DataFrame(preprocessing.scale(data_all))
disease_data_scale = data_all_scale.iloc[:disease_data.shape[0],:]
disease_data_scale.columns=disease_data.iloc[:,3:disease_data.shape[1]-1].columns
disease_data_scale['disease_name']=disease_data['disease_name'].values
disease_data_scale['Age']=disease_data['Age'].values
disease_data_scale.index=disease_data['OUTER_CUSTOMER_ID']
bg_data_scale=data_all_scale.iloc[disease_data.shape[0]:,:]

bg_data_scale.index= bg_data['OUTER_CUSTOMER_ID']
bg_data_scale.columns=bg_data.columns[3:]
bg_data_scale['gender']=bg_data['gender'].values
bg_data_scale['Age']=bg_data['Age'].values
young_bg_data=bg_data_scale.loc[(bg_data_scale['Age']<30)&(bg_data_scale['Age']>20),:]
#=================input dictionary=================================================
if gender=="male":
	dic_path="BFM/Male_louvain_community_allow2_001"
	with open("BFM/male_association_0.001_louvain_p_cleanDict_allow2",'rb') as louvain_dict:
        	louvain_Dict = pickle.load(louvain_dict,encoding='latin1')
else:
	dic_path="BFM/Female_louvain_community_allow2_001"
	with open("BFM/female_association_0.001_louvain_p_cleanDict_allow2",'rb') as louvain_dict:
        	louvain_Dict = pickle.load(louvain_dict,encoding='latin1')
#================function=============================================
def peer_disease_cos(diseaseID, comID):
#	path=dic_path+"/"+comID+"_nodes.tsv"
#	comx=pd.read_csv(path,sep='\t', header=0)
	path=dic_path+"/BFM"+comID.split('_p')[1]+"_nodes.tsv"
	comx=pd.read_csv(path,sep='\t', header=0)
	ec=pd.DataFrame(comx.loc[:,'weighted_eigenvector_centrality'].values,index=comx['feature'],columns=['weighted_eigenvector_centrality'])
	inter=ec.index & disease_data_scale.columns
	ec_inter=ec.reindex(index=inter)
	inter_number=len(inter)
	all_number=len(ec.index)
	person_x=disease_data_scale.reindex(index = [diseaseID], columns =inter)
	person_x_trans=person_x.transpose()
	person_x_ec=person_x_trans.mul(ec.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
	D_age = disease_data_scale.loc[diseaseID, 'Age']
	peer_man =bg_data_scale.loc[(bg_data_scale['Age']<D_age+1) & (bg_data_scale['Age']>D_age-1),:].reindex(columns = inter)
	x_peer_cos = cosine_similarity(X=person_x.notna(), Y=peer_man.notna())
	if (x_peer_cos>0.5).sum()>20:
		peer_man_20=peer_man.loc[x_peer_cos[0,:]>0.5,:].iloc[0:20,:]
		health_man_outpeer=bg_data_scale.loc[~bg_data_scale.index.isin(peer_man_20.index),:].reindex(columns=inter)
		health_man_other=young_bg_data.loc[(health_man_outpeer.index & young_bg_data.index),:].reindex(columns=inter)
		peer_man_20_trans=peer_man_20.transpose()
		peer_man_20_ec=peer_man_20_trans.mul(ec.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
		health_man_other_trans=health_man_other.transpose()
		health_man_other_ec=health_man_other_trans.mul(ec.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
		peer_health_dist=nan_euclidean_distances(X=peer_man_20_ec, Y=health_man_other_ec)
		disease_health_dist=nan_euclidean_distances(X=person_x_ec, Y=health_man_other_ec)
		peer_health_dist_df=pd.DataFrame(peer_health_dist, index=peer_man_20.index, columns=health_man_other.index)
		disease_health_dist_df=pd.DataFrame(disease_health_dist, index=person_x.index, columns=health_man_other.index)
		return(peer_health_dist_df, disease_health_dist_df,inter_number,all_number)
	elif (x_peer_cos>0.5).sum()>0:
		peer_man_some=peer_man.loc[x_peer_cos[0,:]>0.5,:]
		health_man_outpeer=bg_data_scale.loc[~bg_data_scale.index.isin(peer_man_some.index),:].reindex(columns=inter)
		health_man_other=young_bg_data.loc[(health_man_outpeer.index & young_bg_data.index),:].reindex(columns=inter)
		peer_man_some_trans=peer_man_some.transpose()
		peer_man_some_ec=peer_man_some_trans.mul(ec.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
		health_man_other_trans=health_man_other.transpose()
		health_man_other_ec=health_man_other_trans.mul(ec.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
		peer_health_dist=nan_euclidean_distances(X=peer_man_some_ec, Y=health_man_other_ec)
		disease_health_dist=nan_euclidean_distances(X=person_x_ec, Y=health_man_other_ec)
		peer_health_dist_df=pd.DataFrame(peer_health_dist, index=peer_man_some.index, columns=health_man_other.index)
		disease_health_dist_df=pd.DataFrame(disease_health_dist, index=person_x.index, columns=health_man_other.index)
		return(peer_health_dist_df,disease_health_dist_df,inter_number,all_number)
	else:
		health_man_outpeer=bg_data_scale.loc[~bg_data_scale.index.isin(peer_man.index),:].reindex(columns=inter)
		health_man_other=young_bg_data.loc[(health_man_outpeer.index & young_bg_data.index),:].reindex(columns=inter)
		peer_man_trans=peer_man.transpose()
		peer_man_ec=peer_man_trans.mul(ec.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
		health_man_other=bg_data_scale.loc[~bg_data_scale.index.isin(peer_man.index),:].reindex(columns=inter)
		health_man_other_trans=health_man_other.transpose()
		health_man_other_ec=health_man_other_trans.mul(ec.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
		peer_health_dist=nan_euclidean_distances(X=peer_man_ec, Y=health_man_other_ec)
		disease_health_dist=nan_euclidean_distances(X=person_x_ec, Y=health_man_other_ec)
		peer_health_dist_df=pd.DataFrame(peer_health_dist, index=peer_man.index, columns=health_man_other.index)
		disease_health_dist_df=pd.DataFrame(disease_health_dist, index=person_x.index, columns=health_man_other.index)
		return(peer_health_dist_df,disease_health_dist_df,inter_number,all_number)
#=================circle for output result========================================
out_dir=os.getcwd()+"/"+sys.argv[2]+"/Distance_result/"
if not os.path.exists(out_dir):
	os.mkdir(out_dir)
for LRID in disease_data.index:
        path=out_dir+LRID
        if not os.path.exists(path):
                os.mkdir(path)
                for comID in louvain_Dict:
                        dist_file=path+"/BFM"+comID.split('_')[2]+"_dist.tsv"
                        peer_dist,disease_dist,inter_number,all_number = peer_disease_cos(LRID, comID)
                        disease=disease_data_scale.loc[LRID,"disease_name"]
                        peer_dist['state'] =  "health"
                        disease_dist['state'] = disease
                        dist=pd.concat([peer_dist, disease_dist])
                        dist['community']="BFM"+comID.split('_')[2]
                        dist['inter_number']=inter_number
                        dist['all_number']=all_number
                        dist.to_csv(path_or_buf=dist_file, sep="\t")

