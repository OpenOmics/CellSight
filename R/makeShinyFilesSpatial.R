#' Generate data files required for shiny app (spatial data)
#'
#' Generate data files required for shiny app, specifically spatial data
#' A prefix is specified for each set of files to allow for multiple 
#' single-cell datasets in a single Shiny app.
#'
#' @param obj input Seurat (v3+) object or input file path for h5ad file
#' @param scConf shinycell config data.table
#' @param shiny.prefix specify file prefix 
#' @param shiny.dir specify directory to create the shiny app in
#'
#' @return data files required for shiny app
#'
#' @author John F. Ouyang
#'
#' @import data.table hdf5r reticulate hdf5r
#'
#' @examples
#' makeShinyFilesSpatial(seu, scConf, shiny.prefix = "sc1", shiny.dir = "shinyApp/")
#'
#' @export
makeShinyFilesSpatial <- function(
  obj, scConf, shiny.prefix = "sc1", shiny.dir = "shinyApp/"){
  ### Preprocessing and checks
  if(!file.exists(paste0(shiny.dir, "/", shiny.prefix, "conf.rds"))){
    stop(paste0(shiny.prefix, "conf.rds file is missing! Have you ran makeShinyFilesGEX?"))
  }
  
  ### Start extraction
  sc1image = list()
  if(class(obj)[1] == "Seurat"){
    if(.hasSlot(obj, "images")){
      # Get all available slide names
      slide_names <- names(obj@images)
      cat("Found", length(slide_names), "spatial slide(s):", paste(head(slide_names, 5), collapse=", "), 
          ifelse(length(slide_names) > 5, "...", ""), "\n")
      
      sc1image$slide_names <- slide_names
      
      # Build human-readable display names from metadata "sample" column
      # (falls back to internal slide names when no "sample" column exists)
      slide_display_names <- slide_names
      if ("sample" %in% colnames(obj@meta.data)) {
        for (j in seq_along(slide_names)) {
          sn <- slide_names[j]
          slide_cells <- Cells(obj@images[[sn]])
          if (length(slide_cells) > 0) {
            sample_vals <- obj@meta.data[slide_cells, "sample"]
            sample_vals <- sample_vals[!is.na(sample_vals)]
            if (length(sample_vals) > 0) {
              slide_display_names[j] <- names(sort(table(sample_vals), decreasing = TRUE))[1]
            }
          }
        }
      }
      sc1image$slide_display_names <- slide_display_names
      
      # Initialize lists to store data for all slides
      sc1image$coords <- list()
      sc1image$bg_images <- list()
      sc1image$bg_images_hires <- list()
      sc1image$lowres_factors <- list()
      sc1image$hires_factors <- list()
      sc1image$image_types <- list()
      
      # Loop through all slides and extract data
      for(i in seq_along(slide_names)) {
        slide_name <- slide_names[i]
        cat("  Processing slide", i, "of", length(slide_names), ":", slide_name, "\n")
        
        visium_image <- obj@images[[slide_name]]
        
        # Extract coordinates - handle both VisiumV1 and VisiumV2 formats
        if ("VisiumV2" %in% class(visium_image)) {
          # VisiumV2 format
          coords <- visium_image@boundaries$centroids@coords
          sc1image$coords[[slide_name]] <- data.frame(
            tissue = 1,
            row = NA,
            col = NA,
            imagecol = coords[, "x"],
            imagerow = coords[, "y"]
          )
          # VisiumV2 centroids@coords has NULL rownames; use Cells() for barcodes
          rownames(sc1image$coords[[slide_name]]) <- Cells(visium_image)
          sc1image$image_types[[slide_name]] <- "VisiumV2"
        } else {
          # VisiumV1 format
          sc1image$coords[[slide_name]] <- visium_image@coordinates
          sc1image$image_types[[slide_name]] <- "VisiumV1"
        }
        
        # Extract lowres background image
        tryCatch({
          bg_image <- GetImage(obj, image = slide_name, mode = "raster")
          sc1image$bg_images[[slide_name]] <- bg_image
        }, error = function(e) {
          cat("    Warning: Could not extract lowres image for", slide_name, "- using blank raster\n")
          sc1image$bg_images[[slide_name]] <<- matrix("white", nrow = 100, ncol = 100)
          class(sc1image$bg_images[[slide_name]]) <<- "raster"
        })
        
        # Extract high-res background image for zooming
        tryCatch({
          if("VisiumV2" %in% class(visium_image)) {
            # For VisiumV2, check if hires image exists in the object
            hires_img <- visium_image@image@image
            if(!is.null(hires_img) && length(dim(hires_img)) >= 2) {
              sc1image$bg_images_hires[[slide_name]] <- hires_img
              # Calculate hires scaling factor
              lowres_img <- sc1image$bg_images[[slide_name]]
              hires_scale <- dim(hires_img)[2] / dim(lowres_img)[2]
              sc1image$hires_factors[[slide_name]] <- hires_scale
              cat("    Extracted hires image (scale factor:", round(hires_scale, 2), ")\n")
            } else {
              # Fallback to lowres
              sc1image$bg_images_hires[[slide_name]] <- sc1image$bg_images[[slide_name]]
              sc1image$hires_factors[[slide_name]] <- 1.0
            }
          } else {
            # For VisiumV1, try to access hires if available
            if(!is.null(visium_image@image) && "hires" %in% names(visium_image@image)) {
              sc1image$bg_images_hires[[slide_name]] <- visium_image@image$hires
              # Calculate scaling from lowres to hires
              hires_scale <- dim(visium_image@image$hires)[2] / dim(sc1image$bg_images[[slide_name]])[2]
              sc1image$hires_factors[[slide_name]] <- hires_scale
              cat("    Extracted hires image (scale factor:", round(hires_scale, 2), ")\n")
            } else {
              # Fallback to lowres
              sc1image$bg_images_hires[[slide_name]] <- sc1image$bg_images[[slide_name]]
              sc1image$hires_factors[[slide_name]] <- 1.0
            }
          }
        }, error = function(e) {
          cat("    Warning: Could not extract hires image for", slide_name, "- using lowres\n")
          sc1image$bg_images_hires[[slide_name]] <<- sc1image$bg_images[[slide_name]]
          sc1image$hires_factors[[slide_name]] <<- 1.0
        })
        
        # Store lowres factor
        sc1image$lowres_factors[[slide_name]] <- visium_image@scale.factors$lowres
      }
      
      cat("  Extracted data for", length(slide_names), "slides\n")
      
      # Set defaults for backwards compatibility
      sc1image$coord <- sc1image$coords[[slide_names[1]]]
      sc1image$bg_image <- sc1image$bg_images[[slide_names[1]]]
      sc1image$bg_image_hires <- sc1image$bg_images_hires[[slide_names[1]]]
      sc1image$lowres <- sc1image$lowres_factors[[slide_names[1]]]
      sc1image$hires_factor <- sc1image$hires_factors[[slide_names[1]]]
      sc1image$image_type <- sc1image$image_types[[slide_names[1]]]
    }
  } else {
    stop("Only Seurat objects are accepted!")
  }
  
  ### Saving objects
  saveRDS(sc1image, file = paste0(shiny.dir, "/", shiny.prefix, "image.rds"))
}

