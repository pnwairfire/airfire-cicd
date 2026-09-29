---
title: "How to Migrate a Repository to Standardized AirFire CI/CD"
description: "Step-by-step guide for migrating any AirFire repository (Python, Node.js, Terraform, or Polyglot) to centralized reusable workflows and decoupled documentation aggregation."
published: true
editor: markdown
dateCreated: 2026-09-29T12:00:00.000Z
tags:
  - cicd
  - how-to
  - standardization
  - workflows
---

# Migrating a Repository to Standardized AirFire CI/CD

This recipe walks through onboarding any PNW AirFire repository to the centralized `@v1` reusable workflow architecture.

## Overview of the Architecture

* **Central Workflows (`@v1`)**: Workflows are defined in `pnwairfire/airfire-cicd` and called via GitHub Actions `workflow_call`.
* **Zero Deploy Keys**: Contributing repositories never push directly to `pnwairfire/knowledge-base`; instead, the central knowledge base pulls documentation.
* **Local Parity**: All checks run locally via `run-local-ci` before commits or pushes.

---

## 4-Step Migration Checklist

### Step 1: Add Lean `.github/workflows/ci.yml`
Create or replace `.github/workflows/ci.yml` in your repository. Select the relevant reusable workflow(s) for your repository archetype:

```yaml
name: Continuous Integration & Quality Gates

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  # 1. Documentation Quality Gates (if repo contains docs/)
  docs-ci:
    name: Documentation Quality Gates
    uses: pnwairfire/airfire-cicd/.github/workflows/reusable-docs.yml@v1
    with:
      docs_path: "docs"
      validate_frontmatter: true
      run_markdownlint: true

  # 2. Python Pipeline Quality Gates (if repo is Python)
  python-ci:
    name: Python Quality Gates
    uses: pnwairfire/airfire-cicd/.github/workflows/reusable-python.yml@v1
    with:
      python-version: "3.12"
      run-ruff: true
      run-tests: true
```

For Node.js applications, use `reusable-node.yml@v1`. For Terraform infrastructure repos, use `reusable-terraform.yml@v1`. Polyglot repositories can compose multiple jobs in parallel.

### Step 2: Register in `knowledge-base/catalog.yaml`
If your repository authors documentation intended for the team Wiki:
1. Open `pnwairfire/knowledge-base/catalog.yaml`.
2. Register your repository under `sources`:
   ```yaml
   sources:
     - repo: "pnwairfire/<your-repo-name>"
       branch: "main"
       source_dir: "docs"
       dest_dir: "services/<domain>/<subservice>"
       description: "Short description of the service"
   ```

### Step 3: Delete Deprecated Custom Sync Scripts & Secrets
1. Delete any repository-local push scripts (e.g. `scripts/sync_to_knowledge_base.py`, `scripts/sync_docs_to_kb.sh`).
2. Delete any old post-merge push workflows (e.g. `.github/workflows/sync-docs-to-knowledge-base.yml`).
3. Remove the `KNOWLEDGE_BASE_DEPLOY_KEY` secret from your repository's GitHub Settings. Contributing repos require zero external write secrets.

### Step 4: Verify Locally with `run-local-ci`
Run the local verification tool before committing:

```bash
run-local-ci
```

Once all linters, unit tests, and frontmatter checks exit 0, commit your changes.
