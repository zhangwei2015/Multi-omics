library(ggpubr)
library(ggsignif)
library(reshape2)
library(showtext)
library(ggplot2)
library(readr)
showtext_auto(enable=T)
library(dplyr)
library(Hmisc)
library(lemon)
#load_file
load_file<-function(x){
  file=read.table(
    x,
    fill=T,
    header = T,
    fileEncoding ="UTF-8",
    sep = "\t",
    stringsAsFactors=F,
    check.names = F)
    col_num=ncol(file)
  file_long<-melt(file[,2:col_num],id.vars = c("Name","Community","Round","Group"))
  return(file_long)
}
#================================================================================
man_list<-list.files("test/Distance_result",full.names=T)
woman_long<-lapply(woman_list,FUN=load_file)
rbind_woman_long<-as.data.frame(do.call(rbind,woman_long))
rbind_woman_long[rbind_woman_long==""]<-NA
woman_long_nona<-rbind_woman_long[complete.cases(rbind_woman_long),]
woman_long_nona$tag<-paste(woman_long_nona$Name,woman_long_nona$Community,woman_long_nona$variable,sep="_")
woman_r0<-woman_long_nona[woman_long_nona$Round==0,]
woman_r0$time0_value=as.numeric(woman_r0$value)
woman_r1<-woman_long_nona[woman_long_nona$Round==1,]
woman_r1$time1_value=as.numeric(woman_r1$value)
woman_r2<-woman_long_nona[woman_long_nona$Round==2,]
woman_r2$time2_value=as.numeric(woman_r2$value)
woman_r01<-merge(woman_r0,woman_r1,by="tag")
woman_r02<-merge(woman_r0,woman_r2,by="tag")
#=================================================================================
#Calculate the change in similarity distance(CSD) in T1 or T2 minus that in T0.
woman_r01$diff1_0<-woman_r01$time1_value - woman_r01$time0_value
woman_r02$diff2_0<-woman_r02$time2_value - woman_r02$time0_value
g4_1_0<-woman_r01[woman_r01$Group.x=="g4_case",c(2,3,4,5,16)]
g4_1_0$xlab<-"T1-T0"
g4_1_0$tag<-"g4T1-T0"
colnames(g4_1_0)<-c("Name","Community","Round","Group","diff_num","xlab","tag")
g4_1_median=group_by(g4_1_0,Name,Community) %>% summarise(median_value=median(diff_num))
g4_1_median$group="G4"
g5_1_0<-woman_r01[woman_r01$Group.x=="g5_control",c(2,3,4,5,16)]
g5_1_0$xlab<-"T1-T0"
g5_1_0$tag<-"g5T1-T0"
colnames(g5_1_0)<-c("Name","Community","Round","Group","diff_num","xlab","tag")
g5_1_median=group_by(g5_1_0,Name,Community) %>% summarise(median_value=median(diff_num))
g5_1_median$group="G5"
g4_2_0<-woman_r02[woman_r02$Group.x=="g4_case",c(2,3,4,5,16)]
g4_2_0$xlab<-"T2-T0"
g4_2_0$tag<-"g4T2-T0"
colnames(g4_2_0)<-c("Name","Community","Round","Group","diff_num","xlab","tag")
g4_2_median=group_by(g4_2_0,Name,Community) %>% summarise(median_value=median(diff_num))
g4_2_median$group="G4"
g5_2_0<-woman_r02[woman_r02$Group.x=="g5_control",c(2,3,4,5,16)]
g5_2_0$xlab<-"T2-T0"
g5_2_0$tag<-"g5T2-T0"
colnames(g5_2_0)<-c("Name","Community","Round","Group","diff_num","xlab","tag")
g5_2_median=group_by(g5_2_0,Name,Community) %>% summarise(median_value=median(diff_num))
g5_2_median$group="G5"
g4_g5_all<-rbind(g4_1_0[,c(1,2,3,4,5,6,7)],g5_1_0[,c(1,2,3,4,5,6,7)],g4_2_0[,c(1,2,3,4,5,6,7)],g5_2_0[,c(1,2,3,4,5,6,7)])
g4_g5_all$all_tag=paste(g4_g5_all$Name,g4_g5_all$tag,sep="_")
g4_g5_all$tag <- factor(g4_g5_all$tag, levels = c("g4T1-T0","g5T1-T0","g4T2-T0","g5T2-T0"), ordered = T)
#=====================================================================
#==========round012 diff plot function====================
print_diff_pdf<-function(x){
  print_data<-g4_g5_all[g4_g5_all$Community==x,]
  g4_1=g4_1_median[g4_1_median$Community==x,]
  g5_1=g5_1_median[g5_1_median$Community==x,]
  g4_2=g4_2_median[g4_2_median$Community==x,]
  g5_2=g5_2_median[g5_2_median$Community==x,]
  P1=round(p.adjust(t.test(g4_1$median_value,g5_1$median_value)$p.value,"fdr"),5)
  P2=round(p.adjust(t.test(g4_2$median_value,g5_2$median_value)$p.value,"fdr"),5)
  P1_0<-paste("P1-0= ",P1,sep = "")
  P2_0<-paste("P2-0= ",P2,sep = "")
  Xlab=paste(P1_0,P2_0,sep="\n")
  P<-ggplot(print_data,aes(x=tag,y=diff_num,group=all_tag))+geom_boxplot(aes(fill=Group))+theme_bw()+scale_fill_discrete(guide = FALSE) + theme(axis.text.x = element_text(size = 9),axis.text.y = element_text(size = 14),axis.title.x = element_text(size = 14),axis.title.y = element_text(size = 14)) + xlab(Xlab)
}
community_name=unique(g4_g5_all$Community)
figure_list=lapply(community_name, print_diff_pdf)
pdf(file = "round012_diff.pdf", width = 16, height = 8)
ggarrange(figure_list[[1]],figure_list[[2]],figure_list[[5]],figure_list[[6]],figure_list[[7]],figure_list[[8]],figure_list[[9]],figure_list[[10]],figure_list[[11]],figure_list[[12]],figure_list[[3]],figure_list[[4]],ncol=6,nrow = 2)  
dev.off()
#========================================================================
#===========Error scatter plot function=====================
len_sd=group_by(woman_long_nona,Name,Group,Round,Community) %>% summarise(sd=sd(value),len=median(value))
len_sd_g4=len_sd[len_sd$Group=="g4_case",]
len_sd_g5=len_sd[len_sd$Group=="g5_control",]
len_sd_g4$Community<-factor(len_sd_g4$Community,levels = c("BFM_0_92_97","BFM_1_120_120","BFM_2_57_58","BFM_3_21_22","BFM_4_146_147","BFM_5_152_154","BFM_6_62_62","BFM_7_103_104","BFM_8_148_150","BFM_9_82_82","BFM_10_92_93","BFM_11_101_102"),ordered = T)
len_sd_g5$Community<-factor(len_sd_g5$Community,levels = c("BFM_0_92_97","BFM_1_120_120","BFM_2_57_58","BFM_3_21_22","BFM_4_146_147","BFM_5_152_154","BFM_6_62_62","BFM_7_103_104","BFM_8_148_150","BFM_9_82_82","BFM_10_92_93","BFM_11_101_102"),ordered = T)
pdf(file = ".pdf", width = 10, height = 5)
ggplot(len_sd_g4,aes(as.factor(Round),value,group=Name,fill=Name,color=Name,y=len,ymin=len-sd,ymax=len+sd))+
  geom_line(size=0.5,position = position_dodge(width = 0.3)) +
  geom_errorbar(colour="black", width=0.1,size=0.6,position = position_dodge(width = 0.3))+
  geom_point(aes(fill = Name),shape=21,size=3,stroke=1,position = position_dodge(width = 0.3))+
  labs(x="time",y="distance(median)")+
  facet_rep_wrap(~Community, nrow = 2, ncol = 6, scales = "free")+
  theme_classic(base_size = 8)+theme(strip.background = element_blank())
dev.off()

