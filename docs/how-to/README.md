---
title: "How-To Guides Hub"
description: "Step-by-step operational recipes for configuring, migrating, releasing, and verifying AirFire CI/CD workflows."
published: true
editor: markdown
dateCreated: 2026-09-30T12:00:00.000Z
tags:
  - cicd
  - how-to
  - hub
  - operations
---

# How-To Guides Hub

Step-by-step recipes designed to solve specific operational problems and workflows across AirFire services.

* **[How to Migrate a Repository to Standard CI](migrating-a-repo-to-standard-ci.md)**: 4-step checklist to replace bespoke CI scripts with centralized `@v1` reusable workflow callers.
* **[How to Configure AWS OIDC Federation](configuring-aws-oidc.md)**: Recipe for configuring AWS IAM Identity Providers and restricted web identity trust policies.
* **[How to Configure GitHub Environments](configuring-github-environments.md)**: Recipe for setting up development, staging, and production environment gates and deployment concurrency locks.
* **[How to Manage Secrets and Variables](managing-secrets-and-variables.md)**: Best practices for storing configuration in GitHub Variables (`vars.*`), confidential tokens in Secrets (`secrets.*`), and pulling runtime credentials dynamically from AWS Secrets Manager.
* **[How to Install and Use run-local-ci](installing-and-using-run-local-ci.md)**: Recipe for installing, updating, and running local CI quality gate verifications.
* **[How to Release Workflow Updates](releasing-workflow-updates.md)**: Maintainer instructions for testing, tagging immutable point releases (`v1.x.y`), and advancing the floating major tag (`v1`).
