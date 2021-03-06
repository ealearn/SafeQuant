# TODO: Add comment
# 
# Author: erikahrne
###############################################################################

source("/Users/erikahrne/dev/R/workspace/SafeQuant/exec/caseStudy/initCaseStudySession.R")


### LOAD DATA

load("/Users/erikahrne/dev/R/workspace/SafeQuant/data/zavolanMouseLFQvsTMT6.rda")
ls(pattern="*eset")
### same protein annotations for TMT and LFQ
#fData(esetLFQSpectrum)$proteinName <- fData(esetTMTPeptide[as.character(fData(esetLFQSpectrum)$peptide),])$proteinName

### LOAD DATA END

# re-run createZavolanMouseLFQTvsTMT6estData.R (2 peptide per protein cutoff)

# get protein level reference ratios from LFQ data

# create protein sqa objects
sqaLFQProtein <- safeQuantAnalysis(esetLFQProtein,method="global")
sqaTMTProtein <- safeQuantAnalysis(esetTMTProtein,method="global")

# create spectrum sqa objects
sqaTMTSpectrum <- safeQuantAnalysis(esetTMTSpectrum,method="global")

ratioTMT <-  sqaTMTSpectrum$ratio[,1]


### NO FILTERING
ratioLFQ <- sqaLFQProtein$ratio[ as.character(fData(sqaTMTSpectrum$eset)$proteinName) ,]

# calculate interferemce level , Rref = LFQ2/LFQ1 , il = (TMT2 - Rref*TMT1) / (1-Rref) 
tmtMedianPerCond <-  getSignalPerCondition(sqaTMTSpectrum$eset)
tmtMinInt <- apply(sqaTMTSpectrum$eset,1,min)
tmtInterference <- (tmtMedianPerCond[,2]- (2^ratioLFQ)*tmtMedianPerCond[,1]) / (1-(2^ratioLFQ))

tmpSel <- is.na(tmtInterference)
tmtInterference[tmpSel] <- 0
tmtInterference[(tmtInterference > tmtMinInt) |  (tmtInterference < 0)] <- tmtMinInt[(tmtInterference > tmtMinInt) |  (tmtInterference < 0)  ]
tmtInterference[tmpSel] <- NA

#ratioDelta <- (abs(ratioLFQ) - abs(ratioTMT))*sign(ratioLFQ)*sign(ratioTMT)

## plot minInt vs. interference
plotXYDensity(log2(tmtMinInt)[ (tmtInterference != tmtMinInt)], log2(tmtInterference)[ (tmtInterference != tmtMinInt)])
plotXYDensity(log2(tmtMinInt)[ (tmtInterference != tmtMinInt) & (abs(sqaTMTSpectrum$ratio[,1]) > 2)], log2(tmtInterference)[ (tmtInterference != tmtMinInt) & (abs(sqaTMTSpectrum$ratio[,1]) > 2)])
#abline(h=0, lty=2)


plotXYDensity(log2(tmtInterference)[ (tmtInterference != tmtMinInt)], log2( apply(data.frame(exprs(esetLFQProtein))[as.character(fData(esetTMTSpectrum)$proteinName),],1,sum))[ (tmtInterference != tmtMinInt)] )


plotXYDensity(
		log2( apply(data.frame(exprs(esetLFQProtein))[as.character(fData(esetTMTSpectrum)$proteinName),],1,sum))[ (tmtInterference != tmtMinInt)],
		(tmtInterference/tmtMinInt)[ (tmtInterference != tmtMinInt)]  )


boxplot( (tmtInterference/tmtMinInt)[ (tmtInterference != tmtMinInt)] ~  fData(esetLFQProtein)[as.character(fData(esetTMTSpectrum)$proteinName),]$nbRolledFeatures.1[ (tmtInterference != tmtMinInt)] )


plotXYDensity(
	 
		fData(esetLFQProtein)[as.character(fData(esetTMTSpectrum)$proteinName),]$nbRolledFeatures.1[ (tmtInterference != tmtMinInt)],
		(tmtInterference/tmtMinInt)[ (tmtInterference != tmtMinInt)] 
)


library(MASS)

i <- tmtInterference[ (tmtInterference != tmtMinInt)] 
a <- tmtMinInt[ (tmtInterference != tmtMinInt)] 
#b <- as.factor(fData(esetTMTProtein)[as.character(fData(esetTMTSpectrum)$proteinName),]$nbRolledFeatures.1[ (tmtInterference != tmtMinInt)])
b <- fData(esetTMTProtein)[as.character(fData(esetTMTSpectrum)$proteinName),]$nbRolledFeatures.1[ (tmtInterference != tmtMinInt)]


d <- data.frame(i,a,b)



fit <- rlm(i ~ a +  a:b,data=d, weights=1/sqrt(i))
#fit <- lm(i ~ a+  a:b, , weights=1/sqrt(i))
summary(fit)

#i <- tmtInterference
#a <- tmtMinInt
#b <- as.factor(fData(esetTMTProtein)[as.character(fData(esetTMTSpectrum)$proteinName),]$nbRolledFeatures.1)
#d <- data.frame(i,a,b)

pred <- predict(fit,newdata=d)
plotXYDensity(log(pred) , log(i) ) 

