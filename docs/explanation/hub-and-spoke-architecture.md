---
title: "Explanation: Central Reusable Hub Architecture"
description: "Architectural rationale for centralizing AirFire CI/CD workflows using GitHub Actions workflow_call and floating major version tags."
published: true
editor: markdown
dateCreated: 2026-09-29T12:00:00.000Z
tags:
  - cicd
  - explanation
  - architecture
  - governance
---

# Explanation: Central Reusable Hub Architecture

This document explains the architectural rationale behind establishing `pnwairfire/airfire-cicd` as the central reusable workflow hub for the USFS AirFire research group.

---

## 1. The Problem: Workflow Sprawl and Configuration Drift

Prior to centralizing CI/CD, each satellite repository (including `fasm-v4`, `tileserver-pwfsl`, `airfire-observability`, and various data ingestion pipelines) maintained its own standalone `.github/workflows/` directory.

This copy-paste model introduced critical failure modes:

1. **Tooling Inconsistency**: Repositories drifted across different Python versions (3.10 vs 3.11 vs 3.12), package managers (`pip`, `poetry`, `uv`), and linters (`flake8`, `black`, `ruff`).
2. **Security Vulnerabilities**: Third-party GitHub Actions were pinned inconsistently or left unpatched across older repositories.
3. **High Maintenance Overhead**: Updating a common requirement (such as adopting Astral `uv` or updating a linter rule) required editing and testing dozens of separate repositories.
4. **Accidental Deployments**: Educational and test templates with active `on: push` triggers in `.github/workflows/` caused rogue deployments to `dev` and `prod` cloud resources.

---

## 2. The Solution: Hub-and-Spoke Reusable Workflows

The central hub architecture separates workflow implementation from workflow invocation:

```text
                  ┌──────────────────────────────────────────────┐
                  │      pnwairfire/airfire-cicd Action Hub      │
                  │                                              │
                  │   - reusable-docs.yml@v1                     │
                  │   - reusable-python.yml@v1                   │
                  │   - reusable-node.yml@v1                     │
                  │   - reusable-terraform.yml@v1                │
                  └───────────────────────┬──────────────────────┘
                                          │
                   workflow_call          │ (@v1 floating tag)
                                          │
        ┌─────────────────────────────────┼─────────────────────────────────┐
        ▼                                 ▼                                 ▼
┌──────────────────┐             ┌──────────────────┐             ┌──────────────────┐
│  Python Service  │             │  Node / Web App  │             │  Terraform Repo  │
│  (prefect, etc.) │             │  (fasm-v4, etc.) │             │  (wiki-infra)    │
│                  │             │                  │             │                  │
│ ci.yml:          │             │ ci.yml:          │             │ ci.yml:          │
│   uses: .../     │             │   uses: .../     │             │   uses: .../     │
│   reusable-      │             │   reusable-      │             │   reusable-      │
│   python.yml@v1  │             │   node.yml@v1    │             │   terraform.yml@1│
└──────────────────┘             └──────────────────┘             └──────────────────┘
```

### Key Principles

- **Single Point of Truth**: Workflows live in `pnwairfire/airfire-cicd/.github/workflows/`.
- **Zero Local Workflow Duplication**: Consuming repositories contain only a lightweight caller workflow (`.github/workflows/ci.yml`) specifying desired parameters (e.g. `python-version: "3.12"`).
- **Strict Separation of Examples**: To ensure only valid callable workflows reside in `.github/workflows/`, all educational templates and caller examples are strictly isolated in `examples/`.

---

## 3. Versioning Strategy: Floating Major Tags

A major challenge in reusable workflows is balancing update propagation with change stability:

1. **If consumers pin to commit SHAs (`@a1b2c3d`)**: High stability, but security patches and linter upgrades never propagate to repositories without manual PRs across every repo.
2. **If consumers pin to branches (`@main`)**: High propagation, but untested commits on `main` can immediately break builds across the organization.

### The Floating Tag Compromise (`@v1`)
AirFire standardizes on the **floating major tag pattern**:

1. **Immutable Point Releases**: Every verified release is tagged with an annotated SemVer tag (e.g. `v1.0.0`, `v1.1.0`).
2. **Advancing the Floating Tag**: The `v1` tag is forced to point to the newest verified point release:
   ```bash
   git tag -fa v1 -m "Update v1 reusable workflows to v1.1.0"
   git push origin v1 --force
   ```
3. **Consumer Stability**: Downstream repositories reference `@v1`. Non-breaking updates propagate immediately. Repositories requiring strict audit immutability retain the option to pin to `@v1.1.0`.

---

## 4. Architectural Outcomes

- **Enforced Modern Standards**: All Python CI uses `uv`, Python 3.12, and `ruff`; all Node CI uses Node 22 LTS; all Terraform CI runs `tflint` and `validate`.
- **Local Parity via `run-local-ci`**: Because central reusable workflows mirror local verification commands, developers and agents encounter zero discrepancies between local checks and GitHub Actions checks.
- **Auditability**: Cloud security, dependency caching, and OIDC federation policies are verified and updated in one authoritative repository.
