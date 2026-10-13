#' Modify the legend labels for categorical metadata
#'
#' Modify the legend labels for categorical metadata.
#'
#' @param scConf CellSight config data.table
#' @param meta.to.mod metadata for which to modify the legend labels. Users 
#'   can either use the actual metadata column names or display names. Please 
#'   specify only one metadata
#' @param new.labels character vector of new legend labels
#' 
#' @return updated CellSight config data.table
#'
#' @author John F. Ouyang
#'
#' @import data.table
#'
#' @examples
#' bfc <- BiocFileCache::BiocFileCache(ask = FALSE)
#' pbmc_path <- BiocFileCache::bfcrpath(bfc,
#'   "https://zenodo.org/records/15162323/files/multimodal_pbmc.rds?download=1")
#' seu <- readRDS(pbmc_path)
#' scConf <- createConfig(seu)
#' scConf = modLabels(scConf, meta.to.mod = "celltype.l1",
#'                    new.labels = c("B cells", "CD4 T cells", "CD8 T cells",
#'                                   "Dendritic", "Monocyte", "NK cells",
#'                                   "Other", "Other T"))
#'
#' @export
modLabels <- function(scConf, meta.to.mod, new.labels){
  # Check that only one metadata is provided
  if(length(meta.to.mod) != 1){
    stop("Please specify only one metadata to modify legend labels!")
  }
  
  # Check if meta.to.mod exist
  if(meta.to.mod %in% scConf$ID){
    useID = TRUE   # Use IDs
  } else if(meta.to.mod %in% scConf$UI){
    useID = FALSE  # Use UIs
  } else {
    stop("meta.to.mod not found in CellSight config!")
  }
  
  # Check if meta.to.mod is categorical and if length(new.labels) matches 
  if(useID){
    res = strsplit(scConf[ID == meta.to.mod]$fUI, "\\|")[[1]]
  } else {
    res = strsplit(scConf[UI == meta.to.mod]$fUI, "\\|")[[1]]
  }
  if(is.na(res[1])){
    stop("meta.to.mod is not a categorical metadata!")
  }
  if(length(res) != length(new.labels)){
    stop("Length of new.labels does not match!")
  }
  
  # Start changing the colours
  if(useID){
    scConf[ID == meta.to.mod]$fUI = paste0(new.labels, collapse = "|")
  } else {
    scConf[UI == meta.to.mod]$fUI = paste0(new.labels, collapse = "|")
  }
  return(scConf)
}


