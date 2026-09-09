# cellsight <img src="man/figures/logo.png" align="right" height="139" alt="cellsight logo" />
`cellsight` is an enhanced R package for creating interactive, lightweight, 
and shareable web applications to explore single-cell multi-omics and spatial 
transcriptomics data. Building on the simplicity of the original ShinyCell, 
cellsight introduces powerful new features tailored for modern single-cell 
modalities, including support for CITE-seq, scATAC-seq, and spatial 
transcriptomics. It integrates seamlessly with popular analysis tools like 
Seurat, Scanpy, Signac, and ArchR, and offers advanced visualizations such as 
zoom-enabled UMAPs, IGV-style peak tracks, and spatial plots—all easily 
customizable and deployable with minimal dependencies. Designed for both 
computational and experimental researchers, cellsight empowers intuitive 
exploration, cross-modality comparison, and statistical analysis of 
high-dimensional data without requiring extensive coding or setup. 

If you are using `cellsight`, please cite the [biorxiv preprint](
https://www.biorxiv.org/content/10.1101/2025.04.22.650045v1). 
The manuscript is currently under review.

Key features of `cellsight` include:

- Supports seamless integration and visualization of single-cell multi-omics, 
peak-based, and spatial data for in-depth exploration.

- Converts data from leading analysis tools—including Scanpy, Seurat, Signac, 
and ArchR—into a lightweight, portable format suitable for local or web-based 
deployment, enabling open and accessible data sharing.

- Offers a rich collection of interactive, customizable, and publication-ready 
plots.

- Easily extendable, with support for user-defined visualizations through R for 
tailored analysis workflows.

We also compared `cellsight` with other popular single cell data visualisation 
tools, which further highlights the key features of `cellsight`.

| Feature                    | cellxgene                               | Vitessce                              | WebAtlas                              | cellsight                            |
|:---------------------------|:---------------------------------------:|:-------------------------------------:|:-------------------------------------:|:-------------------------------------:|
| Framework                  | JavaScript/Python/R                     | JavaScript/Python/R                   | Vitessce-based                        | R/Shiny                               |
| Spatial data support       | <span style="color:red;">limited</span> | <span style="color:green;">yes</span> | <span style="color:green;">yes</span> | <span style="color:green;">yes</span> |
| Multi-omics integration    | <span style="color:red;">limited</span> | <span style="color:green;">yes</span> | <span style="color:green;">yes</span> | <span style="color:green;">yes</span> |
| Cross-model queries        | <span style="color:red;">limited</span> | <span style="color:green;">yes</span> | <span style="color:green;">yes</span> | <span style="color:green;">yes</span> |
| Configuration Complexity   | low, via command line                   | high, via multiple joson files        | low, via parameter file               | low, via config object                |
| Customisation              | limited                                 | extensive but req. expertise          | limited                               | extensive and user-friendly           |
| R/Bioconductor Integration | via cellxgenedp package                 | via vitessceR package                 | <span style="color:red;">no</span>    | <span style="color:green;">full</span> |
| Deployment                 | primarily web-based                     | primarily web-based                   | primarily web-based                   | local and web-based                   |
| Local Deployment           | yes via R                               | local http server                     | local http server                     | yes, via Rstudio / Rstudio server     |


# Table of Contents and Additional Information / Tutorials
This readme is broken down into the following sections:

- [Installation](#installation) on how to install `cellsight`

- [Quick Start Guide](#quick-start-guide) to rapidly deploy a shiny app with a few lines of code

- [Frequently Asked Questions](#frequently-asked-questions)


# Installation

## Building  requirements

The default required packages for ShinyCell3 are the packages required to build
a CellSight shiny app instance. These packages will be install by default when 
install installing CellSight:

```r
install.packages("CellSight", dependencies = TRUE)
```

Or if you prefer to install individually:

```r
reqPkg = c("data.table", "Matrix", "hdf5r", "reticulate", "R.utils", 
           "ggplot2", "gridExtra", "glue", "readr", "future", "RColorBrewer")
newPkg = reqPkg[!(reqPkg %in% installed.packages()[,"Package"])]
if(length(newPkg)){install.packages(newPkg)}

# If you are using Seurat object as input (for scRNA, multiomics, spatial), 
#   you can install Seurat as follows:
# install.packages("Seurat")

# If you are using Signac object for scATAC-seq, you can install Signac as follows:
# install.packages("Signac")

# If you are using ArchR object as input for scATAC-seq, visit
#   https://github.com/GreenleafLab/ArchR for ArchR's installation instruction

# If you are using h5ad file as input, run code below
# reticulate::py_install("anndata")
```

Furthermore, on the system where the Shiny app will be deployed, users can run 
the following code to check if the packages required by the Shiny app exist 
and install them if required:

```r
install.packages("pak", dependencies = TRUE)
pak::pkg_install("ShinyCell3", dependencies = c("Depends", "Imports", "Config/Needs/viz"))
```


```r
reqPkg = c("shiny", "shinyhelper", "data.table", "Matrix", "DT", "magrittr", 
           "ggplot2", "ggrepel", "hdf5r", "ggdendro", "gridExtra", "ggpubr")
newPkg = reqPkg[!(reqPkg %in% installed.packages()[,"Package"])]
if(length(newPkg)){install.packages(newPkg)}
```

If one is deploying scATAC-seq / peak-based data, bwtools have to be installed 
for the track plots via the command line:
```bash
# Install dependencies for trackplot (on command line)
git clone https://github.com/CRG-Barcelona/libbeato.git
cd ./libbeato
git checkout 0c30432
./configure
make
make install
    
cd ..
git clone https://github.com/CRG-Barcelona/bwtool.git
cd ./bwtool
./configure
make
make check
make install
```

# Quick Start Guide
In short, the `cellsight` package takes in an input single-cell object and 
generates a cellsight config `scConf` containing labelling and colour palette 
information for the single-cell metadata. The ShinyCell config and single-cell 
object are then used to generate the files and code required for the shiny app. 

In this example, we will use single-cell CITE-seq data in the form of a Seurat 
object containing 162,000 PBMC cells measured with 228 antibodies, taken from 
the [Seurat object](https://satijalab.org/seurat/articles/multimodal_reference_mapping.html) 
can be [downloaded here](https://zenodo.org/records/15162323/files/multimodal_pbmc.rds?download=1).

A shiny app can be readily generated using the following code:
 
``` r
library(Seurat)
library(cellsight)

seu <- readRDS("multimodal_pbmc.rds")
scConf <- createConfig(seu)
makeShinyFiles(seu,scConf, shiny.prefix="sc1", shiny.dir="shinyApp/")
makeShinyCodes(shiny.title = "PBMC multiomics", shiny.prefix="sc1",
               shiny.dir="shinyApp/")
```

The generated shiny app can then be found in the `shinyApp/` folder (which is 
the default output folder). To run the app locally, use RStudio to open either 
`server.R` or `ui.R` in the shiny app folder and click on "Run App" in the top 
right corner. The shiny app can also be deployed online via online platforms 
e.g. [shinyapps.io](https://www.shinyapps.io/) and Amazon Web Services (AWS) 
or be hosted via Shiny Server. For further details, refer to 
[Instructions on how to deploy ShinyCell apps online](https://htmlpreview.github.io/?https://github.com/the-ouyang-lab/cellsight-tutorial/master/docs/cloud.html).

More details on the various visualisations in the `cellsight` can be found in
[Additional information on new visualisations tailored for spatial / scATAC-seq / multiomics](https://htmlpreview.github.io/?https://github.com/the-ouyang-lab/cellsight-tutorial/master/docs/addNewVis.html)
and [Additional information on enhanced visualisation features](https://htmlpreview.github.io/?https://github.com/the-ouyang-lab/cellsight-tutorial/master/docs/addEnhanVis.html)



# Frequently Asked Questions
- Q: How much memory / storage space does `cellsight` and the app consume?
  - A: The `cellsight` app consumes very little memory and is meant to be a 
       heavy-duty app where multiple users can access the app simultaneously. 
       Unlike typical R objects, the entire gene expression matrix is stored 
       on disk and *not on memory* via the hdf5 file system. Also, the hdf5 
       file system offers superior file compression and takes up less storage 
       space than native R file formats such as rds / Rdata files.
  - A: It should be noted that a large amount of memory is required when 
       *building* the `cellsight` app. This is because the whole single-cell 
       object has to be loaded onto memory and additional memory is required to 
       generate the required files. From experience, a typical laptop with 8GB 
       RAM can handle datasets around 30k cells while 16GB RAM machines can 
       handle around 60k-70k cells for scRNA-seq data. More memory will be 
       required for multiomics and especially scATAC-seq data. As a rule of 
       thumb, if you are able to perform analysis e.g. dimension reduction on 
       the machine, the machine should be able to build the `cellsight` app.
       
- Q: I have both RNA and integrated data in my Seurat object. How do I specify 
which gene expression assay to plot in the Shiny app?
  - A: Unlike the original ShinyCell, `cellsight` now supports multiple assays 
       within a single `cellsight` app. Thus, both the RNA and integrated data 
       will be incorporated and users can choose to visualise either assays or 
       even compare their expression in the `cellsight` app.

- Q: What types of single-cell data can cellsight handle?
  - A: cellsight supports various multi-omics formats including CITE-seq, 
       scATAC-seq, and both standard and spatial scRNA-seq data. It can 
       seamlessly switch between different data modalities such as RNA 
       expression and protein abundance.

- Q: How does cellsight improve upon its predecessor?
  - A: cellsight introduces enhanced features for multi-assay visualisation, 
       improved plotting capabilities, and advanced analysis tools. It offers 
       better UMAP visualisation with zooming, flexible data ordering, 
       customisable colour scales, and integrated statistical analysis tools.

- Q: Can I deploy cellsight apps locally and on the web?
  - A: Yes, cellsight apps can be run locally using RStudio and can also be 
       deployed online via platforms like shinyapps.io and Amazon Web Services 
       (AWS), or hosted via Shiny Server.

- Q: What are the main visualisation features of cellsight?
  - A: cellsight offers six common tabs: Zoom-enable DimRed, Side-by-side 
       DimRed, Gene coexpression, Violinplot/Boxplot, Proportional plot, and 
       Bubbleplot/Heatmap. It also has specific tabs for spatial data and 
       scATAC-seq data.

- Q: How does cellsight handle spatial transcriptomics data?
  - A: cellsight provides two spatial-specific tabs: "Zoom-enable Spatial" and 
       "Side-by-side Spatial", allowing users to visualise cell information or 
       gene expression overlaid on tissue images with zooming capabilities.

- Q: What special features does cellsight offer for scATAC-seq data?
  - A: For scATAC-seq data, cellsight offers a "Track plot" feature to 
       visualise open chromatin regions. It supports custom annotations (in 
       .bed file) and flexible region selection by gene or chromosomal region.

- Q: How does cellsight compare to other single-cell visualisation tools?
  - A: Compared to tools like cellxgene and Vitessce, cellsight offers more 
       extensive customisation options, full R/Bioconductor integration, and a 
       user-friendly interface with low configuration complexity.


