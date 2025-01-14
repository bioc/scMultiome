% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tfBinding.R
\name{tfBinding}
\alias{tfBinding}
\title{TF Binding Info}
\format{
\code{GRangesList} object containing binding site information
of transcription factor ChIP-seq.
Contains the following experiments:
\itemize{
\item{\strong{hg38_atlas}: GRangesList object of length 1558}
\item{\strong{hg19_atlas}: GRangesList object of length 1558}
\item{\strong{mm10_atlas}: GRangesList object of length 768}
\item{\strong{hg38_encode.sample}: List object of length 171}
\item{\strong{hg19_encode.sample}: List object of length 171}
\item{\strong{mm10_encode.sample}: List object of length 31}
\item{\strong{hg38_atlas.sample}: List object of length 1112}
\item{\strong{hg19_atlas.sample}: List object of length 1112}
\item{\strong{mm10_atlas.sample}: List object of length 517}
\item{\strong{hg38_atlas.tissue}: List object of length 22}
\item{\strong{hg19_atlas.tissue}: List object of length 22}
\item{\strong{mm10_atlas.tissue}: List object of length 23}
}
}
\usage{
tfBinding(
  genome = c("hg38", "hg19", "mm10"),
  source = c("atlas", "encode.sample", "atlas.sample", "atlas.tissue"),
  version = 2,
  metadata = FALSE,
  peak_number = 1000
)
}
\arguments{
\item{genome}{character string specifying the genomic build}

\item{source}{character string specifying the ChIP-seq data source}

\item{version}{numeric indicating data version number (see Details)}

\item{metadata}{logical flag specifying whether to return data or metadata only}

\item{peak_number}{numeric indicating threshold to be applied number of peaks
per transcription factor in the combined version of GenomicRanges
(from all samples and tissues).}
}
\value{
A list of TF binding sites as a \code{GrangesList} object.
}
\description{
Combined transcription factor ChIP-seq data from ChIP-Atlas and ENCODE
}
\details{
This is a special data set that stores transcription factor binding sites for human and
mouse genomic builds, which can be used with the package epiregulon to compute regulons.

In version 2 chipatlas sample and tissue GenomicRanges were build using experiments
with at least 2E7 unique reads and 1E3 peaks. In sample specific encode
chip-seq data a quality metrics was number of peaks only.
}
\section{Data storage and access}{

Each genomic build is a separate \code{GRangesList} object, stored in a separate RDS file.
All genomic builds can be accessed with the same function \code{tfBinding}.
}

