---
title: "How to Configure GitHub Environments and Deployment Protection Gates"
description: "Step-by-step recipe for configuring development, staging, production, and domain-specific environment protection gates and concurrency locks."
published: true
editor: markdown
dateCreated: 2026-09-29T12:00:00.000Z
tags:
  - cicd
  - how-to
  - github
  - environments
  - security
---

# How to Configure GitHub Environments and Deployment Protection Gates

This guide provides instructions for configuring GitHub Environments in AirFire repositories. Standardizing environment targets isolates configuration variables, prevents unauthorized production rollouts, and ensures deployment stability.

For organizational policies on environment promotion, consult the [AirFire CI/CD Style Guide](../cicd-style-guide.md).

---

## 1. Overview of Standard Environment Tiers

AirFire repositories target three core lifecycle environments and recognized domain-specific tiers:

| Environment | Purpose | Protection Rule | Trigger Pattern |
| :--- | :--- | :--- | :--- |
| **`dev`** | Integration testing, active validation, development builds. | Open (no required reviewers). | Automatic on push/merge to `main`. |
| **`staging`** | Pre-production validation, schema migration testing, regression suites. | Open or restricted by branch. | Manual dispatch or push to release candidate branches (`release/*`). |
| **`prod`** | User-facing production applications and public APIs. | Required reviewers (manual approval gate). | Semantic Version release tags (`vM.m.r`). |
| **`practice`** | Specialized simulation tier (e.g. Smoke Outlooks training). | Open for authorized team members. | Parameterized manual dispatch (`workflow_dispatch`). |

---

## 2. Setting Up the Development Environment (`dev`)

1. In your GitHub repository, open **Settings** > **Environments**.
2. Click **New environment**.
3. Name the environment `dev` (exact lowercase).
4. Click **Configure environment**.
5. Leave deployment protection rules unchecked.

---

## 3. Setting Up the Staging Environment (`staging`)

For repositories delivering public web portals (`fasm-v4`, `smoke-airnow-gov`) or high-throughput vector tiles (`tileserver-pwfsl`), configure a staging environment to run automated regression gates prior to production:

1. Under **Environments**, click **New environment**.
2. Name the environment `staging`.
3. Click **Configure environment**.
4. (Optional) Under **Deployment branches**, restrict deployment to `main` or release candidate branches (`release/*`).

---

## 4. Setting Up the Production Environment (`prod`) with Approval Gates

Production deployments require explicit manual authorization to ensure software quality and change awareness:

1. Under **Environments**, click **New environment**.
2. Name the environment `prod`.
3. Click **Configure environment**.
4. Under **Deployment protection rules**, select **Required reviewers**.
5. Add the designated team maintainers (e.g. group developers or administrators).
6. Under **Deployment branches**, restrict deployments to **Selected branches and tags**:
   - Add tag pattern: `v*` (ensures only SemVer tags can deploy to production).
7. Click **Save protection rules**.

---

## 5. Configuring Deployment Concurrency Locks

Deployments must never overlap or cancel mid-execution. In your CD workflow YAML, declare a concurrency lock on the environment name with `cancel-in-progress: false`:

```yaml
concurrency:
  group: cd-${{ github.workflow }}-${{ inputs.environment || (github.event_name == 'release' && 'prod') || (startsWith(github.ref, 'refs/tags/v') && 'prod') || 'dev' }}
  cancel-in-progress: false
```

Setting `cancel-in-progress: false` ensures that if two deployments trigger in close succession, the second deployment queues safely rather than aborting an in-flight rollout.

---

## 6. Next Steps

- Configure environment-scoped variables and credentials: [How to Manage Secrets and Variables](managing-secrets-and-variables.md)
- Configure keyless cloud access: [How to Configure AWS OIDC](configuring-aws-oidc.md)
