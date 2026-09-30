---
title: "AirFire CI/CD Documentation Hub"
description: "Central documentation directory organized across the four Diátaxis quadrants: Explanation, How-To Guides, Reference, and Tutorials."
published: true
editor: markdown
dateCreated: 2026-09-29T12:00:00.000Z
tags:
  - cicd
  - hub
  - diataxis
  - documentation
---

# AirFire CI/CD Documentation Hub

Welcome to the central documentation hub for Continuous Integration and Continuous Deployment (CI/CD) across the USFS Pacific Northwest Research Station AirFire team.

This documentation suite is organized according to the **Diátaxis Documentation Framework**, systematically dividing information into four distinct cognitive quadrants:

```text
                        TO SERVE OUR PRACTICAL NEEDS
                                     │
                 How-To Guides       │       Tutorials
               (Problem-oriented)    │   (Learning-oriented)
                                     │
    ── WORK ─────────────────────────┼───────────────────────── STUDY ──
                                     │
                   Reference         │      Explanation
              (Information-oriented) │ (Understanding-oriented)
                                     │
                        TO SERVE OUR THEORETICAL NEEDS
```

---

## 1. Explanation (Understanding-Oriented)
Clarifies the architectural philosophy, operational team realities, and design decisions behind AirFire software delivery.

* **[USFS AirFire CI/CD Style Guide & Engineering Policy](cicd-style-guide.md)**: The authoritative organizational standard covering team operational reality, trunk-based branching, environment tiers (`dev`, `staging`, `prod`), deployment footprints, and keyless cloud security.
* **[Central Reusable Hub Architecture](explanation/hub-and-spoke-architecture.md)**: Deep-dive on eliminating copy-paste workflow sprawl through centralized GitHub Actions and floating major tags (`@v1`).
* **[Decoupled Documentation Plane](explanation/decoupled-documentation-plane.md)**: Deep-dive on the zero-deploy-key security architecture for aggregating documentation into `pnwairfire/knowledge-base`.

---

## 2. How-To Guides (Problem-Oriented)
Step-by-step recipes designed to solve specific operational problems and workflows.

* **[How to Migrate a Repository to Standard CI](how-to/migrating-a-repo-to-standard-ci.md)**: 4-step checklist to replace bespoke CI scripts with centralized `@v1` reusable workflow callers.
* **[How to Configure AWS OIDC Federation](how-to/configuring-aws-oidc.md)**: Recipe for configuring AWS IAM Identity Providers and restricted web identity trust policies.
* **[How to Configure GitHub Environments](how-to/configuring-github-environments.md)**: Recipe for setting up development, staging, and production environment gates and deployment concurrency locks.
* **[How to Manage Secrets and Variables](how-to/managing-secrets-and-variables.md)**: Best practices for storing configuration in GitHub Variables (`vars.*`), confidential tokens in Secrets (`secrets.*`), and pulling runtime credentials dynamically from AWS Secrets Manager.
* **[How to Install and Use run-local-ci](how-to/installing-and-using-run-local-ci.md)**: Recipe for installing, updating, and running local CI quality gate verifications.
* **[How to Release Workflow Updates](how-to/releasing-workflow-updates.md)**: Maintainer instructions for testing, tagging immutable point releases (`v1.x.y`), and advancing the floating major tag (`v1`).

---

## 3. Reference (Information-Oriented)
Deterministic technical specifications of machinery, parameters, schemas, and configurations.

* **[Reusable Workflows Reference Specification](reference/reusable-workflows-reference.md)**: Complete parameter specifications, input defaults, and outputs for all `@v1` workflows (`reusable-docs`, `reusable-python`, `reusable-node`, `reusable-terraform`).
* **[Consumer Caller Archetypes Catalog](reference/consumer-archetypes-catalog.md)**: Directory signals, minimal workflow YAML snippets, and mapping guidance for Python, Node.js, Terraform, and Polyglot projects.
* **[AWS IAM OIDC Trust Policy Specification](reference/iam-trust-policy-spec.md)**: Ready-to-copy JSON trust policy documents for development, staging, production, and tag-scoped roles.

---

## 4. Tutorials (Learning-Oriented)
Practical lessons guiding a newcomer or autonomous agent from scratch to a working deployment.

* **[Tutorial: Onboarding Your First Repository to AirFire CI/CD](tutorials/onboarding-your-first-repository.md)**: A complete, guided walkthrough demonstrating archetype selection, caller workflow creation, local validation via `run-local-ci`, and pull request execution.

---

## Central Workflows Quick Reference

All consuming repositories call centralized workflows using the `@v1` major version tag:

```yaml
# Documentation Quality Gates (Diátaxis frontmatter + markdownlint)
uses: pnwairfire/airfire-cicd/.github/workflows/reusable-docs.yml@v1

# Python Services & Pipelines (uv + ruff + pytest)
uses: pnwairfire/airfire-cicd/.github/workflows/reusable-python.yml@v1

# Node.js Frontends & Libraries (npm/pnpm + eslint + test + build)
uses: pnwairfire/airfire-cicd/.github/workflows/reusable-node.yml@v1

# Infrastructure as Code (terraform fmt + tflint + validate)
uses: pnwairfire/airfire-cicd/.github/workflows/reusable-terraform.yml@v1
```

For starter templates, inspect the caller files in [examples/](../examples/).
