---
title: "Tutorial: Onboarding Your First Repository to AirFire CI/CD"
description: "A practical learning lesson guiding developers through onboarding a new repository to centralized reusable GitHub Actions workflows."
published: true
editor: markdown
dateCreated: 2026-09-29T12:00:00.000Z
tags:
  - cicd
  - tutorial
  - onboarding
  - getting-started
---

# Tutorial: Onboarding Your First Repository to AirFire CI/CD

Welcome to AirFire continuous integration. In this tutorial, you will add automated quality gates to a repository using the organization's central reusable workflow hub (`pnwairfire/airfire-cicd@v1`).

By the end of this lesson, your repository will automatically validate code formatting, linting, tests, and documentation standards on every pull request.

---

## What You Will Need

- A local clone of an AirFire repository (Python, Node.js, Terraform, or Polyglot).
- Git installed and configured.
- The `run-local-ci` utility installed on your workstation:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/pnwairfire/airfire-cicd/v1/scripts/run-local-ci -o ~/.local/bin/run-local-ci
  chmod +x ~/.local/bin/run-local-ci
  ```
  *(See [How to Install and Use run-local-ci](../how-to/installing-and-using-run-local-ci.md) for full guide and CLI options)*.

---

## Step 1: Identify Your Repository Archetype

Different languages and frameworks require different quality checks. Inspect your repository root to determine its archetype:

- **Python Service**: Contains `pyproject.toml` or `requirements.txt`.
- **Node.js Application**: Contains `package.json` and `package-lock.json`.
- **Terraform Infrastructure**: Contains `.tf` files.
- **Polyglot Monorepo**: Contains multiple runtimes across subdirectories (e.g. `backend/` and `frontend/`).

For a detailed breakdown of archetypes, refer to the [Consumer Caller Archetypes Catalog](../reference/consumer-archetypes-catalog.md).

---

## Step 2: Create Your CI Workflow File

In your repository, create the `.github/workflows/` directory if it does not already exist:

```bash
mkdir -p .github/workflows
```

Now create a new workflow file at `.github/workflows/ci.yml`.

### Example: Onboarding a Python Repository

If your project is Python-based, paste the following caller configuration:

```yaml
name: Continuous Integration & Quality Gates

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  # 1. Documentation quality gates (runs if your repo contains a docs/ directory)
  docs-ci:
    name: Documentation Quality Gates
    uses: pnwairfire/airfire-cicd/.github/workflows/reusable-docs.yml@v1
    with:
      docs_path: "docs"
      validate_frontmatter: true
      run_markdownlint: true

  # 2. Python quality gates (runs ruff and pytest via uv)
  python-ci:
    name: Python Quality Gates
    uses: pnwairfire/airfire-cicd/.github/workflows/reusable-python.yml@v1
    with:
      python-version: "3.12"
      run-ruff: true
      run-tests: true
```

*Note: For Node.js, use `reusable-node.yml@v1`. For Terraform, use `reusable-terraform.yml@v1`.*

---

## Step 3: Run Quality Checks Locally

Before pushing to GitHub, always verify that your code satisfies quality standards locally. In your repository root, run:

```bash
run-local-ci
```

### Understanding the Output
- **Linters (`ruff` / `eslint`)**: Checks syntax, imports, and styling conventions.
- **Formatters (`ruff format` / `prettier`)**: Verifies consistent code layout.
- **Test Suites (`pytest` / `vitest`)**: Executes unit tests.
- **Documentation (`markdownlint` / `frontmatter`)**: Ensures markdown files and YAML headers meet Diátaxis standards.

If any check fails, address the warnings and run `run-local-ci` again until you see:
```text
ALL QUALITY GATES PASSED
```

---

## Step 4: Open a Pull Request and Observe the Central Pipeline

Now that local checks pass, push your changes on a feature branch:

```bash
git checkout -b chore/setup-central-ci
git add .github/workflows/ci.yml
git commit -m "ci: onboard repository to airfire-cicd reusable workflows"
git push origin chore/setup-central-ci
```

Open a pull request targeting `main` on GitHub:
1. Observe the **Checks** tab on your pull request.
2. Notice that GitHub Actions calls the centralized `@v1` workflows from `pnwairfire/airfire-cicd`.
3. When all checks turn green, merge your pull request.

---

## Congratulations

Your repository is now officially onboarded to AirFire's central CI action hub. Whenever the central hub receives performance updates, security patches, or new linter rules, your repository will inherit them automatically.

---

## Next Steps

- Register your documentation with the team wiki: [How to Migrate a Repository to Standard CI](../how-to/migrating-a-repo-to-standard-ci.md)
- Configure keyless cloud access: [How to Configure AWS OIDC](../how-to/configuring-aws-oidc.md)
- Understand the complete organizational standard: [AirFire CI/CD Style Guide](../cicd-style-guide.md)
