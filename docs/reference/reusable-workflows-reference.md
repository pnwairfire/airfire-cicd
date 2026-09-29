---
title: "Reusable Workflows Reference Specification"
description: "Technical reference and inputs specification for all centralized GitHub Actions reusable workflows published under pnwairfire/airfire-cicd@v1."
published: true
editor: markdown
dateCreated: 2026-09-29T12:00:00.000Z
tags:
  - cicd
  - reference
  - workflows
  - specifications
---

# Reusable Workflows Reference Specification

This document provides parameter specifications for all `workflow_call` templates in `pnwairfire/airfire-cicd`.

---

## 1. `reusable-docs.yml`

Validates documentation quality gates, Diátaxis frontmatter, Wiki.js namespace `README.md` hubs, and markdown formatting.

* **Caller URI**: `pnwairfire/airfire-cicd/.github/workflows/reusable-docs.yml@v1`

### Inputs

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `docs_path` | `string` | No | `"docs"` | Path to the directory containing documentation markdown. |
| `validate_frontmatter` | `boolean` | No | `true` | Enforces Diátaxis YAML frontmatter tags and namespace hubs. |
| `run_markdownlint` | `boolean` | No | `true` | Executes `markdownlint-cli2` across all documentation markdown. |

---

## 2. `reusable-python.yml`

Executes Python quality gates adhering to Modern Python standards using Astral `uv`.

* **Caller URI**: `pnwairfire/airfire-cicd/.github/workflows/reusable-python.yml@v1`

### Inputs

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `python-version` | `string` | No | `"3.12"` | Python version to provision via `uv python install`. |
| `run-ruff` | `boolean` | No | `true` | Runs `uv run ruff check .` and `uv run ruff format --check .`. |
| `run-tests` | `boolean` | No | `true` | Runs `uv run pytest`. |
| `pytest-args` | `string` | No | `"-v"` | Command line arguments forwarded to `pytest`. |
| `working-directory` | `string` | No | `"."` | Directory where Python project configuration lives. |

---

## 3. `reusable-node.yml`

Executes Node.js quality gates, package caching, linting, tests, and build bundle validation.

* **Caller URI**: `pnwairfire/airfire-cicd/.github/workflows/reusable-node.yml@v1`

### Inputs

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `node-version` | `string` | No | `"20"` | Node.js version to provision. |
| `package-manager` | `string` | No | `"npm"` | Package manager (`npm` or `pnpm`) for caching. |
| `run-lint` | `boolean` | No | `true` | Runs `npm run lint --if-present`. |
| `run-test` | `boolean` | No | `true` | Runs `npm test --if-present`. |
| `run-build` | `boolean` | No | `true` | Runs `npm run build --if-present`. |
| `working-directory` | `string` | No | `"."` | Directory containing Node package.json. |

---

## 4. `reusable-terraform.yml`

Executes Infrastructure-as-Code formatting, static analysis, and configuration validation.

* **Caller URI**: `pnwairfire/airfire-cicd/.github/workflows/reusable-terraform.yml@v1`

### Inputs

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `terraform-version` | `string` | No | `"1.9.0"` | Terraform version to provision. |
| `run-fmt` | `boolean` | No | `true` | Executes `terraform fmt -check -recursive .`. |
| `run-validate` | `boolean` | No | `true` | Executes `terraform init -backend=false && terraform validate`. |
| `run-tflint` | `boolean` | No | `true` | Executes `tflint --init && tflint --recursive`. |
| `working-directory` | `string` | No | `"."` | Directory containing Terraform HCL root. |
