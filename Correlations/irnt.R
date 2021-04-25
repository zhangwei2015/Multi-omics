args <- commandArgs(trailingOnly = TRUE)
print(args[1])
pheno <- scan(file = args[1], what = numeric(), sep = " ")

irnt <- function(pheno) {
	set.seed(1234)
	numPhenos = length(which(!is.na(pheno)))
	quantilePheno = (rank(pheno, na.last="keep", ties.method="random")-0.5)/numPhenos
	phenoIRNT = qnorm(quantilePheno)	
	return(phenoIRNT);
}


phenoIRNT = irnt(pheno) 

write(x = phenoIRNT,
	  file = paste0(args[1],".IRNT"), ncolumns = length(phenoIRNT))
