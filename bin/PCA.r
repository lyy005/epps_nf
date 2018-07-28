#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

args[1]
args[2]

# Figure - PCoA Plot
library(vegan)
library(ggrepel)
library(ggplot2)

x <- read.table(args[1], head=T)
xPA=(x>1)*1         # remove the species presents less than 1 time

samplePA.dist=vegdist(t(xPA),method="jaccard")  # estimate the beta diversity
samplePA.pcoa=cmdscale(samplePA.dist)           # PCoA analysis
samplePA.pcoa2 <- data.frame(samplePA.pcoa)
samplePA.pcoa2$label <- row.names(samplePA.pcoa2)
pdf(args[2]) 
ggplot(samplePA.pcoa2, aes(x=X1, y=X2))+
  geom_point(shape = 21,size=3, stroke=1)+
  geom_text_repel(aes(label = samplePA.pcoa2$label), show.legend=F)+
  theme_classic()+ xlab("PCoA1") + ylab("PCoA2")
dev.off() 


