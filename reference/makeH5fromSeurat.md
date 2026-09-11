# Make h5 object from Seurat assay data

Make h5 object from Seurat assay data

## Usage

``` r
makeH5fromSeurat(obj, sc1meta, filename, gex.assay, gex.slot, chunkSize)
```

## Arguments

- obj:

  input Seurat (v3+) object

- sc1meta:

  data.table of cell metadata

- filename:

  filename of output h5 file

- gex.assay:

  assay in Seurat object to use

- gex.slot:

  slot in single-cell assay to use

- chunkSize:

  number of genes written to h5file at any one time

## Value

h5 object

## Author

John F. Ouyang
