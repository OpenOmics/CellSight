# Shows the legends for single-cell metadata

Shows the legends for single-cell metadata based on the CellSight config
data.table. This allows user to visualise the different metadata to be
plotted and make any modifications if necessary. Note that the display
name is shown here instead of the actual name. For more information
regarding display name, see
[`?modMetaName`](https://openomics.github.io/CellSight/reference/modMetaName.md).

## Usage

``` r
showLegend(scConf, fontSize = 14)
```

## Arguments

- scConf:

  CellSight config data.table

- fontSize:

  font size of legends. Decrease it if you have too many items to
  display

## Value

gtable plot showing the legends for different metadata

## Author

John F. Ouyang

## Examples

``` r
if (FALSE) { # \dontrun{
showLegend(scConf)

# Can also save the legend for plotting later
scLegend = showLegend(scConf)
leg = do.call(gtable_rbind, scLegend)
grid.newpage()
grid.draw(leg)
} # }
```
