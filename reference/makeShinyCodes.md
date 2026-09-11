# Generate code files required for shiny app

Generate code files required for shiny app for both single-dataset and
multi-dataset scenarios. Specifically, two R scripts will be generated,
namely `server.R` and `ui.R`. Note that `makeShinyFiles` has to be ran
prior to make the necessary data files for each dataset included. The
prefix used in `makeShinyFiles` have to be then supplied in this
function.

## Usage

``` r
makeShinyCodes(
  shiny.title,
  shiny.footnotes = "",
  shiny.prefix,
  shiny.headers,
  shiny.dir,
  defPtSiz = 1.25,
  ganalytics = NA
)
```

## Arguments

- shiny.title:

  specify the overall title for shiny app

- shiny.footnotes:

  text for shiny app footnote. When given as a list, citation can be
  inserted by specifying author, title, journal, volume, page, year,
  doi, link. See example below.

- shiny.prefix:

  specify file prefix for each dataset. Must match the prefix used in
  `makeShinyFiles`

- shiny.headers:

  specify the tab header names for each dataset. Length must match that
  of `shiny.prefix`. Note that this is ignored if there is only one
  dataset

- shiny.dir:

  specify directory to create the shiny app in

- defPtSiz:

  specify default point size for single cells. For example, a smaller
  size can be used if you have many cells in your dataset. A single
  value can be specified to set the point size for all datasets.
  Otherwise, users have to specify one value for each dataset

- ganalytics:

  Google analytics tracking ID (e.g. "UA-123456789-0")

## Value

server.R and ui.R required for shiny app

## Details

The three output files (`server.R`, `ui.R`, `shinyFunc.R`) are assembled
from jinjar templates shipped under `inst/templates`. The master
templates (`server.R.jinja`, `ui.R.jinja`, `shinyFunc.R.jinja`) contain
the orchestration logic - which tab blocks to include for each dataset,
gated on the presence of spatial / ATAC / DEG data - and `{% include %}`
one partial per tab block. All per-dataset facts (prefix, headers, point
sizes, spatial slider parameters and which data types are present) are
computed here in R and passed as the template context.

## Author

John F. Ouyang

## Examples

``` r
if (FALSE) { # \dontrun{
# Example citation
citation = list(
  author  = "Liu X., Ouyang J.F., Rossello F.J. et al.",
  title   = "",
  journal = "Nature",
  volume  = "586",
  page    = "101-107",
  year    = "2020",
  doi     = "10.1038/s41586-020-2734-6",
  link    = "https://www.nature.com/articles/s41586-020-2734-6")
makeShinyCodes(shiny.title = "scRNA-seq shiny app", shiny.footnotes = "",
               shiny.prefix = c("sc1", "sc2"), defPtSiz = c(1.25, 1.5),
               shiny.headers = c("dataset1", "dataset2"),
               shiny.dir = "shinyApp/")
} # }
```
