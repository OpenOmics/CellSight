test_that("checkConfig reports no errors for a freshly created config", {
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))
  expect_message(checkConfig(scConf, seu), "ALL OK")
})

test_that("checkConfig flags a config that has drifted from the object", {
  # Regression test: all.equal() returns a character string (not FALSE) on a
  # mismatch, so `!all.equal(...)` used to error with "invalid argument type"
  # instead of reporting the mismatch checkConfig() exists to catch.
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))
  scConf[ID == "group"]$fID <- "WRONG|LEVELS"

  expect_no_error(checkConfig(scConf, seu))
  expect_message(checkConfig(scConf, seu), "errors found")
})

test_that("checkConfig flags a colour/level count mismatch", {
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))
  scConf[ID == "group"]$fCL <- "red"

  expect_message(checkConfig(scConf, seu), "colours do not match")
})
