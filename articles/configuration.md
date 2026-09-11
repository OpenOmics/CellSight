# Configuring metadata and colours

The config object — `scConf` — is the single place you control what the
generated app shows and how it looks. It is an ordinary `data.table`, so
you can inspect and edit it directly, but the helpers in this article
keep it internally consistent and are the supported route.

Code here is not evaluated when the site is built; it needs a real
object.

## What is in a config

[`createConfig()`](https://openomics.github.io/CellSight/reference/createConfig.md)
returns one row per cell-metadata column, with these columns:

| column    | meaning                                                       |
|-----------|---------------------------------------------------------------|
| `ID`      | the metadata’s name in the object (`colnames(seu@meta.data)`) |
| `UI`      | the label shown in the app                                    |
| `fID`     | factor levels, `\|`-separated, in object order                |
| `fUI`     | the labels shown for those levels, `\|`-separated             |
| `fCL`     | one hex colour per level, `\|`-separated                      |
| `fRow`    | how many rows the legend is wrapped onto                      |
| `default` | `1` or `2` for the two default metadata, `0` otherwise        |
| `grp`     | `TRUE` if the metadata can group cells (2+ levels)            |

Most helpers accept either the `ID` or the `UI` value for `meta.to.mod`
— they detect which you used. Once you have renamed something with
[`modMetaName()`](https://openomics.github.io/CellSight/reference/modMetaName.md),
be consistent about which name you pass afterwards.

Two functions let you look before you edit:

``` r

showOrder(scConf)    # a data.frame of ID / UI / levels, in display order
showLegend(scConf)   # a ggplot of every legend, with its colours
```

[`showLegend()`](https://openomics.github.io/CellSight/reference/showLegend.md)
is the fastest way to catch a palette that reads badly, and takes
`fontSize` if the labels are long.

## Choosing which metadata appears

Restrict at creation time when you already know what you want:

``` r

scConf <- createConfig(seu, meta.to.include = c("orig.ident", "seurat_clusters", "celltype"))
```

Or start from everything and prune.
[`delMeta()`](https://openomics.github.io/CellSight/reference/delMeta.md)
takes a vector:

``` r

scConf <- delMeta(scConf, c("nCount_RNA", "nFeature_RNA", "percent.mt"))
```

[`addMeta()`](https://openomics.github.io/CellSight/reference/addMeta.md)
brings a column back, or adds one that
[`createConfig()`](https://openomics.github.io/CellSight/reference/createConfig.md)
skipped — note that it needs the object too, since it has to read the
column’s levels:

``` r

scConf <- addMeta(scConf, "Phase", seu)
scConf <- addMeta(scConf, c("donor", "timepoint"), seu, maxLevels = 100)
```

`maxLevels` is the guard against accidentally exposing something like a
per-cell barcode as a categorical variable; raise it deliberately.

## Renaming for display

[`modMetaName()`](https://openomics.github.io/CellSight/reference/modMetaName.md)
changes only the app-facing label, never the underlying column, and is
vectorised:

``` r

scConf <- modMetaName(
  scConf,
  meta.to.mod = c("orig.ident", "seurat_clusters", "percent.mt"),
  new.name    = c("Library", "Cluster", "% mitochondrial")
)
```

[`modLabels()`](https://openomics.github.io/CellSight/reference/modLabels.md)
renames the *levels* within one metadata. Unlike the others it takes
exactly one metadata at a time, and `new.labels` must be in the same
order as the existing levels — check with
[`showOrder()`](https://openomics.github.io/CellSight/reference/showOrder.md)
first:

``` r

showOrder(scConf)

scConf <- modLabels(
  scConf,
  meta.to.mod = "Cluster",
  new.labels  = c("Naive CD4 T", "Memory CD4 T", "CD14 Mono", "B", "NK")
)
```

## Colours

[`modColours()`](https://openomics.github.io/CellSight/reference/modColours.md)
also takes one metadata at a time, with one colour per level in level
order. Any format R accepts works — hex codes or named colours:

``` r

scConf <- modColours(
  scConf,
  meta.to.mod = "Cluster",
  new.colours = c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F")
)
```

Colour palettes are a good place to be deliberate: the default is a
[`colorRampPalette()`](https://rdrr.io/r/grDevices/colorRamp.html)
interpolation of a 12-colour Paired-style set, which starts to produce
near-indistinguishable neighbours once a metadata has more than roughly
a dozen levels. If a cluster label matters, give it a colour that
survives being one point among 100,000.

For a sequential or a colourblind-safe set, generate rather than
hand-pick:

``` r

# "Cluster" here is the display name (UI); use the object's column name if you
# have not renamed it. modColours() errors unless the lengths match exactly.
n <- length(strsplit(scConf[UI == "Cluster"]$fID, "\\|")[[1]])
scConf <- modColours(scConf, "Cluster", scales::hue_pal()(n))
```

## Ordering

[`reorderMeta()`](https://openomics.github.io/CellSight/reference/reorderMeta.md)
sets the order metadata appear in the app’s dropdowns. Unlike the other
helpers it accepts **only** `ID` values — the object’s column names, not
display names — and it needs a complete permutation: every `ID` present
exactly once, or it errors. Read the current set off the config rather
than typing it out:

``` r

scConf$ID
#> [1] "orig.ident" "seurat_clusters" "celltype" "Phase"

scConf <- reorderMeta(scConf, c("celltype", "seurat_clusters", "orig.ident", "Phase"))
```

Put the metadata people actually reach for first; the app’s default
selections come from `default`, but the dropdown order is what everyone
scrolls through.

## Defaults

[`modDefault()`](https://openomics.github.io/CellSight/reference/modDefault.md)
nominates the two metadata the app opens on — the first is used for the
main grouping, the second for the side-by-side and split views:

``` r

scConf <- modDefault(scConf, default1 = "celltype", default2 = "seurat_clusters")
```

[`createConfig()`](https://openomics.github.io/CellSight/reference/createConfig.md)
guesses these by pattern-matching `ident`/`library` for the first and
`clust` for the second, which is often right and worth overriding when
it is not. Both must be metadata with `grp == TRUE`.

## Validate before building

[`checkConfig()`](https://openomics.github.io/CellSight/reference/checkConfig.md)
re-reads the object and reports every mismatch it finds — metadata that
no longer exists, levels that have changed — rather than stopping at the
first:

``` r

checkConfig(scConf, seu)
```

Run it after a round of edits, and especially after re-running any
upstream analysis that might have changed cluster labels. A config that
has drifted from its object produces an app that builds cleanly and then
misbehaves.

## A worked config

Putting it together, a typical config pass looks like:

``` r

scConf <- createConfig(seu)
scConf <- delMeta(scConf, c("nCount_RNA", "nFeature_RNA", "percent.mt"))
scConf <- modMetaName(scConf, c("orig.ident", "seurat_clusters"), c("Library", "Cluster"))

# one colour per level, in level order
nClust <- length(strsplit(scConf[UI == "Cluster"]$fID, "\\|")[[1]])
scConf <- modColours(scConf, "Cluster", scales::hue_pal()(nClust))

# reorderMeta() wants IDs, and all of them
scConf <- reorderMeta(scConf, c("celltype", "seurat_clusters", "orig.ident"))
scConf <- modDefault(scConf, "celltype", "Cluster")

checkConfig(scConf, seu)
showLegend(scConf)
```

Then build, as in
[`vignette("cellsight")`](https://openomics.github.io/CellSight/articles/cellsight.md).