\section{Data preparation}{

\subsection{1. Data download}{

We download public ChIP-seq peak calls from ChIP-Atlas and ENCODE
}

\subsection{1.1. ChIP-Atlas}{

ChIP-seq binding sites were downloaded from \href{https://github.com/inutano/chip-atlas/wiki}{ChIP-Atlas}

\if{html}{\out{<div class="sourceCode r">}}\preformatted{# metatdata 
# download fileList.tab from https://dbarchive.biosciencedbc.jp/kyushu-u/metadata/fileList.tab

dir <- "chipAtlas/"
fileLIST <- read.delim(file.path(dir, "metadata/fileList.tab"), header = FALSE)


for (genome in c("hg38", "mm10"))\{
    
    TFLIST <- fileLIST[which(fileLIST[,3] == "TFs and others" &
                                 fileLIST[,2] == genome &
                                 fileLIST[,4] != "-" &
                                 fileLIST[,5] == "All cell types" &
                                 fileLIST[,7] == "05"),]
    
    download.files <- paste0("wget http://dbarchive.biosciencedbc.jp/kyushu-u/", 
                             genome,"/assembled/", TFLIST$V1, ".bed")
    write.table(x = download.files,
                file = file.path(dir, genome, ".sh"),
                quote = FALSE,
                col.names = FALSE,
                row.names = FALSE)
    
    write.table(TFLIST,
                file = file.path(dir, genome,".metadata.txt"),
                quote = FALSE,
                col.names = FALSE,
                row.names = FALSE,
                sep = "\\t")
    
\}

}\if{html}{\out{</div>}}

Download bed files by sample

\if{html}{\out{<div class="sourceCode r">}}\preformatted{for (genome in c("mm10","hg38"))\{
   metadata <- read.delim("experimentList.tab", header=FALSE)
   metadata <- metadata[metadata$V2 == genome,]
   metadata <- metadata[metadata$V3 == "TFs and others",]


# write files for download
fileConn <- file(paste0("data/download.tissue.", genome,".txt"))
writeLines(paste0("wget -nc https://chip-atlas.dbcls.jp/data/", genome,"/eachData/bed05/", metadata$V1,".05.bed"), fileConn)
close(fileConn)
\}
}\if{html}{\out{</div>}}
}

\subsection{1.2. ENCODE}{

Transcription factor ChIP-seq peaks were downloaded from \href{https://www.encodeproject.org/}{ENCODE data portal}
}

\subsection{2. Merge peaks}{

Merge peaks of the same TFs into the same bed files.
}

\subsection{2.1. ChIP-Atlas}{

\if{html}{\out{<div class="sourceCode r">}}\preformatted{
library(GenomicRanges)
library(rtracklayer)

##################### chipatlas_bedfiles_merge #####################
## Takes in a list of bed files and an accompanying legend that shows 
## which BED files correspond to  a specific TF
## Outputs a directory of merged bed files

dir <- 'chipAtlas/'
outdir <- 'chipatlas/data/chipatlas'



genomes <- c("mm10","hg38")
chr_order <- list()
chr_order[["mm10"]] <- c(paste0("chr",1:19),"chrX","chrY","chrM")
chr_order[["hg38"]] <- c(paste0("chr",1:22),"chrX","chrY","chrM")

for (genome in genomes)\{
  # Get directories of all bed files and make a list of the path of all bed files
  list_beds <- list.files(file.path(dir, paste0(genome, '_1e5')),
                          pattern = "*.bed")

  # Read the metatdata file

  metadata <- read.delim(file.path(dir, genome, ".metadata.txt"), header=FALSE)
  metadata$filename <- file.path(dir, genome, "_1e5", metadata$V1,".bed")
  colnames(metadata)[4] <- "TF"

  ## specify sorting order for chromosomes
  chr_order_genome <- chr_order[[genome]]

  ### get list of TFs represented in BED files
  TF.list <- unique(metadata$TF)

  for (i in seq_along(TF.list)) \{

    print(TF.list[i])

    # get bed files associated with TF
    TF.files <- metadata[which(metadata$TF == TF.list[i]), "filename"]

    # merge bed files and sort by chromosome and starting coordinate

    merged_bed <- as.data.frame(rtracklayer::import.bed(file_name))
    merged_bed$seqnames <- factor(merged_bed$seqnames, levels = chr_order_genome)
    merged_bed <- na.omit(merged_bed)
    merged_bed <- merged_bed[order(merged_bed$seqnames, merged_bed$start),]

    ## convert to granges object and merge overlapping ranges
    gr <- makeGRangesFromDataFrame(merged_bed,
                                   seqnames.field = "seqnames",
                                   start.field = "start",
                                   end.field = "end")
    gr <- reduce(gr, drop.empty.ranges = TRUE)

    # write new bed file to directory
    export.bed(gr, con = file.path(outdir, genome, TF.list[i],".bed"))
  \}

\}
}\if{html}{\out{</div>}}
}

\subsection{2.2. ENCODE}{

Filter and merge ENCODE peaks

\if{html}{\out{<div class="sourceCode r">}}\preformatted{############### filter peaks ####################
## Takes in bed files and filters the peaks 
## in each file based on the enrichment score.
## Low Enrichment peaks are filtered out.

dir = 'encode/'
outdir = 'chipatlas/data/encode/'
for (genome in c("mm10", "hg38"))\{

    # Make a list of all the bed files
    list_beds <- list.files(file.path(dir, genome, "raw"), pattern = "*.bed.gz")

    #filter each bed file to have p value score > 4
    for (i in seq_along(list_beds)) \{

        print(list_beds[i])

        curr_bed <- read.table(file.path(dir, genome, "raw", list_beds[i]))

        post_QC_bed <- curr_bed[curr_bed$V7 >=5,] #Q values

        if (nrow(post_QC_bed) >100)\{
            write.table(post_QC_bed,
                        file.path('/gstore/scratch/u/yaox19/encode/', 
                               genome, "filtered", list_beds[i]),
                        row.names = F, col.names = F, quote = F, sep="\\t")
        \}

    \}
\}




##################### ENCODE_bedfiles_merge #####################
## Takes in a list of bed files and an accompanying legend that shows 
## which BED files correspond to  a specific TF
## Outputs a directory of merged bed files



chr_order <- list()
chr_order[["mm10"]] <- c(paste0("chr",1:19),"chrX","chrY","chrM")
chr_order[["hg38"]] <- c(paste0("chr",1:22),"chrX","chrY","chrM")

replacement <- list(mm10 = "-mouse", hg38 = "-human")

for (genome in c("hg38","mm10"))\{

    # read metadata
    list_beds <- list.files(file.path(dir, genome, "raw"), pattern = "*.bed.gz")
    metadata <- read.delim(file.path(dir, genome, "raw", "metadata.tsv"))
    if(genome == "hg38") metadata <- metadata[metadata$"File.assembly"=="GRCh38",]
    metadata <- metadata[, c("File.accession", "Experiment.target")]
    metadata$"Experiment.target" <-  gsub(replacement[[genome]],"", metadata$"Experiment.target")

    # capitalize the first alphabet for mouse genes
    if (genome == "mm10")\{
        metadata$"Experiment.target" <- stringr::str_to_title(metadata$"Experiment.target")
    \}

    metadata$"File.accession" <- trimws( metadata$"File.accession")
    metadata$"File.accession" <- file.path(dir, genome, "filtered",
                                        metadata$"File.accession",".bed.gz")
    colnames(metadata) <- c("filename","TF")

    # remove files that do not exist
    metadata <- metadata[which(file.exists(metadata$filename)),]

    # specify sorting order for chromosomes
    chr_order_genome <- chr_order[[genome]]

    # get list of TFs represented in BED files
    TF.list <- unique(metadata$TF)

    for (i in seq_along(TF.list)) \{

        print(TF.list[i])

        # get bed files associated with TF
        TF.files <- metadata[which(metadata$TF == TF.list[i]), "filename"]

        # merge bed files and sort by chromosome and starting coordinate
          extraCols_narrowPeak <- c(singnalValue = "numeric", pValue = "numeric",
                            qValue = "numeric", peak = "integer")
        merged_bed <- lapply(TF.files, function(file) as.data.frame(rtracklayer::import.bed(file, extraCols = extraCols_narrowPeak)))
        merged_bed <- do.call('rbind', merged_bed)
        merged_bed$seqnames <- factor(merged_bed$seqnames, levels = chr_order[[genome]])
        merged_bed <- merged_bed[!is.na(merged_bed$seqnames),]
        merged_bed <- merged_bed[order(merged_bed$seqnames, merged_bed$start),]

        # convert to granges object and merge overlapping ranges
        gr <- makeGRangesFromDataFrame(merged_bed,
                                       seqnames.field = "V1",
                                       start.field = "V2",
                                       end.field = "V3")
        gr <- reduce(gr, drop.empty.ranges = TRUE)

        # write new bed file to directory
        export.bed(gr, con=file.path(outdir, genome, TF.list[i],".bed"))
    \}




\}
}\if{html}{\out{</div>}}
}

\subsection{2.3. Merge both ENCODE and ChIP-Atlas}{

\if{html}{\out{<div class="sourceCode r">}}\preformatted{
dir <- "chipatlas/data/"

chr_order <- list()
chr_order[["mm10"]] <- c(paste0("chr",1:19),"chrX","chrY","chrM")
chr_order[["hg38"]] <- c(paste0("chr",1:22),"chrX","chrY","chrM")


for (genome in c("mm10", "hg38"))\{

    # specify sorting order for chromosomes
    chr_order_genome <- chr_order[[genome]]

    ########### merge with chipatlas bed files
    chipatlas.files <- list.files(file.path(dir, "chipatlas", genome),pattern = "*.bed")
    encode.files <- list.files(file.path(dir, "encode", genome),pattern = "*.bed")
    shared.TFs <- intersect(chipatlas.files, encode.files)
    chipatlas.TFs <- setdiff(chipatlas.files, encode.files)
    encode.TFs <- setdiff(encode.files, chipatlas.files)
    combined_grl <- GRangesList()
    #### shared.TFs
    for (i in seq_along(shared.TFs)) \{

        print(shared.TFs[i])

        chipatlas <- as.data.frame(import.bed(file.path(dir, "chipatlas", genome, shared.TFs[i])))
        encode <- as.data.frame(import.bed(file.path(dir, "encode", genome, shared.TFs[i])))

        merged_bed <- rbind(chipatlas[,1:3], encode[,1:3])
        merged_bed$seqnames <- factor(merged_bed$seqnames, levels = chr_order_genome)
        merged_bed <- merged_bed[!is.na(merged_bed$seqnames),]
        merged_bed <- merged_bed[order(merged_bed$seqnames, merged_bed$start),]

        gr <- makeGRangesFromDataFrame(merged_bed,seqnames.field = "seqnames",
                                   start.field = "start",end.field = "end")
        gr <- reduce(gr_merged, drop.empty.ranges = TRUE)
        combined_grl <- c(combined_grl, GRangesList(gr))
        export.bed(gr, con=file.path(dir, "chipatlas_encode_merged", genome, shared.TFs[i]))

    \}

    ##### chipatlas
    for (i in seq_along(chipatlas.TFs)) \{

        print(chipatlas.TFs[i])

        chipatlas <- as.data.frame(import.bed(file.path(dir, "chipatlas", genome, chipatlas.TFs[i])))

        merged_bed <- chipatlas[,1:3]
        merged_bed$seqnames <- factor(merged_bed$seqnames, levels = chr_order_genome)
        merged_bed <- merged_bed[!is.na(merged_bed$seqnames),]
        merged_bed <- merged_bed[order(merged_bed$seqnames, merged_bed$start),]
    
        gr <- makeGRangesFromDataFrame(merged_bed,seqnames.field = "seqnames",
                                       start.field = "start",end.field = "end")
        gr <- reduce(gr, drop.empty.ranges = TRUE)
        combined_grl <- c(combined_grl, GRangesList(gr))
        export.bed(gr, con=file.path(dir, "chipatlas_encode_merged", genome, chipatlas.TFs[i]))

    \}

    ##### encode
    for (i in seq_along(length(encode.TFs))) \{

        print(encode.TFs[i])

        chipatlas <- as.data.frame(import.bed(file.path(dir, "encode", genome, encode.TFs[i])))

        merged_bed <- chipatlas[,1:3]
        merged_bed$seqnames <- factor(merged_bed$seqnames, levels = chr_order_genome)
        merged_bed <- merged_bed[!is.na(merged_bed$seqnames),]
        merged_bed <- merged_bed[order(merged_bed$seqnames, merged_bed$start),]
    
        gr <- makeGRangesFromDataFrame(merged_bed,seqnames.field = "seqnames",
                                       start.field = "start",end.field = "end")
        gr <- reduce(gr, drop.empty.ranges = TRUE)
        combined_grl <- c(combined_grl, GRangesList(gr))
        export.bed(gr, con=file.path(dir, "chipatlas_encode_merged", genome, encode.TFs[i]))
        saveRDS(grl, paste0(output_dir, "tfBinding_", genome,"_atlas.rds"))
    \}
\}
}\if{html}{\out{</div>}}
}

\subsection{2.4 Merge ChIP-Atlas peaks by sample}{

\if{html}{\out{<div class="sourceCode r">}}\preformatted{
library(rtracklayer)
#import metadata

for (genome in c("hg38","mm10"))\{
    metadata <- read.delim(paste0(data_dir, "chipAtlas/experimentList.tab"), header=FALSE)
    metadata <- metadata[metadata$V2 == genome,]
    metadata <- metadata[metadata$V3 == "TFs and others",]

    # add QC metrics - new in version 2
    metadata_qc <- do.call(rbind, strsplit(metadata$V8, split = ","))
    metadata_qc <- data.frame(apply(metadata_qc, 2, as.numeric))
    colnames(metadata_qc) <- c("Number.of.reads", "Percentage.mapped", "Percentage.duplicates", "Number.of.peaks")

    metadata <- cbind(metadata, metadata_qc)
    metadata$unique.reads <- round(metadata[,"Number.of.reads"]*
                                       metadata[,"Percentage.mapped"]*
                                       (100-metadata[,"Percentage.duplicates"])/10000)

    metadata <- metadata[which(metadata$unique.reads >= 20000000 &
                                   #metadata_qc$Percentage.mapped >= 70 &
                                   metadata$Number.of.peaks >= 1000), ]

    # import bed
    extraCols_narrowPeak <- c(singnalValue = "numeric", pValue = "numeric",
                              qValue = "numeric", peak = "integer")

    grl <- list()

    celllines <- unique(metadata$V6)
    celllines <- as.vector(na.omit(celllines))
    for (cellline in celllines)\{
        metadata.cellline <- metadata[which(metadata$V6 == cellline),]
        unique.tf <- unique(metadata.cellline$V4)

        for (tf in unique.tf)\{

            message("cell line = ", cellline, " ", "tf = ", tf)
            gr <- list()
            beds <- metadata.cellline$V1[metadata.cellline$V4 ==tf]

            if (length(beds) >0) \{
                counter <- 1
                for (bed in beds) \{
                    file <- paste0(data_dir, "chipAtlas/", genome, "_1e5_individual/", bed,".05.bed")

                    if (file.exists(file)) \{
                        # each gr list is per TF per tissue
                        gr[[counter]] <- try(rtracklayer::import(file, extraCols = extraCols_narrowPeak))
                        counter <- counter + 1
                    \}
                \}

                if (length(gr) > 0) \{
                    grl[[cellline]][[tf]] <- reduce(do.call(c, gr))
                \}
            \}
        \}

        if (length(grl[[cellline]])>0)\{
            grl[[cellline]] <- GRangesList(grl[[cellline]])

        \}
    \}
    saveRDS(grl, paste0(output_dir, "tfBinding_", genome,"_atlas.sample_v2.rds"))
\}

}\if{html}{\out{</div>}}
}

\subsection{2.5 Merge ChIP-Atlas peaks by tissue}{

\if{html}{\out{<div class="sourceCode r">}}\preformatted{library(rtracklayer)
#import metadata

for (genome in c("hg38","mm10"))\{
    metadata <- read.delim(data_dir, "chipAtlas/experimentList.tab", header=FALSE)
    metadata <- metadata[metadata$V2 == genome,]
    metadata <- metadata[metadata$V3 == "TFs and others",]

    # add QC metrics - new in version 2
    metadata_qc <- do.call(rbind, strsplit(metadata$V8, split = ","))
    metadata_qc <- data.frame(apply(metadata_qc, 2, as.numeric))
    colnames(metadata_qc) <- c("Number.of.reads", "Percentage.mapped", "Percentage.duplicates", "Number.of.peaks")

    metadata <- cbind(metadata, metadata_qc)
    metadata$unique.reads <- round(metadata[,"Number.of.reads"]*
                                       metadata[,"Percentage.mapped"]*
                                       (100-metadata[,"Percentage.duplicates"])/10000)

    metadata <- metadata[which(metadata$unique.reads >= 20000000 &
                                   metadata$Number.of.peaks >= 1000), ]
    # import bed
    extraCols_narrowPeak <- c(singnalValue = "numeric", pValue = "numeric",
                              qValue = "numeric", peak = "integer")

    grl <- list()
=
    tissues <- unique(metadata$V5)
    tissues <- as.vector(na.omit(tissues))

    for (tissue in tissues)\{
        metadata.tissue <- metadata[which(metadata $V5 == tissue),]
        unique.tf <- unique(metadata.tissue$V4)
        #
        for (tf in unique.tf)\{

            message("tissue = ", tissue," ", "tf = ", tf)
            gr <- list()
            beds <- metadata.tissue$V1[metadata.tissue$V4 ==tf]

            if (length(beds) >0) \{
                counter <- 1
                for (bed in beds) \{
                    file <- paste0(data_dir, "chip_peaks/", genome, "_1e5_individual/", bed,".05.bed")

                    if (file.exists(file)) \{
                    # each gr list is per TF per tissue
                        gr[[counter]] <- try(rtracklayer::import(file, extraCols = extraCols_narrowPeak))
                        counter <- counter + 1
                    \}

                \}

                if (length(gr) > 0) \{
                    grl[[tissue]][[tf]] <- GenomicRanges::reduce(do.call(c, gr))
                \}

            \}
        \}

        if (length(grl[[tissue]]) > 0) \{
            grl[[tissue]] <- GRangesList(grl[[tissue]])
        \}
    \}

    saveRDS(grl, paste0(output_dir, "tfBinding_", genome,"_atlas.tissue_v2.rds"))
\}

}\if{html}{\out{</div>}}
}

\subsection{2.6 Merge ENCODE peaks by sample}{

\if{html}{\out{<div class="sourceCode r">}}\preformatted{library(rtracklayer)

metadata.path <- c(GRCh38=paste0(data_dir,"encode/human"),
                   mm10=paste0(data_dir, "encode/mm10/encode"))

for (genome in c("GRCh38", "mm10"))\{

    metadata <- read.delim(file.path(metadata.path[genome], "raw","metadata.tsv"), header=TRUE)
    metadata <- metadata[metadata$File.assembly == genome,]
    metadata <- metadata[metadata$Assay == "TF ChIP-seq",]
    metadata <- metadata[metadata$Audit.NOT_COMPLIANT == "",]
    metadata <- metadata[metadata$Audit.ERROR == "",]
    metadata$Peaks <- NA
    rownames(metadata) <- metadata$File.accession

    # import bed
    extraCols_narrowPeak <- c(singnalValue = "numeric", pValue = "numeric",
                              qValue = "numeric", peak = "integer")

    grl <- list()

    celllines <- unique(metadata$Biosample.term.name)
    celllines <- as.vector(na.omit(celllines))
    for (cellline in celllines)\{
        metadata.cellline <- metadata[which(metadata $Biosample.term.name == cellline),]
        unique.tf <- unique(metadata.cellline$Experiment.target)

        for (tf in unique.tf)\{
            message("tf = ", tf, " ", "cell line = ", cellline)
            tf.name <- sapply(strsplit(tf, "-"),"[",1)
            beds <- metadata.cellline$File.accession[metadata.cellline$Experiment.target ==tf]

            gr <- list()

            if (length(beds) >0) \{

                for (bed in beds) \{
                    file <- file.path(metadata.path[genome], "raw", paste0(bed,".bed.gz"))

                    if (file.exists(file)) \{
                        temp_bed <- try(rtracklayer::import(file, extraCols = extraCols_narrowPeak))
                        peak_no <- length(temp_bed)
                        metadata[bed, "Peaks"] <- peak_no
                        if (peak_no > 1000) \{              # new in version 2
                            gr[[bed]] <- temp_bed
                        \}
                        rm(temp_bed)
                    \}
                \}
            \}

            if (length(gr) > 0)\{
                grl[[cellline]][[tf.name]] <- GenomicRanges::reduce(do.call(c, unname(gr)))
            \}
        \}

        if (length(grl[[cellline]])>0)\{
            grl[[cellline]] <- GRangesList(grl[[cellline]])

        \}
    \}
    saveRDS(grl, paste0(output_dir,"tfBinding_", genome,"_encode.sample_v2.rds"))
    write.table(metadata, paste0(output_dir, "encode.metadata.", genome, ".txt"), quote = FALSE, row.names = FALSE, sep = "\\t")
\}

}\if{html}{\out{</div>}}
}

\subsection{3. Liftover}{

Perform liftover from hg38 to hg19 for the ChIP-seq binding sites

\if{html}{\out{<div class="sourceCode r">}}\preformatted{# chain downloaded from https://hgdownload.soe.ucsc.edu/goldenPath/hg38/liftOver/hg38ToHg19.over.chain.gz
# need to reformat chain file from space to tab
# sed -r 's/^([0-9]+) ([0-9]+) ([0-9]+)$/\\1\\t\\2\\t\\3/' hg38ToHg19.over.chain > hg38_to_hg19_tabs.chain

ch <- rtracklayer::import.chain(con = "/chipatlas/data/hg38_to_hg19_tabs.chain")

library(liftOver)

# convert binding sites from ENCODE
grl_hg38 <- readRDS(paste0(output_dir,"tfBinding_", genome,"_encode.sample_v2.rds"))
grl_hg19 <- lapply(grl_hg38, liftOver, ch)
saveRDS(grl_hg19, file = paste0(output_dir,"tfBinding_hg19_encode.sample_v2.rds"))

# convert binding sites from ChIP Atlas

# convert grl by cell line
grl_hg38 <- readRDS(paste0(output_dir, "tfBinding_hg38_atlas.sample_v2.rds"))
grl_hg19 <- lapply(grl_hg38, liftOver, ch)
saveRDS(grl_hg19, file = paste0(output_dir, "tfBinding_hg19_atlas.sample_v2.rds")))

#convert grl by tissue
grl_hg38 <- readRDS(paste0(output_dir, "tfBinding_hg38_atlas.tissue_v2.rds"))
grl_hg19 <- lapply(grl_hg38, liftOver, ch)
saveRDS(grl_hg19, file = paste0(output_dir, "tfBinding_hg19_atlas.tissue_v2.rds"))

#convert combined grl
grl_hg38 <- readRDS(paste0(output_dir, "tfBinding_hg38_atlas.rds")
grl_hg19 <- lapply(grl_hg38, liftOver, ch)
saveRDS(grl_hg19, file = paste0(output_dir, "tfBinding_hg19_atlas.rds"))
}\if{html}{\out{</div>}}
}
}

\examples{
# check metada of dataset
tfBinding("mm10", metadata = TRUE)
# download data
\dontrun{
tfBinding("mm10", "atlas")
}

}
\references{
ChIP-Atlas 2021 update: a data-mining suite for exploring epigenomic landscapes by
fully integrating ChIP-seq, ATAC-seq and Bisulfite-seq data.
Zou Z, Ohta T, Miura F, Oki S.
\emph{Nucleic Acids Research. Oxford University Press (OUP);} 2022.
\href{http://dx.doi.org/10.1093/nar/gkac199}{doi:10.1093/nar/gkac199}

ChIP‐Atlas: a data‐mining suite powered by full integration of public ChIP‐seq data.
Oki S, Ohta T, Shioi G, Hatanaka H, Ogasawara O, Okuda Y, Kawaji H, Nakaki R, Sese J, Meno C.
\emph{EMBO}; Vol. 19, EMBO reports. 2018.
\href{http://dx.doi.org/10.15252/embr.201846255}{doi:10.15252/embr.201846255}

ENCODE: {https://www.encodeproject.org/}
}
