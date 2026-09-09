# Shiny app code templates

`makeShinyCodes()` assembles the three generated files — `server.R`, `ui.R`,
and `shinyFunc.R` — from the [jinjar](https://davidchall.github.io/jinjar/)
templates in this directory. To change what the generated app contains, edit
the template that owns that piece and reinstall the package.

## Layout

```
templates/
  server.R.jinja          master: orders the server.R blocks
  ui.R.jinja              master: orders the ui.R blocks (+ single/multi layout)
  shinyFunc.R.jinja       self-contained: the full shinyFunc.R
  partials/
    server/…            one file per server.R block
    ui/…                one file per ui.R block
```

The `server` and `ui` **masters** hold the orchestration logic (which blocks
appear, in what order, gated on whether a dataset has spatial / ATAC / DEG
data, and the single- vs multi-dataset layout). Each `{% include %}`s one
**partial** per block. Edit a master to change *which* blocks appear or their
order; edit a partial to change the *content* of one block.

`shinyFunc.R.jinja` is essentially a plain R file — the shared plotting
functions used by every tab — with one small trailing
`{% for d in datasets %}{% if d.has_bw %}…{% endif %}{% endfor %}` block that
appends the ATAC track-plot helpers once per ATAC dataset. Edit it as ordinary
R; leave that trailing block in place.

## Partial reference (file name → what it produces)

Each interactive tab is one partial in both `server/` (reactive logic) and
`ui/` (layout). The file name matches the tab's purpose:

| file (server/ + ui/)       | tab title in the app        |
| -------------------------- | --------------------------- |
| `dimred-zoom`              | Zoom-enable Dimred          |
| `dimred-sidebyside`        | Side-by-side DimRed         |
| `dimred-coexpression`      | Gene coexpression           |
| `dimred-split`             | Split-out DimRed            |
| `deg-dimred`               | DEG dimred plot             |
| `spatial-zoom`             | Zoom-enable Spatial         |
| `spatial-sidebyside`       | Side-by-side Spatial        |
| `trackplot`                | Track plot (ATAC)           |
| `violin-box`               | Violinplot / Boxplot        |
| `proportion`               | Proportion plot             |
| `bubble-heatmap`           | Bubbleplot / Heatmap        |
| `module-score`             | Module scoring              |

Every non-tab block now lives directly inside a master template (or, for
Google Analytics, inside `R/makeShinyCodes.R`) rather than in its own partial
file — see the next section. The `shinyFunc.R` content (shared plotting
functions + ATAC track-plot helpers) similarly lives in the self-contained
`shinyFunc.R.jinja` described above.

### Inlined blocks (no partial file)

Short, structural, or rarely-edited blocks are written straight into the master
templates. Edit them there:

| block                       | where it lives                                     |
| --------------------------- | -------------------------------------------------- |
| library calls               | top of `server.R.jinja` and `ui.R.jinja`           |
| preamble (palettes, panel sizes, `shinyServer(...)` / `shinyUI(...)` open, helpers) | after the library calls in `server.R.jinja` and `ui.R.jinja` |
| per-dataset data loads       | the first `{% for d in datasets %}` loop in `server.R.jinja` / `ui.R.jinja` (with `-spatial` / `-track` variants gated on `d.has_image` / `d.has_bw`) |
| closing lines               | end of `server.R.jinja` (`}) `) and `ui.R.jinja` (footnote + page close) |
| `google-analytics.html`     | the `ga_html` raw string in `R/makeShinyCodes.R`   |

### UI spatial variants

The spatial tabs need layout variants that the masters pick between:

| file                                | when it is used                                   |
| ----------------------------------- | ------------------------------------------------- |
| `spatial-zoom` / `spatial-sidebyside` | single-slide dataset                            |
| `spatial-zoom-multislide` / `spatial-sidebyside-multislide` | multi-slide dataset (adds a slide selector) |
| `spatial-sidebyside-extra`          | **unused** — legacy duplicate of `spatial-sidebyside` (same server bindings, first dataset's point-size defaults). No longer `{% include %}`d after the menus were regrouped by content; kept only for reference. |

## Template syntax

These templates use non-default jinjar delimiters so the generated R/Shiny
code's own `{ }` braces pass through untouched:

- `<< var >>`   — variable interpolation (jinjar's usual `{{ }}` is remapped)
- `{% if %}` / `{% for %}` / `{% include %}` — control tags (jinjar defaults)

Inside a `{% for d in datasets %}` loop, per-dataset fields are referenced as
`<< d.prefix >>`, `<< d.ptsiz >>`, etc. The context (the `datasets` list and
the top-level flags) is built in `R/makeShinyCodes.R`.

## Formatting and linting

You do **not** need to keep the partials' indentation "correct" for the final
app: a partial is `{% include %}`d at different nesting depths (a tab lives
inside a content `navbarMenu(...)` in both layouts, and one level deeper still in
the multi-dataset layout, where each dataset's pages sit under a per-dataset
dropdown-header), so no single indentation could be right everywhere.

Instead, `makeShinyCodes()` runs [`styler`](https://styler.r-lib.org) on the
fully-assembled `server.R`, `ui.R`, and `shinyFunc.R` after rendering. styler
re-indents and re-spaces the complete programs, so the generated code that users
run is consistently formatted regardless of how the fragments were laid out.
styler is formatting-only — it never changes behaviour — and is optional: if it
is not installed the generated files are left valid but un-styled.

Write partials to be **readable on their own**; leave final layout to styler.

### Whitespace still matters in the masters

The generated files no longer need to be byte-exact, but the master templates
still control *structure*: jinjar emits any text *between* control tags,
including newlines. Keep the `{% … %}` tags in `server.R.jinja` / `ui.R.jinja` /
`shinyFunc.R.jinja` on a single line with no spaces between them — a stray
newline between two `{% include %}` tags would inject a blank line (styler
tidies spacing, but structural line breaks in the wrong place can still change
the assembled output).

### Linting

Templates are linted **as rendered**, not as fragments — the fragments contain
jinjar tokens and are not valid R on their own. Run:

```
Rscript tools/render-and-lint.R
```

It renders a fully-featured app (multi-dataset, spatial multi-slide, ATAC, DEG),
checks the generated R parses, and lints it. It exits non-zero if a template
fails to render, the output is not valid R, or any lint remains — and runs in CI
on every PR (`.github/workflows/lint-templates.yml`). The linter config there
lets styler own layout (indentation off) and allows the upstream ShinyCell house
style (`=` assignment, camelCase/dotted names, explicit `return()`, etc.).
