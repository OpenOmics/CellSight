# Credits and attribution

CellSight is a derivative work. Most of what makes it useful was written
by other people, and this page records who, and what you have to
preserve if you redistribute it.

## Upstream project

CellSight is derived from
**[ShinyCell2](https://github.com/the-ouyang-lab/ShinyCell2)**,
developed in the Ouyang lab and distributed under GPL-3.0. Its original
authors are:

- **John F. Ouyang**
- **Beijun Chen**

Their authorship is still visible throughout the source: most functions
in the reference index carry an `@author John F. Ouyang` tag, because
they are still substantially his code. CellSight adds modifications,
extensions, refactors and documentation on top of that foundation — it
does not replace it.

## CellSight contributors

Maintained by the [OpenOmics](https://github.com/OpenOmics) group:

- **Ryan Routsong** (maintainer) — <ryan.routsong@nih.gov>
- **Skyler Kuhn**
- **Brittney Dulek**
- **Neelam Redekar**

The generated [authors
page](https://openomics.github.io/CellSight/authors.md) lists the same
set with their formal roles as recorded in `DESCRIPTION`.

## What CellSight changed

Relative to upstream, the substantive differences are:

- **A templated frontend.** The hand-written `wr*` code writers were
  replaced by [jinjar](https://davidchall.github.io/jinjar/) templates
  under `inst/templates`, with the generated output run through
  [styler](https://styler.r-lib.org) and linted as rendered in CI. See
  [`vignette("templates")`](https://openomics.github.io/CellSight/articles/templates.md).
- **Broader spatial support**, including multi-slide objects with a
  slide selector.
- **A DEG page** driven by precomputed differential-expression tables.
- **Container tooling** under `tools/docker/CellSight/`, with CLI
  wrappers for building apps and for ingesting raw 10x Visium HD output.
  See
  [`vignette("docker")`](https://openomics.github.io/CellSight/articles/docker.md).

`NEWS.md` records this per release; `NOTICE` records the derivative-work
claim itself.

## Licensing

CellSight is licensed under the **GNU General Public License v3.0**, the
same licence as ShinyCell2. The [full
text](https://openomics.github.io/CellSight/LICENSE.md) ships with the
package.

GPL-3.0 is a copyleft licence, so if you redistribute CellSight —
modified or not — you need to:

1.  **Keep the full licence text** with the source distribution
    (`LICENSE`).
2.  **Preserve the attribution and derivative-work notice** (`NOTICE`).
    This is why `NOTICE` is deliberately *not* in `.Rbuildignore`: it
    must travel with the built tarball, not just live in the git
    repository.
3.  **Distribute your modifications under GPL-3.0** as well.

This applies to your fork of CellSight, not to apps you generate with
it: the data and figures in a CellSight app are yours.

CellSight is distributed **without any warranty**, without even the
implied warranty of merchantability or fitness for a particular purpose.
See the licence for the full disclaimer.

## Citing

Cite the upstream method alongside CellSight — the visualisation
approach and most of the implementation are ShinyCell2’s work. For
CellSight’s own metadata:

``` r

citation("cellsight")
```

## Third-party components

Beyond CellSight’s R dependencies, two components are worth naming
because they carry their own terms:

- **`bwtool`** and **`libbeato`** ([CRG
  Barcelona](https://github.com/CRG-Barcelona)) — command-line binaries
  required at runtime for ATAC track plots. Not installed by
  [`install.packages()`](https://rdrr.io/r/utils/install.packages.html);
  see
  [`vignette("modalities")`](https://openomics.github.io/CellSight/articles/modalities.md).
- **`rjinja-syntax`**, the bundled VS Code syntax extension for
  `*.R.jinja` files at `inst/extdata/vscode-rjinja/`. Optional, and only
  useful to contributors.

Generated apps also depend on the packages listed under
`Config/Needs/viz` in `DESCRIPTION`, each under its own licence — see
[`vignette("deployment")`](https://openomics.github.io/CellSight/articles/deployment.md).

## Reporting problems

Bugs and feature requests:
<https://github.com/OpenOmics/CellSight/issues>.

If the issue looks like it comes from the shared visualisation code
rather than from CellSight’s additions, it may be worth checking
[ShinyCell2’s
issues](https://github.com/the-ouyang-lab/ShinyCell2/issues) too.
