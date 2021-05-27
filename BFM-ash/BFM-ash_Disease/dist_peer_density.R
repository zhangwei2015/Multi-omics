setwd("test")
library(ggpubr)
library(ggsignif)
library(reshape2)
library(showtext)
library(dplyr)
showtext_auto(enable=T)
load_file<-function(x){
  disease_file=read.table(
    x,
    fill=T,
    header = T,
    sep = "\t",
    fileEncoding ="UTF-8",
    stringsAsFactors=F,
    check.names = F)
  column=length(colnames(disease_file))-2
  colnames(disease_file)[1]<-"OUTER_CUSTOMER_ID"
  disease_file_long<-melt(disease_file[,1:column],id.vars = c("state","community","OUTER_CUSTOMER_ID"))
  return(disease_file_long)
}
all_woman<-function(x){
  disease_filelist<-list.files(x,pattern = ".tsv",full.names = T)
  disease_file_long<-lapply(disease_filelist,FUN=load_file)
  rbind_disease_long<-as.data.frame(do.call(rbind,disease_file_long))
  rbind_disease_long[rbind_disease_long==""]<-NA
  rbind_disease_long_nona<-rbind_disease_long[complete.cases(rbind_disease_long),]
  rbind_disease_long_nona$value_num=as.numeric(rbind_disease_long_nona$value)
  return(rbind_disease_long_nona)
}
#==============================tuberculosis===============================
all_woman_file<-list.files("test",full.names=T)
all_woman_com_rbind<-lapply(all_woman_file,FUN=all_woman)
print_density<-function(x){
  p_df=group_by(x, community) %>% summarise(p=t.test(value~state,alternative="less",var.equal=TRUE)$p.value)
  p_df$p_adj=p.adjust(p_df$p,"fdr")
  ggplot(x,aes(x=value_num))+geom_density(aes(y=..scaled..,group=state,fill=state),alpha=0.3)+facet_grid(~community,scales = "free")+geom_text(x=1,y=1,aes(label=sprintf("p = %.2g", p_df$p_adj)),data = p_df,size=3)+theme_classic()
}
p<-lapply(all_woman_com_rbind,FUN=print_density)
pdf(file = "female_dist_desease_fdr.pdf", width = 16, height = 4)
ggarrange(p[[1]],p[[2]],ncol=1,nrow = 2,labels = c("A","B"))
dev.off()
#==============================enterogastritis============================
all_woman_file<-list.files("test",full.names=T)
all_woman_com_rbind<-lapply(all_woman_file,FUN=all_woman)
print_density<-function(x){
  p_df=group_by(x, community) %>% summarise(p=t.test(value~state,paired=T,var.equal=TRUE)$p.value)
  ggplot(x,aes(x=value_num))+geom_density(aes(y=..scaled..,group=state,fill=state),alpha=0.3)+facet_grid(~community,scales = "free")+geom_text(x=1,y=1,aes(label=sprintf("p = %.2g", p_df$p)),data = p_df,size=3)+theme_classic()
}
p<-lapply(all_woman_com_rbind,FUN=print_density)
pdf(file = "female_intestine_dist_0606.pdf", width = 20, height = 5)
ggarrange(p[[1]],p[[2]],ncol=1,nrow = 2,labels = c("A","B"))
dev.off()
#===============================sub_net===================================
load_sub_file<-function(x){
  woman_file=read.table(
    x,
    fill=T,
    #  col.names = file_col,
    header = T,
    sep = ",",
    fileEncoding ="UTF-8",
    stringsAsFactors=F,
    check.names = F)
  colnames(woman_file)[1]<-"OUTER_CUSTOMER_ID"
  ID=woman_file[length(row.names(woman_file)),1]
  disease_file_long<-melt(woman_file,id.vars = c("state","sub_community","OUTER_CUSTOMER_ID","community"))
  disease_file_long['ID_tag']=ID
  return(disease_file_long)
}
person_sub<-function(x){
  disease_woman_file<-list.files(x,pattern = ".tsv",full.names = T)
  disease_file_long<-lapply(disease_woman_file,FUN=load_sub_file)
  rbind_disease_long<-as.data.frame(do.call(rbind,disease_file_long))
  rbind_disease_long[rbind_disease_long==""]<-NA
  rbind_disease_long_nona<-rbind_disease_long[complete.cases(rbind_disease_long),]
  rbind_disease_long_nona$value_num=as.numeric(rbind_disease_long_nona$value)
  return(rbind_disease_long_nona)
}
print_density<-function(data,name,com){
  data_df=data.frame(dplyr::filter(data[which(data['community']==com),],ID_tag==name))
  p_df=group_by(data_df, sub_community) %>% summarise(p=t.test(value~state,alternative="less",var.equal=TRUE)$p.value)
  ggplot(data_df,aes(x=value_num))+geom_density(aes(y=..scaled..,group=state,fill=state),alpha=0.3)+facet_grid(~sub_community,scales = "free")+geom_text(x=1,y=1,aes(label=sprintf("p = %.2g", p_df$p)),data = p_df,size=3)+theme_classic()
}
list_file<-function(x){
  file_list=list.files(x,full.names=T)
  return(file_list)
}
#female,tuberculosis,BFM3
woman_sub_list<-list_file("test/sub_Distance_result")
person_sublist<-lapply(woman_sub_list, FUN = list_file)
all_person_list=lapply(person_sublist, all_sub)
all_woman_long<-as.data.frame(do.call(rbind,all_person_list))
p1=print_density(all_woman_long,"5A3D4475B2F30D83E053A83CA8C03B4F","BFM_3_21_22")
p2=print_density(all_woman_long,"5A3D4475B3D60D83E053A83CA8C03B4F","BFM_3_21_22")
pdf(file = "female_sub.pdf", width = 20, height = 8)
ggarrange(p1,p2,ncol=1,nrow = 2,labels = c("louvain3","louvain3"))
dev.off()
#female,enterogastritis,BFM4
woman_sub_list<-list_file("test/sub_Distance_result")
person_sublist<-lapply(woman_sub_list, FUN = list_file)
all_person_list=lapply(person_sublist, all_sub)
all_woman_long<-as.data.frame(do.call(rbind,all_person_list))
p1=print_density(all_woman_long,"5A3D4475B11F0D83E053A83CA8C03B4F","BFM_4_146_147")
p2=print_density(all_woman_long,"5A3D4475B1510D83E053A83CA8C03B4F","BFM_4_146_147")
pdf(file = "female_sub.pdf", width = 20, height = 15)
ggarrange(p1,p2,ncol=1,nrow = 2,labels = c("louvain4","louvain4"))
dev.off()