#!/usr/local/bin/Rscript

# Read command line options
cat("\nReading Command-line arguments .....\n")
aCmdLineOptions <- commandArgs(TRUE)

stopifnot(length(aCmdLineOptions) > 3)

# RPKM Sample Info File
cat("\nReading RPKM Sample Info Filename .....\n")
sSampleInfo = aCmdLineOptions[1]

# Read Gene ID Column Number
cat("\nReading Gene ID Column # .....\n")
nGeneIDCol = as.numeric(aCmdLineOptions[2])

# Read RPKM Column Number
cat("\nReading RPKM Column # .....\n")
nRPKMCol = as.numeric(aCmdLineOptions[3])

# Initialize output directory
cat("\nReading output directory .....\n")
sOutDir = aCmdLineOptions[4]

# Initialize output prefix
cat("\nReading output prefix .....\n")
sPrefix = aCmdLineOptions[5]

# Initialize plot title
cat("\nReading plot title .....\n")
sTitle = aCmdLineOptions[6]

# Does the input filename have a header line
bHeader = "FALSE"
if( !(is.na(aCmdLineOptions[7])) ) {
	bHeader = as.logical(aCmdLineOptions[7])
	cat("\nDoes the input filename have a header line .....", bHeader, "\n")
	
}

# Access content of sample info file
cat("\nReading contents of input file", sSampleInfo, ".....\n")
oS = read.delim(sSampleInfo, sep="\t", header=F)

# Extract coverage rpkm for samples from data frame oS
oBox = list()
aYLim = NULL

sample = list()
nI = 1
while (nI <= nrow(oS)) {
	
	sFile = as.character(oS[nI,1])
	tmp <- gsub(".*/", "", as.character(sFile), perl=TRUE)
	sSID <- gsub(".bowtie.*|.accepted_hits.*", "", tmp, perl=TRUE)
	sample[nI] <- sSID
	
	cat("\nReading Total.RPKM for", sSID, ".....\n")
	oD = read.delim(sFile, sep="\t", header=isTRUE(bHeader),comment.char = "#")
	
	oR = oD[,c(nGeneIDCol,nRPKMCol)]
	colnames(oR) = c("Gene.ID", paste("Norm.Cvg.RPKM", sSID, sep="."))
	
	# RPKM Histogram before filtering
	cat("\nPlotting RPKM Histogram .....\n")
	pdf(paste(sOutDir, "/", sSID,".",sTitle,".Histogram.pdf", sep=""))
	hist(log2(oR$Norm.Cvg.RPKM), breaks=200, main=sSID, xlab="log2(RPKM)", ylab="# Genes", col="blue")
	dev.off()
	
	oBox[[sSID]] = density(log2(oR$Norm.Cvg.RPKM))
	
	aYLim = c(aYLim, oBox[[sSID]]$y)
	
	nI = nI + 1
}

cat("\nPlotting RPKM Ratio Boxplots .....\n")
pdf(paste(sOutDir, "/", sPrefix,".",sTitle,".Density.Plots.pdf", sep=""))

sSID = as.character(sample[1])

oD = oBox[[sSID]]
aNames = c(sSID)

aYrange = range(aYLim)

plot(oD, main="Density.Plot", xlab=paste("log2(",sTitle,")",sep=""), ylab="Density", ylim=aYrange, lty=1, col=1)
aLty = c(1)

nI = 2
while (nI <= nrow(oS)) {
	sSID = as.character(sample[nI])
	oD = oBox[[sSID]]
	aNames = c(aNames, sSID)
	
	nLty = (((nI - 1) %/% 8) + 1)
	lines(oD, lty=nLty, col=nI)
	aLty = c(aLty, nLty)
	
	nI = nI + 1
}

legend("topright", legend=aNames, cex=0.6, col=(1:nrow(oS)), lwd=2, lty = aLty);

dev.off()

cat("\nAnalysis Complete .....\n")

