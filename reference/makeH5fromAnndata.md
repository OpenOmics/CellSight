# Make h5 object from Anndata assay

Make h5 object from Anndata assay

## Usage

``` r
makeH5fromAnndata(obj, sc1meta, filename, gex.assay, chunkSize)
```

## Arguments

- obj:

  input file path for h5ad file

- sc1meta:

  data.table of cell metadata

- filename:

  filename of output h5 file

- gex.assay:

  assay in anndata object to use

- chunkSize:

  number of genes written to h5file at any one time

## Value

h5 object

## Author

John F. Ouyang
