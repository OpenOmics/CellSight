#' Modify the colour palette for categorical metadata
#'
#' Modify the colour palette for categorical metadata.
#'
#' @param scConf CellSight config data.table
#' @param meta.to.mod metadata for which to modify the colour palette. Users 
#'   can either use the actual metadata column names or display names. Please 
#'   specify only one metadata
#' @param new.colours character vector of new colour palette
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
#' scConf = modColours(scConf, meta.to.mod = "celltype.l1",
#'                     new.colours = c("#A6CEE3", "#1F78B4", "#B2DF8A", "#33A02C",
#'                                     "#FB9A99", "#E31A1C", "#FDBF6F", "#FF7F00"))
#'
#' @export
modColours <- function(scConf, meta.to.mod, new.colours){
  # Check that only one metadata is provided
  if(length(meta.to.mod) != 1){
    stop("Please specify only one metadata to modify colour palette!")
  }
  
  # Check if meta.to.mod exist
  if(meta.to.mod %in% scConf$ID){
    useID = TRUE   # Use IDs
  } else if(meta.to.mod %in% scConf$UI){
    useID = FALSE  # Use UIs
  } else {
    stop("meta.to.mod not found in CellSight config!")
  }
  
  # Check if new.colours are valid colours
  res = try(col2rgb(new.colours), silent = TRUE)
  if("try-error" %in% class(res)){
    stop("invalid colours are provided!")
  }
  
  # Check if meta.to.mod is categorical and if length(new.colours) matches 
  if(useID){
    res = strsplit(scConf[ID == meta.to.mod]$fCL, "\\|")[[1]]
  } else {
    res = strsplit(scConf[UI == meta.to.mod]$fCL, "\\|")[[1]]
  }
  if(is.na(res[1])){
    stop("meta.to.mod is not a categorical metadata!")
  }
  if(length(res) != length(new.colours)){
    stop("Length of new.colours does not match!")
  }
  
  # Start changing the colours
  if(useID){
    scConf[ID == meta.to.mod]$fCL = paste0(new.colours, collapse = "|")
  } else {
    scConf[UI == meta.to.mod]$fCL = paste0(new.colours, collapse = "|")
  }
  return(scConf)
}


