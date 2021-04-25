args <- commandArgs(trailingOnly = TRUE)
tmpF <- args[1]
phase <- args[2]
isFactor <- args[3]
isOrdinal <- args[4]
tmp <- read.table(tmpF, header = FALSE, sep = " ", stringsAsFactors = F) #1503*1000
tmpT <- t(tmp)

sumLinear <- function(y,x,varType,age){
	if (varType=="Cont") {
		fit <- lm(y~x+age)
		sumx <- summary(fit)
		pvalue = sumx$coefficients['x', 'Pr(>|t|)']
		beta = sumx$coefficients['x', "Estimate"] 
	} else if (varType=="Unord") {
		x <- factor(x)
		fit <- lm(y~x+age)
		sumx <- summary(fit)
		ct <- sumx$coefficients
		pvalue = min(ct[-c(1, nrow(ct)),'Pr(>|t|)'])
		beta = ct[-c(1, nrow(ct)),"Estimate"][which.min(ct[-c(1, nrow(ct)),'Pr(>|t|)'])]
	} else if (varType=="Ord") {
		x <- factor(x, ordered = T)
		fit <- lm(y~x+age)
		sumx <- summary(fit)
		ct <- sumx$coefficients
		pvalue = min(ct[-c(1, nrow(ct)),'Pr(>|t|)'])
		beta = ct[-c(1, nrow(ct)),"Estimate"][which.min(ct[-c(1, nrow(ct)),'Pr(>|t|)'])]
	}
	return(c(pvalue, beta))
}

#if (phase==1){
#	result <- data.frame(pvalue=rep(NA,nrow(tmp)/3), 
#						 beta=rep(NA,nrow(tmp)/3), 
#						 row.names = paste("r", seq(1,nrow(tmp),3), sep = "_"))
#	for (i in seq(1,nrow(tmp),3)) {
#	#		fit <- lm(tmp[i,]~tmp[i+1,]+tmp[i+2,])
#			fit <- lm(tmpT[,i]~tmpT[,i+1]+tmpT[,i+2])
#			sumx = summary(fit)
#			pvalue = sumx$coefficients['tmpT[, i + 1]','Pr(>|t|)']
#			result[paste("r", i, sep = "_"), 'pvalue'] = pvalue
#			beta = sumx$coefficients["tmpT[, i + 1]","Estimate"]
#			result[paste("r", i, sep = "_"), 'beta'] = beta
#	#		cis = confint(fit, level=0.95)
#	#		lower = cis["tmpT[, i + 1]", "2.5 %"]
#	#		upper = cis["tmpT[, i + 1]", "97.5 %"]
#	}
#} else if (phase==2) {
#	result <- data.frame(pvalue=rep(NA,nrow(tmp)/3), 
#						 beta=rep(NA,nrow(tmp)/3), 
#						 row.names = paste("r", seq(2,nrow(tmp),3), sep = "_"))
#	for (i in seq(2,nrow(tmp),3)) {
#			fit <- lm(tmpT[,i]~tmpT[,i-1]+tmpT[,i+1])
#			sumx = summary(fit)
#			pvalue = sumx$coefficients['tmpT[, i - 1]','Pr(>|t|)']
#			result[paste("r", i, sep = "_"), 'pvalue'] = pvalue
#			beta = sumx$coefficients["tmpT[, i - 1]","Estimate"]
#			result[paste("r", i, sep = "_"), 'beta'] = beta
#	}
#}

if (phase==1){
	result <- data.frame(pvalue=rep(NA,nrow(tmp)/3), 
						 beta=rep(NA,nrow(tmp)/3), 
						 row.names = paste("r", seq(1,nrow(tmp),3), sep = "_"))
	for (i in seq(1,nrow(tmp),3)) {
			if (isFactor=="FALSE"){
				pval_beta = sumLinear(tmpT[,i], tmpT[,i+1], "Cont", tmpT[,i+2]) 
				result[paste("r", i, sep = "_"), 'pvalue'] = pval_beta[1]
				result[paste("r", i, sep = "_"), 'beta'] = pval_beta[2] 
			} else if (isFactor=="TRUE" & isOrdinal=="FALSE") {
				pval_beta = sumLinear(tmpT[,i], tmpT[,i+1], "Unord", tmpT[,i+2])
				result[paste("r", i, sep = "_"), 'pvalue'] = pval_beta[1]
				result[paste("r", i, sep = "_"), 'beta'] = pval_beta[2] 
			} else if (isFactor=="TRUE" & isOrdinal=="TRUE") {
				pval_beta = sumLinear(tmpT[,i], tmpT[,i+1], "Ord", tmpT[,i+2])
				result[paste("r", i, sep = "_"), 'pvalue'] = pval_beta[1]
				result[paste("r", i, sep = "_"), 'beta'] = pval_beta[2] 
			}
	}
} else if (phase==2) {
	result <- data.frame(pvalue=rep(NA,nrow(tmp)/3), 
						 beta=rep(NA,nrow(tmp)/3), 
						 row.names = paste("r", seq(2,nrow(tmp),3), sep = "_"))
	for (i in seq(2,nrow(tmp),3)) {
			if (isFactor=="FALSE"){
				pval_beta = sumLinear(tmpT[,i], tmpT[,i-1], "Cont", tmpT[,i+1]) 
				result[paste("r", i, sep = "_"), 'pvalue'] = pval_beta[1]
				result[paste("r", i, sep = "_"), 'beta'] = pval_beta[2] 
			} else if (isFactor=="TRUE" & isOrdinal=="FALSE") {
				pval_beta = sumLinear(tmpT[,i], tmpT[,i-1], "Unord", tmpT[,i+1])
				result[paste("r", i, sep = "_"), 'pvalue'] = pval_beta[1]
				result[paste("r", i, sep = "_"), 'beta'] = pval_beta[2] 
			} else if (isFactor=="TRUE" & isOrdinal=="TRUE") {
				pval_beta = sumLinear(tmpT[,i], tmpT[,i-1], "Ord", tmpT[,i+1])
				result[paste("r", i, sep = "_"), 'pvalue'] = pval_beta[1]
				result[paste("r", i, sep = "_"), 'beta'] = pval_beta[2] 
			}
	}
}
beta_median <- median(result$beta)
pvalue_median <- result$pvalue[which(result$beta==beta_median)]
m_t <- data.frame(pvalue=pvalue_median, beta=beta_median, row.names = "median")
res <- t(rbind(m_t, result))

write.table(x=res, file = paste0(tmpF, ".median"), quote = FALSE, row.names = FALSE, col.names = FALSE, fileEncoding = "UTF-8")
