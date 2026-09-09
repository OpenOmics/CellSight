library(hdf5r)

#' Write Data Frame to HDF5 File in Chunks using hdf5r
#'
#' Writes a data frame to an HDF5 file using chunked storage for efficient
#' I/O operations, especially for large datasets.
#'
#' @param df Data frame to write
#' @param filename Character string specifying the HDF5 file path
#' @param key Character string specifying the group/dataset key. Default is "data".
#' @param chunk_rows Integer specifying number of rows per chunk. Default is 10000.
#' @param compression_level Integer from 0-9 specifying gzip compression level.
#'   0 = no compression (fastest), 9 = maximum compression (slowest). Default is 0.
#'
#' @return Invisibly returns the file path
#'
#' @examples
#' \dontrun{
#' df <- data.frame(x = 1:100000, y = rnorm(100000))
#' write_df_chunked_hdf5r(df, "output.h5", key = "mydata")
#' }
#'
#' @export
write_df_chunked_hdf5r <- function(df, filename, key = "data",
                                   chunk_rows = 10000, compression_level = 0, quiet = FALSE) {
  # Open or create HDF5 file
  if (file.exists(filename)) {
    h5file <- H5File$new(filename, mode = "a")
  } else {
    h5file <- H5File$new(filename, mode = "w")
  }

  # Create group for the data frame
  if (!h5file$exists(key)) {
    group <- h5file$create_group(key)
  } else {
    group <- h5file[[key]]
  }

  n_rows <- nrow(df)
  n_cols <- ncol(df)

  # Write each column as a separate dataset with chunking
  for (col_idx in seq_len(n_cols)) {
    col_name <- colnames(df)[col_idx]
    col_data <- df[[col_idx]]

    # Determine data type and prepare data
    if (is.factor(col_data)) {
      # Store factor as integer with levels
      values <- as.integer(col_data)
      dtype <- h5types$H5T_NATIVE_INT
      # # Store factor levels separately
      # levels_key <- paste0(col_name, "_levels")
      # if (group$exists(levels_key)) {
      #   group[[levels_key]]$delete()
      # }
      # group[[levels_key]] <- levels(col_data)
    } else if (is.integer(col_data)) {
      values <- col_data
      dtype <- h5types$H5T_NATIVE_INT
    } else if (is.numeric(col_data)) {
      values <- as.numeric(col_data)
      dtype <- h5types$H5T_NATIVE_DOUBLE
    } else if (is.logical(col_data)) {
      values <- as.integer(col_data)
      dtype <- h5types$H5T_NATIVE_INT
    } else if (is.character(col_data)) {
      values <- col_data
      dtype <- h5types$H5T_STRING
    } else {
      if (!quiet) {
        warning("Unsupported type for column ", col_name, ", converting to character")
      }
      values <- as.character(col_data)
      dtype <- h5types$H5T_STRING
    }

    # Delete if exists
    if (group$exists(col_name)) {
      group$link_delete(col_name)
    }

    # Create dataset with chunking
    if (is.character(values)) {
      # String data - use explicit space and string dtype
      space <- H5S$new("simple", dims = n_rows, maxdims = n_rows)

      # Create variable-length string dtype
      str_dtype <- H5T_STRING$new(size = Inf)
      str_dtype$set_cset(h5const$H5T_CSET_UTF8)

      dataset <- group$create_dataset(
        name = col_name,
        dtype = str_dtype,
        space = space,
        chunk_dims = min(chunk_rows, n_rows),
        gzip_level = compression_level
      )

      # Write data in chunks
      for (i in seq(1, n_rows, by = chunk_rows)) {
        end_idx <- min(i + chunk_rows - 1, n_rows)
        dataset[i:end_idx] <- values[i:end_idx]
      }
      space$close()
      str_dtype$close()
    } else {
      # Numeric data - use space and chunk specifications
      space <- H5S$new("simple", dims = n_rows, maxdims = n_rows)

      dataset <- group$create_dataset(
        name = col_name,
        dtype = dtype,
        space = space,
        chunk_dims = min(chunk_rows, n_rows),
        gzip_level = compression_level
      )

      # Write data in chunks
      for (i in seq(1, n_rows, by = chunk_rows)) {
        end_idx <- min(i + chunk_rows - 1, n_rows)
        dataset[i:end_idx] <- values[i:end_idx]
      }

      space$close()
    }

    dataset$close()

    if (!quiet) {
      cat("Written column:", col_name, "\n")
    }
  }

  # Close file
  group$close()
  h5file$close_all()

  if (!quiet) {
    cat("Data frame written to", filename, "under key:", key, "\n")
    cat("File size:", round(file.size(filename) / 1024^2, 2), "MB\n")
  }

  invisible(filename)
}
