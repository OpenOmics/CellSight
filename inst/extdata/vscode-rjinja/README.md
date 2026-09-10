# rjinja VS Code Extension (bundled with CellSight)

This folder contains a bundled VS Code extension archive:

- `rjinja-syntax.tar.gz`

## What it is

`rjinja-syntax` is a Visual Studio Code syntax extension for R + Jinja template files (for example `*.R.jinja`).

## What it does

It provides editor support for mixed template/code files used by CellSight code generation templates, such as:

- Better syntax highlighting for Jinja tags embedded in R template files
- Improved readability when editing files under `inst/templates/`
- A more consistent authoring experience for CellSight template development

## Why it is included in this package

CellSight relies on R-Jinja template files to generate Shiny app code. Bundling this extension archive with the package makes it easy for developers to use the intended syntax tooling while working on template internals.

## How to use it

1. Extract `rjinja-syntax.tar.gz`.
2. In VS Code, install the extension from the extracted package/archive using **Install from VSIX...** (or equivalent for the packaged format).
3. Open CellSight template files (e.g. `*.R.jinja`) to use the syntax support.

## Notes

- This extension is optional for end users of CellSight.
- It is mainly intended for contributors who edit template files.
