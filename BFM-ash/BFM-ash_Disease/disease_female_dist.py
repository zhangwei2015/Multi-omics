#head1 Description
#   This script use to calculate the euclidean distances beturn disease women ang health women
#   Input:	Disease women ID
#			Background data
#			Health young woman ID
#
from sklearn.metrics.pairwise import nan_euclidean_distances
from sklearn.metrics.pairwise import cosine_similarity
from sklearn import preprocessing
import pandas as pd
import numpy as np
import os
import dill
import pickle
#=================input disease women ID & background data=========================
disper_ID=pd.read_csv("/hwfssz5/ST_HEALTH/Immune_And_Health_Lab/PopImmDiv_P17Z10200N0271/lixiaoyu/duozuxue/community_distance/health_disease/community_distance_0601/female_tuberculosis_entergastritis.csv",sep="\t")
combind_v158_female_df=pd.read_csv("/ldfssz1/ST_HEALTH/Immune_And_Health_Lab/PopImmDiv_P17Z10200N0271/wanziyun/health_mining/correlation_analysis/data_v1.58/data/combined_data17_v1.58_female_uniq_rm.csv")
#=================background data scale=======================================================
combind_v158_scaled_female_df=pd.DataFrame(preprocessing.scale(combind_v158_female_df.iloc[:,3:]))
combind_v158_scaled_female_df.index=combind_v158_female_df['OUTER_CUSTOMER_ID']
combind_v158_scaled_female_df.columns=combind_v158_female_df.columns[3:]
combind_v158_scaled_female_df['gender']=combind_v158_female_df['gender'].values
combind_v158_scaled_female_df['Age']=combind_v158_female_df['Age'].values
#=================output dirpath===================================================
out_dir="/hwfssz5/ST_HEALTH/Immune_And_Health_Lab/PopImmDiv_P17Z10200N0271/lixiaoyu/duozuxue/community_distance/health_disease/community_distance_0601/female_intestine_dist_0608"
#=================input dictionary=================================================
with open("/hwfssz5/ST_HEALTH/Immune_And_Health_Lab/PopImmDiv_P17Z10200N0271/wanziyun/health_mining/correlation_analysis/data_v1.58/Female_V2/association_0.001_louvain_p_cleanDict_allow2",'rb') as louvain_dict:
	man_louvain_Dict = pickle.load(louvain_dict,encoding='latin1')

#=================find disease_person==============================================
disease_woman = combind_v158_scaled_female_df.reindex(index=disper_ID['Sample'])
disease_woman['disease_name']=disper_ID['患病名称'].values
disease_woman_df=disease_woman.loc[disease_woman['gender']==2,:]

#=================find health young women==========================================
health_woman_ID=pd.read_csv("/hwfssz5/ST_HEALTH/Immune_And_Health_Lab/PopImmDiv_P17Z10200N0271/lixiaoyu/duozuxue/community_distance/health_disease/community_distance_0601/health_woman_0603.csv",sep="\t")
health_woman=combind_v158_scaled_female_df.loc[health,_woman_ID['Sample'],:]
young_health_woman=health_woman.loc[(health_woman['Age']<30)&(health_woman['Age']>20),:]
#=================Function for calculate dist======================================
def peer_disease_cos(diseaseID, comID):
	path="/hwfssz5/ST_HEALTH/Immune_And_Health_Lab/PopImmDiv_P17Z10200N0271/wanziyun/health_mining/correlation_analysis/data_v1.58/Female_V2/louvain_community_allow2_001/"+comID+"_nodes.tsv"
	comx=pd.read_csv(path,sep='\t', header=0 )
	ec=pd.DataFrame(comx.loc[:,'weighted_eigenvector_centrality'].values,index=comx['feature'],columns=['weighted_eigenvector_centrality'])
	inter=ec.index & disease_woman.columns
	ec_inter=ec.reindex(index=inter)
	inter_number=len(inter)
	all_number=len(ec.index)
	person_x=disease_man.reindex(index = [diseaseID], columns =inter)
	person_x_trans=person_x.transpose()
	person_x_ec=person_x_trans.mul(ec.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
	D_age = disease_man.loc[diseaseID, 'Age']
	peer_man = health_man.loc[(health_man['Age']<D_age+1) & (health_man['Age']>D_age-1),:].reindex(columns = inter)
	x_peer_cos = cosine_similarity(X=person_x.notna(), Y=peer_man.notna())
	if (x_peer_cos>0.5).sum()>20:
		peer_man_20=peer_man.loc[x_peer_cos[0,:]>0.5,:].iloc[0:20,:]
		health_man_outpeer=health_man.loc[~health_man.index.isin(peer_man_20.index),:].reindex(columns=inter)
		health_man_other=young_health_man.loc[(health_man_outpeer.index & young_health_man.index),:].reindex(columns=inter)
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
		health_man_outpeer=health_man.loc[~health_man.index.isin(peer_man_some.index),:].reindex(columns=inter)
		health_man_other=young_health_man.loc[(health_man_outpeer.index & young_health_man.index),:].reindex(columns=inter)
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
		health_man_outpeer=health_man.loc[~health_man.index.isin(peer_man.index),:].reindex(columns=inter)
		health_man_other=young_health_man.loc[(health_man_outpeer.index & young_health_man.index),:].reindex(columns=inter)
		peer_man_trans=peer_man.transpose()
		peer_man_ec=peer_man_trans.mul(ec.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
		health_man_other=health_man.loc[~health_man.index.isin(peer_man.index),:].reindex(columns=inter)
		health_man_other_trans=health_man_other.transpose()
		health_man_other_ec=health_man_other_trans.mul(ec.loc[:,'weighted_eigenvector_centrality'],axis=0).transpose()
		peer_health_dist=nan_euclidean_distances(X=peer_man_ec, Y=health_man_other_ec)
		disease_health_dist=nan_euclidean_distances(X=person_x_ec, Y=health_man_other_ec)
		peer_health_dist_df=pd.DataFrame(peer_health_dist, index=peer_man.index, columns=health_man_other.index)
		disease_health_dist_df=pd.DataFrame(disease_health_dist, index=person_x.index, columns=health_man_other.index)
		return(peer_health_dist_df,disease_health_dist_df,inter_number,all_number)


#=================circle for output result========================================
out_dir="/hwfssz5/ST_HEALTH/Immune_And_Health_Lab/PopImmDiv_P17Z10200N0271/lixiaoyu/duozuxue/community_distance/health_disease/community_distance_0601/female_intestine_dist_0608"#output fire path
for LRID in disease_man.index:
	path=out_dir+"/"+LRID
	if not os.path.exists(path):
		os.mkdir(path)
		for comID in man_louvain_Dict:
			dist_file=path+"/"+comID+"_dist.tsv"
			peer_dist,disease_dist,inter_number,all_number = peer_disease_cos(LRID, comID)
			disease=disease_man.loc[LRID,"disease_name"]
			peer_dist['state'] =  "health"
			disease_dist['state'] = disease
			dist=pd.concat([peer_dist, disease_dist])
			dist['community']=comID
			dist['inter_number']=inter_number
			dist['all_number']=all_number
			dist.to_csv(path_or_buf=dist_file, sep="\t")





















































