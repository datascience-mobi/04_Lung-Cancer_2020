library(GEOquery)
library(dplyr)

#Import the GEO dataset
gse <- getGEO("GSE30219")

#Import and extract hte id mapping informations
gpl <- getGEO("GPL570")
gpl <- gpl@dataTable
gpl <- gpl@table
gpl <- gpl[gpl$`Sequence Type` == "Consensus sequence" & gpl$`Gene Symbol` != "",]

#Format the mapping information from probe ID to gene symbole in the form of a names vector
gpl_mapper <- gsub(" .*","",gpl$`Gene Symbol`) 
names(gpl_mapper) <- gpl$ID

#Extract the expression matrix
datExpr = as.data.frame(exprs(gse[[1]]))

#Replace affymetrix probe IDs with gene symbols
datExpr$ID <- row.names(datExpr)
datExpr <- datExpr[datExpr$ID %in% names(gpl_mapper),]
for(i in 1:length(datExpr[,1]))
{
  if(datExpr[i,"ID"] %in% names(gpl_mapper))
  {
    datExpr[i,"ID"] <- gpl_mapper[datExpr[i,"ID"]]
  } else {
    datExpr[i,"ID"] <- "______"
  }
}
datExpr <- datExpr[!grepl("______",datExpr$ID),]

##Alternativ e probes need to be summarised. For affymetrix microaray, I guess that median is the best
datExpr <- datExpr %>% group_by(ID) %>% summarise_each(funs(median(., na.rm = TRUE)))
datExpr <- as.data.frame(datExpr)

#now that genes are unique, we can use them as row names
row.names(datExpr) <- datExpr$ID
datExpr <- datExpr[,-1]

#let's rename the columns
names(datExpr) <- as.character(gse$GSE30219_series_matrix.txt.gz$title)

#let's compile some clinical infos as well
sample_infos <- as.data.frame(cbind(as.character(gse$GSE30219_series_matrix.txt.gz$title),gse$GSE30219_series_matrix.txt.gz$`gender:ch1`))
names(sample_infos) <- c("title","gender")
sample_infos$tissue <- gse$GSE30219_series_matrix.txt.gz$`tissue:ch1`
sample_infos$status <- gse$GSE30219_series_matrix.txt.gz$`status:ch1`
sample_infos$pt_stage <- gse$GSE30219_series_matrix.txt.gz$`pt stage:ch1`
sample_infos$pm_stage <- gse$GSE30219_series_matrix.txt.gz$`pm stage:ch1`
sample_infos$pn_stage <- gse$GSE30219_series_matrix.txt.gz$`pn stage:ch1`
sample_infos$relapse <- gse$GSE30219_series_matrix.txt.gz$`relapse (event=1; no event=0):ch1`
sample_infos$hystology <- gse$GSE30219_series_matrix.txt.gz$`histology:ch1`
sample_infos$age <- gse$GSE30219_series_matrix.txt.gz$`age at surgery:ch1`
sample_infos$follow_up_time <- gse$GSE30219_series_matrix.txt.gz$`follow-up time (months):ch1`
