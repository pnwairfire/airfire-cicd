# Consumer Workflow Examples

This directory provides copy-and-paste caller workflow templates for downstream USFS AirFire repositories onboarding to the centralized `@v1` CI/CD system.

## Overview

Rather than authoring complex, bespoke GitHub Actions configurations in every repository, AirFire repositories invoke centralized reusable workflows published from `pnwairfire/airfire-cicd`.

Placing these caller examples under `examples/` ensures that GitHub Actions does not execute them within this central style guide repository while keeping them immediately accessible as reference code.

## Available Templates

| Template File | Target Repository Archetype | Reusable Workflows Invoked |
| :--- | :--- | :--- |
| [`consumer-python-ci.yml`](consumer-python-ci.yml) | Python applications, libraries, data processing tools | `reusable-docs.yml@v1`, `reusable-python.yml@v1` |
| [`consumer-node-ci.yml`](consumer-node-ci.yml) | Node.js applications, TypeScript services, web frontends | `reusable-docs.yml@v1`, `reusable-node.yml@v1` |
| [`consumer-terraform-ci.yml`](consumer-terraform-ci.yml) | Terraform Infrastructure as Code (IaC) repositories | `reusable-docs.yml@v1`, `reusable-terraform.yml@v1` |
| [`consumer-polyglot-ci.yml`](consumer-polyglot-ci.yml) | Full-stack repos with Python backend and Node.js frontend | `reusable-docs.yml@v1`, `reusable-python.yml@v1`, `reusable-node.yml@v1` |

## Onboarding Instructions

1. Copy the appropriate template to `.github/workflows/ci.yml` in your repository.
2. Review and adjust inputs (such as runtime versions or `working-directory` paths).
3. If your repository contains markdown documentation, ensure docs are placed in the directory specified by `docs_path` (default is `docs/`).
4. Refer to the [Repository Migration Runbook](../docs/how-to/migrating-a-repo-to-standard-ci.md) and [Reusable Workflows Reference](../docs/reference/reusable-workflows-reference.md) for detailed configuration parameters.
