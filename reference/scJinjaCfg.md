# jinjar configuration used by all cellsight code writers

Uses `<<` and `>>` for variable interpolation so that the many literal
curly braces in the generated Shiny/ggplot code pass through untouched.
Block and comment delimiters keep the jinjar defaults; neither of those
sequences occurs in the generated code.

## Usage

``` r
scJinjaCfg()
```

## Value

a `jinjar_config` object
