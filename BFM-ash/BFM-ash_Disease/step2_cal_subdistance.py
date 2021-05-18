import os
import pandas as pd
import numpy as np
import pickle
import dill
import sys
from sklearn import preprocessing
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.metrics.pairwise import nan_euclidean_distances
#================input data &scale===============================================
gender=sys.argv[1]
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

#================find sub_louvain_name==============================================
def file_name(file_dir):
	L = []
	for root, dirs, files in os.walk(file_dir):
		for file in files:
#			if len(file.split("_"))==6 and file.split("_")[5]=='nodes.tsv':
				L.append(os.path.join(file))
		return L
#===============dist_function=============================================
def peer_disease_cos(diseaseID, comID):
	sub_file=pd.read_csv(com_path+"/"+filename,sep='\t', header=0)
	ec_sub=pd.DataFrame(sub_file.loc[:,'weighted_eigenvector_centrality'].values,index=sub_file['feature'],columns=['weighted_eigenvector_centrality'])
	inter=ec_sub.index & disease_data_scale.columns
	person_x=disease_data_scale.reindex(index = [diseaseID], columns = sub_file['feature'])
	person_x_trans=person_x.transpose()
	person_x_ec=person_x_trans.mul(ec_sub.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
	D_age = disease_data_scale.loc[diseaseID, 'Age']
	peer_man = bg_data_scale.loc[(bg_data_scale['Age']<D_age+1) & (bg_data_scale['Age']>D_age-1),:].reindex(columns = sub_file['feature'])
	x_peer_cos = cosine_similarity(X=person_x.notna(), Y=peer_man.notna())
	if (x_peer_cos>0.5).sum()>20:
		peer_man_20=peer_man.loc[x_peer_cos[0,:]>0.5,:].iloc[0:20,:]
		health_man_outpeer=bg_data_scale.loc[~bg_data_scale.index.isin(peer_man_20.index),:].reindex(columns=sub_file['feature'])
#		health_man_1['Age']=health_man.loc[health_man_1.index,'Age']
		health_man_other=young_bg_data.loc[(health_man_outpeer.index & young_bg_data.index),:].reindex(columns=inter)
		peer_man_20_trans=peer_man_20.transpose()
		peer_man_20_ec=peer_man_20_trans.mul(ec_sub.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
		health_man_other_trans=health_man_other.transpose()
		health_man_other_ec=health_man_other_trans.mul(ec_sub.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
		peer_health_dist=nan_euclidean_distances(X=peer_man_20_ec, Y=health_man_other_ec)
		disease_health_dist=nan_euclidean_distances(X=person_x_ec, Y=health_man_other_ec)
		peer_health_dist_df=pd.DataFrame(peer_health_dist, index=peer_man_20.index, columns=health_man_other.index)
		disease_health_dist_df=pd.DataFrame(disease_health_dist, index=person_x.index, columns=health_man_other.index)
		return(peer_health_dist_df, disease_health_dist_df)
	elif (x_peer_cos>0.5).sum()>0:
		peer_man_some=peer_man.loc[x_peer_cos[0,:]>0.5,:]
		health_man_outpeer=bg_data_scale.loc[~bg_data_scale.index.isin(peer_man_some.index),:].reindex(columns=sub_file['feature'])
#		health_man_1['Age']=health_man.loc[health_man_1.index,'Age']
		health_man_other=young_bg_data.loc[(health_man_outpeer.index & young_bg_data.index),:].reindex(columns=inter)
		peer_man_some_trans=peer_man_some.transpose()
		peer_man_some_ec=peer_man_some_trans.mul(ec_sub.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
		health_man_other_trans=health_man_other.transpose()
		health_man_other_ec=health_man_other_trans.mul(ec_sub.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
		peer_health_dist=nan_euclidean_distances(X=peer_man_some_ec, Y=health_man_other_ec)
		disease_health_dist=nan_euclidean_distances(X=person_x_ec, Y=health_man_other_ec)
		peer_health_dist_df=pd.DataFrame(peer_health_dist, index=peer_man_some.index, columns=health_man_other.index)
		disease_health_dist_df=pd.DataFrame(disease_health_dist, index=person_x.index, columns=health_man_other.index)
		return(peer_health_dist_df,disease_health_dist_df)
	else:
		peer_man_trans=peer_man.transpose()
		peer_man_ec=peer_man_trans.mul(ec_sub.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
		health_man_outpeer=bg_data_scale.loc[~bg_data_scale.index.isin(peer_man.index),:].reindex(columns=sub_file['feature'])
#		health_man_1['Age']=health_man.loc[health_man_1.index,'Age']
		health_man_other=young_bg_data.loc[(health_man_outpeer.index & young_bg_data.index),:].reindex(columns=inter)
		health_man_other_trans=health_man_other.transpose()
		health_man_other_ec=health_man_other_trans.mul(ec_sub.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
		peer_health_dist=nan_euclidean_distances(X=peer_man_ec, Y=health_man_other_ec)
		disease_health_dist=nan_euclidean_distances(X=person_x_ec, Y=health_man_other_ec)
		peer_health_dist_df=pd.DataFrame(peer_health_dist, index=peer_man.index, columns=health_man_other.index)
		disease_health_dist_df=pd.DataFrame(disease_health_dist, index=person_x.index, columns=health_man_other.index)
		return(peer_health_dist_df,disease_health_dist_df)
		
#circle
out_dir=os.getcwd()+"/"+sys.argv[2]+"/sub_Distance_result/"
if not os.path.exists(out_dir):
	os.mkdir(out_dir)
for diseaseID in disease_data.index:
	path=out_dir+diseaseID
	disease_man_x=pd.DataFrame(disease_data_scale.loc[diseaseID,:]).transpose()
	if not os.path.exists(path):
		os.mkdir(path)
	for comID in louvain_Dict:
		sub_path=path+"/BFM"+comID.split('_p')[1]
		if not os.path.exists(sub_path):
			os.mkdir(sub_path)
		com_path=dic_path+"/BFM"+comID.split('_p')[1]
		filelist=file_name(com_path)
		for filename in filelist:
			sub_com=filename.split('.', 1 )[0]
			dist_file=sub_path+"/sub_BFM"+filename.split('_')[3]+"_dist.csv"
			peer_dist,disease_dist = peer_disease_cos(diseaseID, comID)
			disease=disease_data_scale.loc[diseaseID,"disease_name"]
			peer_dist['state'] =  "health"
			disease_dist['state'] = disease
			dist=pd.concat([peer_dist, disease_dist])
			dist['community']="BFM"+comID.split('_p')[1]
			dist['sub_community']=filename
			dist.to_csv(path_or_buf=dist_file, sep="\t",index=False)