#predInterference <- (tmtMinInt * 0.8) 

predInterference <- rep(NA,nrow(tmtMedianPerCond))
predInterference[as.numeric(names(pred))] <- pred

tmtMedianPerCondAdjusted <- tmtMedianPerCond - predInterference 
 apply(tmtMedianPerCondAdjusted,1,min,na.rm=T )

ratioTMTAdjusted <- log2(tmtMedianPerCondAdjusted[,2] / tmtMedianPerCondAdjusted[,1])

plotXYDensity(ratioLFQ,ratioTMTAdjusted)


iPred <- coef(fit)[1] + coef(fit)[2]*a+ coef(fit)[3]*b+  coef(fit)[4]*a*b

plotXYDensity(log(pred) , log(iPred[as.numeric(names(pred))]) ) 


plotXYDensity(log2(tmtMinInt)[ (tmtInterference != tmtMinInt) & !is.na(ratioLFQ) & (abs(ratioLFQ) > 0)], log2(tmtInterference)[ (tmtInterference != tmtMinInt) & !is.na(ratioLFQ) & (abs(ratioLFQ) > 0)]) 
# gloally 55% of tmtMinInt is noise

plotXYDensity(log2(tmtMinInt), log2(tmtInterference)) 
# gloally 72% of tmtMinInt is noise

plotXYDensity(log2(tmtMinInt)[ (tmtInterference != tmtMinInt) & !is.na(ratioLFQ) & (abs(ratioLFQ) > 1)], log2(tmtInterference)[ (tmtInterference != tmtMinInt) & !is.na(ratioLFQ) & (abs(ratioLFQ) > 1)])
plotXYDensity(log2(tmtMinInt)[ (tmtInterference != tmtMinInt) & !is.na(ratioLFQ) & (abs(ratioLFQ) > 2)], log2(tmtInterference)[ (tmtInterference != tmtMinInt) & !is.na(ratioLFQ) & (abs(ratioLFQ) > 2)])
plotXYDensity(log2(tmtMinInt)[ (tmtInterference != tmtMinInt) & !is.na(ratioLFQ) & (abs(ratioLFQ) > 2.5)], log2(tmtInterference)[ (tmtInterference != tmtMinInt) & !is.na(ratioLFQ) & (abs(ratioLFQ) > 2.5)])

print("DONE")

plot(c(1:10),(c(1:10))/0.3)

plot(c(1:10)-1,(c(1:10) - 1)/0.3)

plotXYDensity(log2(tmtInterference)[(tmtInterference != tmtMinInt) & !is.na(ratioLFQ)] , log2(fData(sqaTMTSpectrum$eset)$ms1Int)[(tmtInterference != tmtMinInt) & !is.na(ratioLFQ)])

boxplot(log2(tmtInterference) ~ signif(fData(sqaTMTSpectrum$eset)$mzFreq,1))
boxplot(tmtInterference/tmtMinInt ~ signif(fData(sqaTMTSpectrum$eset)$mzFreq,1))

plotXYDensity(fData(sqaTMTSpectrum$eset)$mzFreq, tmtInterference/tmtMinInt  )


boxplot(log2(tmtInterference) ~ I(round((fData(sqaTMTSpectrum$eset)$injectionTime+5)/10)*10))

boxplot(log2(tmtInterference) ~ fData(sqaTMTSpectrum$eset)$charge)

boxplot(tmtInterference/tmtMinInt ~ fData(sqaTMTSpectrum$eset)$charge)

boxplot(tmtInterference/tmtMinInt ~ I(round((fData(sqaTMTSpectrum$eset)$injectionTime+5.1)/10)*10))

tmtMedianPerCondAdjusted <- tmtMedianPerCond - (tmtMinInt * 0.72) 
ratioTMTAdjusted <- log2(tmtMedianPerCondAdjusted[,2] / tmtMedianPerCondAdjusted[,1])

plotXYDensity(ratioTMT,ratioTMTAdjusted)
abline(coef=c(0,1))

plotXYDensity(log2(apply(sqaTMTSpectrum$eset,1,min)), log2(fData(sqaTMTSpectrum$eset)$ms1Int))
plotXYDensity(log2(apply(sqaTMTSpectrum$eset,1,max)), log2(fData(sqaTMTSpectrum$eset)$ms1Int))


boxplot(log2(apply(sqaTMTSpectrum$eset,1,sum)) ~ fData(sqaTMTSpectrum$eset)$charge)

### HERE
plotXYDensity(ratioLFQ,ratioTMT)
plotXYDensity(ratioLFQ,ratioTMTAdjusted)

### DIAGNOSTIC PLOTS



plotXYDensity(abs(ratioLFQ),abs(ratioTMT))

plotXYDensity(log2(apply(exprs(sqaTMTSpectrum$eset),1,min)), abs(ratioLFQ)-abs(ratioTMT))


fit <- lm(abs(ratioLFQ) ~ I(abs(ratioTMT)) : log2(apply(exprs(sqaTMTSpectrum$eset),1,sum)) )

summary(fit)

pred <- predict(fit)


plotXYDensity(abs(ratioLFQ[as.numeric(names(pred))]),pred)

plotXYDensity(abs(ratioTMT[as.numeric(names(pred))]),pred)






