---
title: "Consumer Caller Archetypes Catalog"
description: "Reference catalog mapping AirFire repository architectures to standard reusable CI caller templates in examples/."
published: true
editor: markdown
dateCreated: 2026-09-29T12:00:00.000Z
tags:
  - cicd
  - reference
  - archetypes
  - templates
---

# Consumer Caller Archetypes Catalog

This reference document catalogs standard repository archetypes across the USFS AirFire organization and maps them to pre-configured caller templates in `examples/`.

For parameter specifications of called workflows, consult the [Reusable Workflows Reference Specification](reusable-workflows-reference.md).

---

## Archetype Summary Matrix

| Archetype | Identifying Files | Central Caller Template | Called Workflows |
| :--- | :--- | :--- | :--- |
| **Python Service / Pipeline** | `pyproject.toml`, `requirements.txt`, `src/`, `tests/` | [consumer-python-ci.yml](../../examples/consumer-python-ci.yml) | `reusable-docs.yml@v1`<br>`reusable-python.yml@v1` |
| **Node.js Web App / SPA** | `package.json`, `package-lock.json`, `src/` | [consumer-node-ci.yml](../../examples/consumer-node-ci.yml) | `reusable-docs.yml@v1`<br>`reusable-node.yml@v1` |
| **Terraform Infrastructure** | `*.tf`, `terraform/`, `environments/` | [consumer-terraform-ci.yml](../../examples/consumer-terraform-ci.yml) | `reusable-docs.yml@v1`<br>`reusable-terraform.yml@v1` |
| **Polyglot Monorepo** | Multi-runtime root (`backend/`, `frontend/`, `terraform/`) | [consumer-polyglot-ci.yml](../../examples/consumer-polyglot-ci.yml) | `reusable-docs.yml@v1`<br>`reusable-python.yml@v1`<br>`reusable-node.yml@v1` |

---

## 1. Python Archetype

### Scope & Target Projects
Applies to Python packages, CLI tools, automated ETL pipelines, and Prefect flow repositories (e.g. `prefect-af-managed`, `airfire-observability`, `cloud-downloader`).

### Key Capabilities
- Automated documentation quality gates if a `docs/` directory is present.
- Python runtime provisioning via Astral `uv` (`3.12` default).
- Linter and formatter verification using `ruff check` and `ruff format --check`.
- Unit test execution via `pytest` with configurable arguments.

### Minimal Caller Configuration
```yaml
name: Continuous Integration

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  python-ci:
    name: Python Quality Gates
    uses: pnwairfire/airfire-cicd/.github/workflows/reusable-python.yml@v1
    with:
      python-version: "3.12"
      run-ruff: true
      run-tests: true
```

---

## 2. Node.js Archetype

### Scope & Target Projects
Applies to interactive mapping clients, Svelte SPAs, and JavaScript/TypeScript libraries (e.g. `fasm-v4`, `outlook-viewer-v2`, `fasm-shared`).

### Key Capabilities
- Dependency installation and cache optimization for `npm` or `pnpm`.
- Code quality checks via `npm run lint --if-present`.
- Framework and type checks via `npm run check --if-present`.
- Unit testing via `npm test --if-present`.
- Build verification via `npm run build --if-present`.

### Minimal Caller Configuration
```yaml
name: Continuous Integration

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  node-ci:
    name: Node.js Quality Gates
    uses: pnwairfire/airfire-cicd/.github/workflows/reusable-node.yml@v1
    with:
      node-version: "22"
      package-manager: "npm"
      run-lint: true
      run-test: true
      run-build: true
```

---

## 3. Terraform Archetype

### Scope & Target Projects
Applies to repositories managing AWS infrastructure, Cloudflare edge policies, and ECS deployments (e.g. `wiki-infra`, `airfire-auth`).

### Key Capabilities
- Format enforcement via `terraform fmt -check -recursive`.
- Static analysis via `tflint`.
- Syntax and schema validation via `terraform init -backend=false && terraform validate`.

### Minimal Caller Configuration
```yaml
name: Continuous Integration

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  terraform-ci:
    name: Terraform Quality Gates
    uses: pnwairfire/airfire-cicd/.github/workflows/reusable-terraform.yml@v1
    with:
      terraform-version: "1.9.0"
      run-fmt: true
      run-validate: true
      run-tflint: true
```

---

## 4. Polyglot Archetype

### Scope & Target Projects
Applies to composite repositories maintaining both backend services and frontend user interfaces in subdirectories.

### Key Capabilities
- Runs documentation, backend, and frontend checks in parallel.
- Scopes working directories cleanly (e.g. `working-directory: "backend"` for Python, `working-directory: "frontend"` for Node.js).
- Prevents cross-runtime dependency pollution.

For complete implementation examples, inspect [consumer-polyglot-ci.yml](../../examples/consumer-polyglot-ci.yml).
