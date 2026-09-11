# Write Data Frame to HDF5 File in Chunks using hdf5r

Writes a data frame to an HDF5 file using chunked storage for efficient
I/O operations, especially for large datasets.

## Usage

``` r
write_df_chunked_hdf5r(
  df,
  filename,
  key = "data",
  chunk_rows = 10000,
  compression_level = 0,
  quiet = FALSE
)
```

## Arguments

- df:

  Data frame to write

- filename:

  Character string specifying the HDF5 file path

- key:

  Character string specifying the group/dataset key. Default is "data".

- chunk_rows:

  Integer specifying number of rows per chunk. Default is 10000.

- compression_level:

  Integer from 0-9 specifying gzip compression level. 0 = no compression
  (fastest), 9 = maximum compression (slowest). Default is 0.

## Value

Invisibly returns the file path

## Examples

``` r
if (FALSE) { # \dontrun{
df <- data.frame(x = 1:100000, y = rnorm(100000))
write_df_chunked_hdf5r(df, "output.h5", key = "mydata")
} # }
```
