require(MASS)
require(lmtest)
require(nnet)
args <- commandArgs(trailingOnly = TRUE)
tmpF <- args[1]
isOrdinal1 <- as.logical(args[2])
isOrdinal2 <- as.logical(args[3])
tmp <- read.table(tmpF, header = FALSE, sep = " ", stringsAsFactors = F) #1503*1000
tmpT <- t(tmp)

which.median <- function(x) {
	n=length(x)
	if (n%%2==0) { 
		p1 = x[order(x)[n/2]]
		p2 = x[order(x)[n/2+1]]
		if (p1<=p2) {
			idx = order(x)[n/2]
		} else {
			idx = order(x)[n/2+1]
		}
	} else {
		idx = order(x)[ceiling(n/2)]
	}	
	return(idx)
}

sumMultinom <- function(y,x,isOrdinal,age){
	if (!isOrdinal) {
		x <- factor(x)
	} else {
		x <- factor(x, ordered=T)
	}
	y <- factor(y, ordered=F) 
		fit <- multinom(y ~ x + age, maxit=1000, trace=FALSE)
		sumx <- summary(fit)
		z <- sumx$coefficients/sumx$standard.errors
		p = (1 - pnorm(abs(z), 0, 1))*2
		p_v <- as.vector(p[,-c(1,ncol(p))])
		idx <- which.median(p_v)
		pvalue <- p_v[idx]
		beta <- sumx$coefficients[,-c(1,ncol(p))][idx]
#		pvalue = min(p[,-c(1,ncol(p))])
#		beta = sumx$coefficients[,-c(1,ncol(p))][which.min(p[,-c(1,ncol(p))])]	
	return(c(pvalue, beta))
}

sumLogit <- function(y,x,isOrdinal,age){
	if (!isOrdinal) {
		x <- factor(x)
	} else {
		x <- factor(x, ordered=T)
	}
	y <- factor(y, ordered=T) 
	fit <- polr(y~x+age, Hess=TRUE)
	ct <- coeftest(fit)	
	p_v <- ct[,"Pr(>|t|)"][-nrow(ct)]
		idx <- which.median(p_v)
		pvalue <- p_v[idx]
#	pvalue = min(ct[,"Pr(>|t|)"][-nrow(ct)])
#	idx = which.min(ct[,"Pr(>|t|)"][-nrow(ct)])
#	group = names(idx)
	beta = ct[idx, "Estimate"]
	return(c(pvalue, beta))
}

result1 <- data.frame(pvalue=rep(NA,nrow(tmp)/3), 
					 beta=rep(NA,nrow(tmp)/3),
#					 group=rep(NA,nrow(tmp)/3), 
					 row.names = paste("r", seq(1,nrow(tmp),3), sep = "_"))

result2 <- data.frame(pvalue=rep(NA,nrow(tmp)/3), 
					 beta=rep(NA,nrow(tmp)/3), 
#					 group=rep(NA,nrow(tmp)/3), 
					 row.names = paste("r", seq(2,nrow(tmp),3), sep = "_"))
	
if (isOrdinal1 && isOrdinal2){

	for (i in seq(1,nrow(tmp),3)) {
			pval_beta <- sumLogit(tmpT[,i], tmpT[,i+1], isOrdinal2, tmpT[,i+2])
			result1[paste("r", i, sep = "_"), 'pvalue'] = pval_beta[1] 
			result1[paste("r", i, sep = "_"), 'beta'] = pval_beta[2] 
#			result1[paste("r", i, sep = "_"), 'group'] = pval_beta[3]
	}

	for (i in seq(2,nrow(tmp),3)) {
			pval_beta <- sumLogit(tmpT[,i], tmpT[,i-1], isOrdinal1, tmpT[,i+1])
			result2[paste("r", i, sep = "_"), 'pvalue'] = pval_beta[1] 
			result2[paste("r", i, sep = "_"), 'beta'] = pval_beta[2] 
#			result2[paste("r", i, sep = "_"), 'group'] = pval_beta[3]
	}	

} else if (isOrdinal1 && !isOrdinal2) {
		
	for (i in seq(1,nrow(tmp),3)) {
			pval_beta <- sumLogit(tmpT[,i], tmpT[,i+1], isOrdinal2, tmpT[,i+2])
			result1[paste("r", i, sep = "_"), 'pvalue'] = pval_beta[1] 
			result1[paste("r", i, sep = "_"), 'beta'] = pval_beta[2] 
	}

	for (i in seq(2,nrow(tmp),3)) {
			pval_beta <- sumMultinom(tmpT[,i], tmpT[,i-1], isOrdinal1, tmpT[,i+1])
			result2[paste("r", i, sep = "_"), 'pvalue'] = pval_beta[1] 
			result2[paste("r", i, sep = "_"), 'beta'] = pval_beta[2] 
	}	

} else if (!isOrdinal1 && isOrdinal2) {
	
	for (i in seq(1,nrow(tmp),3)) {
			pval_beta <- sumMultinom(tmpT[,i], tmpT[,i+1], isOrdinal2, tmpT[,i+2])
			result1[paste("r", i, sep = "_"), 'pvalue'] = pval_beta[1] 
			result1[paste("r", i, sep = "_"), 'beta'] = pval_beta[2] 
	}

	for (i in seq(2,nrow(tmp),3)) {
			pval_beta <- sumLogit(tmpT[,i], tmpT[,i-1], isOrdinal1, tmpT[,i+1])
			result2[paste("r", i, sep = "_"), 'pvalue'] = pval_beta[1] 
			result2[paste("r", i, sep = "_"), 'beta'] = pval_beta[2] 
	}	
} else {
	for (i in seq(1,nrow(tmp),3)) {
			pval_beta <- sumMultinom(tmpT[,i], tmpT[,i+1], isOrdinal2, tmpT[,i+2])
			result1[paste("r", i, sep = "_"), 'pvalue'] = pval_beta[1] 
			result1[paste("r", i, sep = "_"), 'beta'] = pval_beta[2] 
	}

	for (i in seq(2,nrow(tmp),3)) {
			pval_beta <- sumMultinom(tmpT[,i], tmpT[,i-1], isOrdinal1, tmpT[,i+1])
			result2[paste("r", i, sep = "_"), 'pvalue'] = pval_beta[1] 
			result2[paste("r", i, sep = "_"), 'beta'] = pval_beta[2] 
	}	
}

beta_median1 <- median(result1$beta)
pvalue_median1 <- result1$pvalue[which(result1$beta==beta_median1)]
beta_median2 <- median(result2$beta)
pvalue_median2 <- result2$pvalue[which(result2$beta==beta_median2)]

if (pvalue_median1<=pvalue_median2){
		m_t <- data.frame(pvalue=pvalue_median2, beta=beta_median2, row.names="median")
		res <- t(rbind(m_t, result2))
} else {
		m_t <- data.frame(pvalue=pvalue_median1, beta=beta_median1, row.names="median")
		res <- t(rbind(m_t, result1))
}

write.table(x=res, file = paste0(tmpF, ".median"), quote = FALSE, row.names = FALSE, col.names = FALSE, fileEncoding = "UTF-8")
