test_that("write_df_chunked_hdf5r round-trips numeric, factor and character columns", {
  f <- tempfile(fileext = ".h5")
  df <- data.frame(
    x = 1:25,
    y = as.numeric(1:25) / 2,
    g = factor(rep(c("a", "b"), length.out = 25)),
    s = letters[1:25],
    stringsAsFactors = FALSE
  )

  write_df_chunked_hdf5r(df, f, key = "mydata", chunk_rows = 10, quiet = TRUE)

  h5 <- hdf5r::H5File$new(f, mode = "r")
  on.exit(h5$close_all())

  expect_true(h5$exists("mydata"))
  expect_equal(h5[["mydata/x"]][], df$x)
  expect_equal(h5[["mydata/y"]][], df$y)
  expect_equal(h5[["mydata/g"]][], as.integer(df$g))
  expect_equal(h5[["mydata/s"]][], df$s)
})

test_that("write_df_chunked_hdf5r overwrites an existing column on rewrite", {
  f <- tempfile(fileext = ".h5")
  write_df_chunked_hdf5r(data.frame(x = 1:5), f, key = "d", quiet = TRUE)
  write_df_chunked_hdf5r(data.frame(x = 6:10), f, key = "d", quiet = TRUE)

  h5 <- hdf5r::H5File$new(f, mode = "r")
  on.exit(h5$close_all())
  expect_equal(h5[["d/x"]][], 6:10)
})

test_that("write_df_chunked_hdf5r warns and stringifies unsupported column types", {
  f <- tempfile(fileext = ".h5")
  df <- data.frame(d = as.Date("2024-01-01") + 0:4)

  expect_warning(
    write_df_chunked_hdf5r(df, f, key = "d", quiet = FALSE),
    "Unsupported type"
  )

  h5 <- hdf5r::H5File$new(f, mode = "r")
  on.exit(h5$close_all())
  expect_equal(h5[["d/d"]][], as.character(df$d))
})
