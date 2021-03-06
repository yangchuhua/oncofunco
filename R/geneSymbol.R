#' Get genes as GRanges object
#'
#' This function returns GRanges object, used as input for plotting gene track
#' Warning: too much dependency to other packages, will need to rewrite/update the code in future far far away...
#' Warning: only works for LE at the moment with pre-loaded bio packages
#' @param chrom chromosome name, must be character class with length(chrom)==1, e.g.: chr1"
#' @param chromStart,chromEnd Region range, zoom, minimum BP and maximum BP, advised to keep this less than 5Mb.
#' @export geneSymbol
#' @author Tokhir Dadaev
#' @return a GRanges object
#' @keywords gene symbol granges plot


geneSymbol <- function(chrom = NA, chromStart = NA, chromEnd = NA){
  # require(ggplot2)
  # require(ggbio)
  # require(GenomicFeatures)
  # require(TxDb.Hsapiens.UCSC.hg19.knownGene)
  # require(org.Hs.eg.db) # gene symobols
  # require(DBI)

  txdb <- TxDb.Hsapiens.UCSC.hg19.knownGene

  #valid chrom names
  chr <- paste0("chr",c(1:22,"X","Y"))

  # Input checks ----------------------------------------------------------
  if(!is.character(chrom) |
     length(chrom) != 1 |
     !chrom %in% chr) stop("chrom: must be character class with length(chrom)==1, e.g.: chr1")

  if(is.na(chromStart) |
     chromStart < 0) warning("chromStart: setting to default value 0")

  if(is.na(chromEnd)) warning("chromEnd: default value last position for chromosome")

  # Validate start end position for chrom - using txdb chrominfo table
  chrominfo <-
    dbGetQuery(txdb$conn,
               paste0("select * from chrominfo where chrom='",
                      chrom,"'"))
  chromStart <- ifelse(is.na(chromStart) | chromStart < 0,
                       0, chromStart)
  chromEnd <- ifelse(is.na(chromEnd) |
                       chromEnd > chrominfo$length |
                       chromEnd < chromStart,
                     chrominfo$length, chromEnd)

  #Print summary for selection region of interest
  print(paste0("Collapsing to gene symbols, region: ",
               chrom, ":", chromStart, "-", chromEnd))

  # Get chromosome start end positions to subset TXDB for transcripts
  roi_chr <- GRanges(seqnames = chrominfo$chrom,
                     IRanges(start = chromStart,
                             end = chromEnd,
                             names = chrom))
  # Collapse to gene symbol -----------------------------------------------
  # Subset txdb over overlaps for chr-start-end
  keys_overlap_tx_id <- as.data.frame(subsetByOverlaps(transcripts(txdb), roi_chr))
  keys_overlap_tx_id <- as.character(keys_overlap_tx_id$tx_id)

  # Match TX ID to GENEID
  TXID_GENEID <- AnnotationDbi::select(txdb,
                                       keys = keys_overlap_tx_id,
                                       columns = c("TXNAME","GENEID"),
                                       keytype = "TXID")
  # Select transcipts from txdb which have GENEID
  Trans <- AnnotationDbi::select(txdb,
                                 keys = as.character(TXID_GENEID$TXID),
                                 columns = columns(txdb),
                                 keytype = "TXID")
  # Get gene symbol
  gene_symbol <- unique(
    AnnotationDbi::select(org.Hs.eg.db,
                          keys = Trans[ !is.na(Trans$GENEID), "GENEID"],
                          columns = "SYMBOL",
                          keytype = "ENTREZID"))

  # Match GENEID, SYMBOL
  TXID_GENEID <- merge(TXID_GENEID, gene_symbol, 
                       by.x = "GENEID", by.y = "ENTREZID")

  # If not match on gene symbol, then TXNAME is gene symbol
  # TXID_GENEID$SYMBOL <- ifelse(is.na(TXID_GENEID$SYMBOL),
  #                              TXID_GENEID$TXNAME,TXID_GENEID$SYMBOL)
  # UPDATE, drop TX that do not match to gene symbol:
  TXID_GENEID <- TXID_GENEID[ !is.na(TXID_GENEID$SYMBOL), ]
  
  # merge to add gene symbol
  Trans <- merge(Trans, TXID_GENEID, by = c("TXID","GENEID","TXNAME"))

  # If not match on gene symbol, then TXNAME is gene symbol
  # Trans$SYMBOL <- ifelse(is.na(Trans$SYMBOL),
  #                        Trans$TXNAME,Trans$SYMBOL)
  Trans <- Trans[ !is.na(Trans$SYMBOL), ]

  #Make Granges object
  CollapsedGenes <- GRanges(seqnames = Trans$EXONCHROM,
                            IRanges(start = Trans$EXONSTART,
                                    end = Trans$EXONEND),
                            strand = Trans$EXONSTRAND)
  CollapsedGenes$gene_id <- Trans$SYMBOL
  
  # Output ----------------------------------------------------------------
  #return collapsed genes per CHR
  return(CollapsedGenes)
}
