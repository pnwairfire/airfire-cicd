---
title: "How to Install and Use run-local-ci"
description: "Step-by-step guide for installing, configuring, and running run-local-ci to verify CI quality gates locally before committing or pushing."
published: true
editor: markdown
dateCreated: 2026-09-30T12:00:00.000Z
tags:
  - cicd
  - how-to
  - quality-gates
  - local-parity
---

# How to Install and Use run-local-ci

`run-local-ci` is the standard workstation verification utility for PNW AirFire repositories. It executes project quality gates, linters, formatters, and test suites locally before changes are committed or pushed to GitHub.

Running quality checks locally eliminates broken build notifications in team Slack channels (`#fasm-alerts`) and maintains clean, bisectable commit history.

---

## Prerequisites

- **Python 3.11+** installed on your workstation.
- **Git** installed and configured.
- **uv**: Modern Python package runner. Install via `curl -LsSf https://astral.sh/uv/install.sh | sh` if not already present.

---

## Installation

Download the executable script directly from the floating `@v1` release into your user binary directory:

```bash
curl -fsSL https://raw.githubusercontent.com/pnwairfire/airfire-cicd/v1/scripts/run-local-ci -o ~/.local/bin/run-local-ci
chmod +x ~/.local/bin/run-local-ci
```

### Ensure `~/.local/bin` is in your PATH

Verify that `~/.local/bin` is in your environment PATH:

```bash
echo $PATH | grep -q "$HOME/.local/bin" && echo "PATH is configured" || echo "Add ~/.local/bin to PATH"
```

If not already configured, append the following line to your shell configuration (`~/.bashrc` or `~/.zshrc`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## Verifying the Installation

Check the installed version to confirm accessibility:

```bash
run-local-ci --version
```

Expected output:

```text
run-local-ci 1.2.0
```

---

## Common Workflows

### 1. Standard Pre-Commit Verification

Execute `run-local-ci` from any repository root before creating a git commit:

```bash
run-local-ci
```

The runner automatically detects the repository archetype, discovers defined pre-push hooks or `.github/workflows/*.yml` configurations, and executes all quality checks.

### 2. Auto-Fixing Code & Formatting Errors

If format or lint errors occur, run with the `--fix` flag to automatically format Python, Markdown, and Terraform files:

```bash
run-local-ci --fix
```

Auto-fixing applies:
- **Python**: `uv run ruff check --fix .` and `uv run ruff format .`
- **Markdown**: `npx --yes markdownlint-cli2 --fix "**/*.md"`
- **Terraform**: `terraform fmt -recursive .`

Always review changes with `git diff` after running auto-fixes.

### 3. Inspect Discovered Checks (Dry Run)

To view all discovered checks, jobs, and workflows without executing them:

```bash
run-local-ci --list
```

### 4. Target a Subdirectory or Specific Repository

Use the `-C` flag to run quality gates against a specific subrepository:

```bash
run-local-ci -C path/to/service
```

### 5. Run Workflows in Docker via act

To test workflows inside containerized GitHub Actions runner environments:

```bash
run-local-ci --act
```

*(Requires `gh` CLI and the `nektos/act` extension: `gh extension install nektos/gh-act`)*.

---

## CLI Flag Reference

| Flag | Description |
| :--- | :--- |
| `--fix` | Automatically formats code and resolves autofixable lint errors before verification. |
| `--list` | Lists all discovered workflows, jobs, and quality checks without executing them. |
| `-C, --dir <PATH>` | Sets the target repository directory (default: current working directory). |
| `--workflow <FILE>` | Executes only steps matching a specific workflow filename (e.g. `ci.yml`). |
| `--job <ID>` | Executes only steps matching a specific job ID. |
| `--hook` | Forces execution of the repository pre-push hook script (`scripts/git-hooks/pre-push`). |
| `--act` | Executes workflows in Docker containers using `gh act`. |
| `-v, --verbose` | Displays verbose stdout and stderr for passing steps. |
| `--version` | Displays the program version and exits. |

---

## Updating run-local-ci

To update to the latest stable point release on the `@v1` stream, re-run the installation command:

```bash
curl -fsSL https://raw.githubusercontent.com/pnwairfire/airfire-cicd/v1/scripts/run-local-ci -o ~/.local/bin/run-local-ci
chmod +x ~/.local/bin/run-local-ci
```

---

## Related Documentation

- [Onboarding Your First Repository](../tutorials/onboarding-your-first-repository.md)
- [Reusable Workflows Reference](../reference/reusable-workflows-reference.md)
- [Migrating a Repository to Standardized CI/CD](migrating-a-repo-to-standard-ci.md)
- [Hub-and-Spoke Architecture](../explanation/hub-and-spoke-architecture.md)
