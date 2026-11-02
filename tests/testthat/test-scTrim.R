test_that("scTrim drops a whitespace-only first line and dedents the rest", {
  expect_equal(scTrim("  \n  hello\n  world\n  "), "hello\nworld")
})

test_that("scTrim leaves single-line input with no newline untouched", {
  expect_equal(scTrim("no newline here"), "no newline here")
})

test_that("scTrim is a no-op on a zero-length vector", {
  expect_identical(scTrim(character(0)), character(0))
})

test_that("scTrim discards content on the first line entirely", {
  expect_equal(
    scTrim("first line kept\n    indented\n    more\n"),
    "first line kept\nindented\nmore"
  )
})

test_that("scTrim strips only the minimum shared indent", {
  expect_equal(scTrim("\n  a\n    b\n  c\n"), "a\n  b\nc")
})

test_that("scTrim is vectorised and leaves non-newline elements as-is", {
  out <- scTrim(c("\n  one\n  two\n", "plain"))
  expect_equal(out, c("one\ntwo", "plain"))
})
