# Dedent a template block

Removes the common leading indentation from a multi-line string: the
first line is dropped if it is only indentation, the minimum indent
shared by the remaining lines is stripped, and a single trailing
whitespace-only line is removed. This is a self-contained
reimplementation of the dedenting that
[`glue::glue()`](https://glue.tidyverse.org/reference/glue.html) applied
to these templates, kept so the code writers do not depend on glue.
Operates on ASCII input.

## Usage

``` r
scTrim(x)
```

## Arguments

- x:

  a character vector of template blocks

## Value

the dedented character vector
