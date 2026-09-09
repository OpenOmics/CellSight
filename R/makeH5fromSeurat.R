#' Make h5 object from Seurat assay data
#'
#' Make h5 object from Seurat assay data
#'
#' @param obj input Seurat (v3+) object
#' @param sc1meta data.table of cell metadata
#' @param filename filename of output h5 file
#' @param gex.assay assay in Seurat object to use
#' @param gex.slot slot in single-cell assay to use
#' @param chunkSize number of genes written to h5file at any one time
#'
#' @return h5 object
#'
#' @author John F. Ouyang
#'
#' @import data.table hdf5r reticulate
#'
#' @export
makeH5fromSeurat <- function(obj, sc1meta, filename, 
                             gex.assay, gex.slot, chunkSize){  
  
  # Create h5 file and get ready
  if(class(obj@assays[[gex.assay]]) == "Assay5"){
    cat("Assay type: Assay5 (Seurat v5)\n")
    cat("Available layers in assay:", names(obj@assays[[gex.assay]]@layers), "\n")
    
    # Method 1: Cells() on assay
    assay.cells.method1 = tryCatch({
      Cells(obj@assays[[gex.assay]])
    }, error = function(e) {
      cat("")
      NULL
    })

    # Method 2: Cells() on main object
    assay.cells.method2 = tryCatch({
      Cells(obj)
    }, error = function(e) {
      cat("")
      NULL
    })
    
    # Method 3: colnames on main object
    assay.cells.method3 = tryCatch({
      colnames(obj)
    })
    
    # Method 4: Direct layer access
    assay.cells.method4 = tryCatch({
      if("data" %in% names(obj@assays[[gex.assay]]@layers)){
        colnames(obj@assays[[gex.assay]]@layers$data)
      } else {
        NULL
      }
    })
    
    # Use the first method that returns non-NULL cells
    assay.cells = NULL
    for(method in list(assay.cells.method2, assay.cells.method3, assay.cells.method1, assay.cells.method4)){
      if(!is.null(method) && length(method) > 0){
        assay.cells = method
        break
      }
    }
    
    if(is.null(assay.cells) || length(assay.cells) == 0){
      cat("\n!!! ALL METHODS FAILED - Inspecting object structure !!!\n")
      cat("Assay class:", class(obj@assays[[gex.assay]]), "\n")
      cat("Assay slot names:", slotNames(obj@assays[[gex.assay]]), "\n")
      cat("Layer names:", names(obj@assays[[gex.assay]]@layers), "\n")
      cat("First layer class:", class(obj@assays[[gex.assay]]@layers[[1]]), "\n")
      stop("Cannot extract cell names from Assay5 object")
    }
    
    # Get matrix dimension from the assay itself
    gex.matdim = c(nrow(obj@assays[[gex.assay]]), length(assay.cells))
  } else {
    cat("Assay type: Legacy Assay (Seurat v3/v4)\n")
    cat("Available slots in assay:", slotNames(obj@assays[[gex.assay]]), "\n")
    gex.matdim = dim(slot(obj@assays[[gex.assay]], gex.slot))
    # Get available cells in this assay
    assay.cells = colnames(slot(obj@assays[[gex.assay]], gex.slot))
  }
  
  # Filter sc1meta to only include cells present in this assay
  sc1meta.filtered = sc1meta[sc1meta$cellID %in% assay.cells, ]
  
  # Check overlap
  overlap_count = sum(sc1meta$cellID %in% assay.cells)
  # cat("Overlap between sc1meta and assay:", overlap_count, "\n")
  
  # ADDED: Verify all cellIDs in filtered metadata exist in assay
  missing_cells = setdiff(sc1meta.filtered$cellID, assay.cells)
  if(length(missing_cells) > 0){
    warning(paste("Removing", length(missing_cells), "cells not found in assay"))
    cat("First few missing cells:", head(missing_cells, 10), "\n")
    sc1meta.filtered = sc1meta.filtered[!sc1meta.filtered$cellID %in% missing_cells, ]
  }
  
  # ADDED: Check if we have any cells left
  if(nrow(sc1meta.filtered) == 0){
    cat("ERROR: No overlapping cells found!\n")
    cat("Sample cellIDs from metadata:", head(unique(sc1meta$cellID), 20), "\n")
    cat("Sample cellIDs from assay:", head(unique(assay.cells), 20), "\n")
    stop("No overlapping cells found between metadata and assay data")
  }
  
  # CRITICAL CHECK: Ensure we have cells to process
  if(nrow(sc1meta.filtered) == 0){
    cat("\n!!! CRITICAL ERROR !!!\n")
    cat("No cells remaining after filtering!\n")
    cat("Total cells in sc1meta:", nrow(sc1meta), "\n")
    cat("Total cells in assay:", length(assay.cells), "\n")
    cat("Overlap count:", sum(sc1meta$cellID %in% assay.cells), "\n")
    cat("\nSample cellIDs from sc1meta (first 20):\n")
    print(head(sc1meta$cellID, 20))
    cat("\nSample cellIDs from assay (first 20):\n")
    print(head(assay.cells, 20))
    stop("No cells to process - check cell ID formatting/naming mismatch")
  }
  
  sc1gexpr <- H5File$new(filename, mode = "w")
  sc1gexpr.grp <- sc1gexpr$create_group("grp")
  sc1gexpr.grp.data <- sc1gexpr.grp$create_dataset(
    "data",  dtype = h5types$H5T_NATIVE_FLOAT,
    space = H5S$new("simple", dims = c(gex.matdim[1], nrow(sc1meta.filtered)), maxdims = c(gex.matdim[1], nrow(sc1meta.filtered))),
    chunk_dims = c(1, nrow(sc1meta.filtered)))
  chk = chunkSize
  while(chk > (gex.matdim[1]-8)){
    chk = floor(chk / 2)
  } 
  
# Start writing to file
  nChunk = floor((gex.matdim[1]-8)/chk)
  if(class(obj@assays[[gex.assay]]) == "Assay5"){
    # First, check what layers exist and their dimensions
    layer_names = names(obj@assays[[gex.assay]]@layers)
    for(ln in layer_names){
      layer_dims = tryCatch({
        dim(obj@assays[[gex.assay]]@layers[[ln]])
      }, error = function(e) c(NA, NA))
      cat("  ", ln, ": ", paste(layer_dims, collapse=" x "), "\n")
    }
    
    # Strategy: Find the layer with correct number of cells (95494)
    # Prefer exact match to gex.slot, but fall back to finding right-sized layer
    target_layer = NULL
    
    # First try: exact match
    if(gex.slot %in% layer_names){
      test_dims = dim(obj@assays[[gex.assay]]@layers[[gex.slot]])
      if(test_dims[2] == gex.matdim[2]){
        target_layer = gex.slot
        # cat("Found exact match layer with correct dimensions:", target_layer, "\n")
      } else {
        # cat("Layer", gex.slot, "exists but has wrong dimensions:", paste(test_dims, collapse=" x "), "\n")
      }
    }
    
    # Second try: find layer with correct cell count
    if(is.null(target_layer)){
      for(ln in layer_names){
        layer_dims = tryCatch({
          dim(obj@assays[[gex.assay]]@layers[[ln]])
        }, error = function(e) next)
        
        if(!is.null(layer_dims) && layer_dims[2] == gex.matdim[2]){
          target_layer = ln
          break
        }
      }
    }
    
    # Third try: use LayerData but verify
    if(is.null(target_layer)){
      test_data = tryCatch({
        LayerData(obj, assay = gex.assay, layer = gex.slot)
      }, error = function(e) NULL)
      
      if(!is.null(test_data) && ncol(test_data) == gex.matdim[2]){
        target_layer = gex.slot
      }
    }
    
    if(is.null(target_layer)){
      stop(paste("Cannot find a layer with", gex.matdim[2], "cells. Available layers:",
                 paste(layer_names, collapse=", ")))
    }
    
    # Now retrieve the data from the correct layer
    gex.data = tryCatch({
      if(target_layer %in% layer_names){
        obj@assays[[gex.assay]]@layers[[target_layer]]
      } else {
        LayerData(obj, assay = gex.assay, layer = target_layer)
      }
    }, error = function(e) {
      stop(paste("Failed to retrieve layer", target_layer, ":", e$message))
    })

    # CRITICAL FIX: Ensure the matrix has cell names
    if(is.null(colnames(gex.data))){
      cat("WARNING: Retrieved matrix has no column names, assigning from assay.cells\n")
      colnames(gex.data) = assay.cells
      cat("Assigned", length(assay.cells), "cell names to matrix\n")
    }

    
    # Verify gex.data dimensions match expectations
    if(!all(dim(gex.data) == gex.matdim)){
      cat("ERROR: Data dimensions still don't match!\n")
      cat("Actual:", dim(gex.data), "\n")
      cat("Expected:", gex.matdim, "\n")
      stop("Dimension mismatch even after finding correct layer")
    }
    
    # Ensure cell order matches and all cells exist
    if(!all(sc1meta.filtered$cellID %in% colnames(gex.data))){
      missing_in_data = sum(!sc1meta.filtered$cellID %in% colnames(gex.data))
      cat("ERROR:", missing_in_data, "cells in metadata not found in data matrix\n")
      cat("Sample missing cells:", head(sc1meta.filtered$cellID[!sc1meta.filtered$cellID %in% colnames(gex.data)], 10), "\n")
      stop("Cell ID mismatch between metadata and data matrix")
    }
    
    # Recalculate nChunk based on actual dimensions
    nChunk = floor((gex.matdim[1]-8)/chk)
    
    for(i in 1:nChunk){
      sc1gexpr.grp.data[((i-1)*chk+1):(i*chk), ] <- as.matrix(
        gex.data[((i-1)*chk+1):(i*chk), sc1meta.filtered$cellID])
    }
    sc1gexpr.grp.data[(i*chk+1):gex.matdim[1], ] <- as.matrix(
      gex.data[(i*chk+1):gex.matdim[1], sc1meta.filtered$cellID])
    
    # CRITICAL: Get gene names from the matrix
    gex.rownm = rownames(gex.data)
    
    # ADDED: Verify gene names exist
    if(is.null(gex.rownm) || length(gex.rownm) == 0){
      gex.rownm = rownames(obj@assays[[gex.assay]])
    }
      
  } else {
    for(i in 1:nChunk){
      sc1gexpr.grp.data[((i-1)*chk+1):(i*chk), ] <- as.matrix(
        slot(obj@assays[[gex.assay]], gex.slot)[
          ((i-1)*chk+1):(i*chk), sc1meta.filtered$cellID])
    }
      sc1gexpr.grp.data[(i*chk+1):gex.matdim[1], ] <- as.matrix(
        slot(obj@assays[[gex.assay]], gex.slot)[
          (i*chk+1):gex.matdim[1], sc1meta.filtered$cellID])
      gex.rownm = rownames(slot(obj@assays[[gex.assay]], gex.slot))
  }
  sc1gexpr$close_all()

  return(gex.rownm)
}