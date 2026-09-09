# GitHub Actions Workflows

This directory contains CI/CD workflows for the cellsight R package.

## Workflows

### PR Installation Gate (`pr-gate.yml`)

**Purpose**: PR gating - ensures the package can be installed before allowing merge.

**Triggers**:
- Pull requests to `main` or `develop` branches
- Runs on PR open, update, or reopen

**What it does**:
1. Installs R 4.5.0
2. Displays R version for verification
3. Installs system dependencies (libcurl, libssl, libxml2, libhdf5)
4. Installs package dependencies from DESCRIPTION
5. Attempts to install cellsight
6. Tests that the package loads successfully
7. Verifies core functions exist (wrShFunc, wrSVmainA1, wrSVmainD1)

**Duration**: ~2-5 minutes

This is the primary gate for PRs - if this fails, the PR cannot be merged.

---

## Status Badge

Add this to your README.md:

```markdown
[![PR Installation Gate](https://github.com/OpenOmics/cellsight/actions/workflows/pr-gate.yml/badge.svg)](https://github.com/OpenOmics/cellsight/actions/workflows/pr-gate.yml)
```

## Debugging Failed Checks

If a workflow fails:

1. Check the Actions tab on GitHub
2. Click on the failed workflow run
3. Expand the failed step to see error details
4. Check uploaded artifacts (if any) for detailed logs

Common failures:
- **Missing dependencies**: Add to DESCRIPTION file
- **Namespace issues**: Run `devtools::document()` locally
- **Test failures**: Run `devtools::test()` locally
- **Build failures**: Run `devtools::check()` locally
