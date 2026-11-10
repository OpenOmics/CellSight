FROM ubuntu:22.04
LABEL maintainer="Skyler Kuhn <kuhnsa@nih.gov>, Ryan Routsong <routsongrm@nih.gov>"

# Two conda environments, so build-time and viz-time dependencies can't conflict:
#   cs-build : DESCRIPTION Depends/Imports + Seurat/Signac  (builds the app)
#   cs-viz   : DESCRIPTION Suggests used by the generated app (serves the app)
# cs-build is first on PATH, so build_cellsight.R etc. run in it by default.
# Serve an app with:  run_cellsight_app /path/to/app [port] [host]

ENV TZ=America/New_York \
    DEBIAN_FRONTEND=noninteractive \
    MAMBA_ROOT_PREFIX=/opt/conda \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8
RUN mkdir -p /opt2/work /data2
WORKDIR /opt2

# System packages: only what's needed for the native trackplot tools
# (libbeato / bwtool) and general utilities. R and its libraries come from conda.
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        build-essential \
        bzip2 \
        ca-certificates \
        cmake \
        curl \
        git \
        gzip \
        libjpeg-dev \
        libpng-dev \
        locales \
        pigz \
        rsync \
        unzip \
        vim \
        wget \
        zlib1g-dev \
    && localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /opt2/ \
        && wget --no-check-certificate -O /opt2/which.tar.gz https://ftp.gnu.org/gnu/which/which-2.21.tar.gz \
        && tar -xvf /opt2/which.tar.gz -C /opt2/ \
        && rm /opt2/which.tar.gz \
        && cd /opt2/which-2.21/ \
        && ./configure --prefix=/opt2/which-2.21 \
        && make \
        && make install

COPY --from=mambaorg/micromamba:2.0.5 /bin/micromamba /usr/local/bin/micromamba

# Native trackplot dependencies
COPY git_installs.sh /opt2/work/git_installs.sh
RUN cd /opt2/work && ./git_installs.sh

# ---- build environment -----------------------------------------------------
COPY environment-build.yml /opt2/environment-build.yml
RUN micromamba create -y -n cs-build -f /opt2/environment-build.yml \
    && micromamba clean -a -y

COPY env_tools.R /opt2/env_tools.R
# jinjar (CellSight Depends) is not guaranteed on conda; fall back to CRAN.
# CellSight itself comes straight from GitHub (dependencies already in conda).
RUN micromamba run -n cs-build Rscript /opt2/env_tools.R \
        required=jinjar \
        github=OpenOmics/CellSight
# Optional: ArchR (Suggests; not on CRAN/Bioconductor). Non-fatal.
RUN micromamba run -n cs-build Rscript /opt2/env_tools.R \
        github_optional=GreenleafLab/ArchR
RUN micromamba run -n cs-build Rscript /opt2/env_tools.R \
        check=cellsight,Seurat,SeuratObject,Signac,hdf5r,argparse,optparse,jinjar,qs2,BiocFileCache,data.table,Matrix,reticulate,ggplot2,gridExtra,readr,future,future.apply,RColorBrewer,styler,lintr,remotes,BiocManager,knitr,rmarkdown,BiocGenerics,GenomeInfoDb,rtracklayer,S4Vectors,SingleCellExperiment

# ---- viz environment -------------------------------------------------------
COPY environment-viz.yml /opt2/environment-viz.yml
RUN micromamba create -y -n cs-viz -f /opt2/environment-viz.yml \
    && micromamba clean -a -y
# shinydataviewer is on CRAN, not conda-forge. Optional: the generated app
# does not load it.
RUN micromamba run -n cs-viz Rscript /opt2/env_tools.R optional=shinydataviewer
RUN micromamba run -n cs-viz Rscript /opt2/env_tools.R \
        check=shiny,shinyhelper,DT,magrittr,data.table,Matrix,ggplot2,ggrepel,hdf5r,ggdendro,gridExtra,ggpubr,qs2,reactable,bslib

# ---- entry scripts ---------------------------------------------------------
# Make cs-build the default environment: non-interactive commands (docker run
# ... Rscript / build_cellsight.R) via PATH + CONDA_* vars, interactive shells
# (docker run -it ... bash) via a real `micromamba activate` in /etc/bash.bashrc.
ENV PATH=/opt/conda/envs/cs-build/bin:$PATH \
    CONDA_PREFIX=/opt/conda/envs/cs-build \
    CONDA_DEFAULT_ENV=cs-build
RUN printf '#!/usr/bin/env bash\nexec micromamba "$@"\n' > /usr/local/bin/conda \
    && cp /usr/local/bin/conda /usr/local/bin/mamba \
    && chmod +x /usr/local/bin/conda /usr/local/bin/mamba \
    && printf '\n# CellSight: default to the build environment\neval "$(micromamba shell hook --shell bash)"\nconda() { micromamba "$@"; }\nmamba() { micromamba "$@"; }\nmicromamba activate cs-build\n' >> /etc/bash.bashrc
ADD build_cellsight.R /usr/bin/build_cellsight.R
ADD seurat_inspector.R /usr/bin/seurat_inspector.R
ADD ingest_10x.R /usr/bin/ingest_10x.R
ADD run_app.R /usr/local/share/cellsight/run_app.R
RUN chmod +x /usr/bin/build_cellsight.R /usr/bin/seurat_inspector.R \
        /usr/bin/ingest_10x.R \
    && printf '#!/usr/bin/env bash\nexec /opt/conda/envs/cs-viz/bin/Rscript /usr/local/share/cellsight/run_app.R "$@"\n' \
        > /usr/local/bin/run_cellsight_app \
    && chmod +x /usr/local/bin/run_cellsight_app
EXPOSE 3838
