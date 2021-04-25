args <- commandArgs(trailingOnly = TRUE)
tmpF <- args[1]
phase <- args[2]
isOrdinal <- args[3]
tmp <- read.table(tmpF, header = FALSE, sep = " ", stringsAsFactors = F) #1503*1000
tmpT <- t(tmp)

if (phase==1){
	result <- data.frame(pvalue=rep(NA,nrow(tmp)/3), 
						 beta=rep(NA,nrow(tmp)/3),
						 row.names = paste("r", seq(1,nrow(tmp),3), sep = "_"))
	for (i in seq(1,nrow(tmp),3)) {
			y <- factor(tmpT[,i])
			if (isOrdinal=="TRUE") {
				x <- factor(tmpT[,i+1],ordered=T)
				fit <- glm(y ~ x + tmpT[,i+2], family="binomial")
				sumx <- summary(fit)
				ct <- sumx$coefficients
				pvalue = min(ct[-c(1,nrow(ct)),'Pr(>|z|)'])
				result[paste("r", i, sep = "_"), 'pvalue'] = pvalue
				idx = which.min(ct[-c(1,nrow(ct)),'Pr(>|z|)'])
				beta = ct[-c(1,nrow(ct)), "Estimate"][idx]
				result[paste("r", i, sep = "_"), 'beta'] = beta
			} else if (isOrdinal=="FALSE") {
				x <- factor(tmpT[,i+1], ordered=F)
				fit <- glm(y ~ x + tmpT[,i+2], family="binomial")
				sumx <- summary(fit)
				ct <- sumx$coefficients
				pvalue = min(ct[-c(1,nrow(ct)),'Pr(>|z|)'])
				result[paste("r", i, sep = "_"), 'pvalue'] = pvalue
				idx = which.min(ct[-c(1,nrow(ct)),'Pr(>|z|)'])
				beta = ct[-c(1,nrow(ct)), "Estimate"][idx]
				result[paste("r", i, sep = "_"), 'beta'] = beta
			}
	}
} else if (phase==2) {
	result <- data.frame(pvalue=rep(NA,nrow(tmp)/3), 
						 beta=rep(NA,nrow(tmp)/3),
						 row.names = paste("r", seq(2,nrow(tmp),3), sep = "_"))
	for (i in seq(2,nrow(tmp),3)) {
			y <- factor(tmpT[,i])
			if (isOrdinal=="TRUE") {
				x <- factor(tmpT[,i-1], ordered=T)
				fit <- glm(y ~ x + tmpT[,i+1], family="binomial")
				sumx <- summary(fit)
				ct <- sumx$coefficients
				pvalue = min(ct[-c(1,nrow(ct)),'Pr(>|z|)'])
				result[paste("r", i, sep = "_"), 'pvalue'] = pvalue
				idx = which.min(ct[-c(1,nrow(ct)),'Pr(>|z|)'])
				beta = ct[-c(1,nrow(ct)), "Estimate"][idx]
				result[paste("r", i, sep = "_"), 'beta'] = beta
			} else if (isOrdinal=="FALSE") {
				x <- factor(tmpT[,i-1], ordered=F)
				fit <- glm(y ~ x + tmpT[,i+1], family="binomial")
				sumx <- summary(fit)
				ct <- sumx$coefficients
				pvalue = min(ct[-c(1,nrow(ct)),'Pr(>|z|)'])
				result[paste("r", i, sep = "_"), 'pvalue'] = pvalue
				idx = which.min(ct[-c(1,nrow(ct)),'Pr(>|z|)'])
				beta = ct[-c(1,nrow(ct)), "Estimate"][idx]
				result[paste("r", i, sep = "_"), 'beta'] = beta}
	}
}

beta_median <- median(result$beta)
pvalue_median <- result$pvalue[which(result$beta==beta_median)]
m_t <- data.frame(pvalue=pvalue_median, beta=beta_median, row.names = "median")
res <- t(rbind(m_t, result))
write.table(x=res, file = paste0(tmpF, ".median"), quote = FALSE, row.names = FALSE, col.names = FALSE, fileEncoding = "UTF-8")
