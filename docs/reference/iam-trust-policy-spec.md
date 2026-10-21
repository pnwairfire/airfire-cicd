---
title: "AWS IAM OIDC Trust Policy Specification"
description: "Technical reference and JSON policy templates for configuring AWS IAM OpenID Connect trust relationships for AirFire GitHub Actions."
published: true
editor: markdown
dateCreated: 2026-09-29T12:00:00.000Z
tags:
  - cicd
  - reference
  - aws
  - iam
  - oidc
---

# AWS IAM OIDC Trust Policy Specification

This document provides exact JSON trust policy specifications for establishing keyless authentication between GitHub Actions and AWS Security Token Service (STS) across EPA (`339712853872`) and UW (`545607068190`) AWS accounts.

For step-by-step setup instructions, consult [How to Configure AWS OIDC](../how-to/configuring-aws-oidc.md).

---

## 1. Specification Overview

When a GitHub Actions runner requests credentials via `aws-actions/configure-aws-credentials`, AWS STS validates the JSON Web Token (JWT) issued by GitHub against the IAM Role's Trust Policy.

### Required Fixed Claims

| Claim Key | Expected Value | Purpose |
| :--- | :--- | :--- |
| `Principal.Federated` | `arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com` | Declares GitHub Actions as the trusted identity provider. |
| `Action` | `sts:AssumeRoleWithWebIdentity` | Grants permission to exchange a Web Identity JWT for STS credentials. |
| `token.actions.githubusercontent.com:aud` | `sts.amazonaws.com` | Ensures the token was minted specifically for AWS authentication. |

### GitHub Immutable OIDC Subject Claim Enforcement

Effective July 15, 2026, GitHub enforces immutable subject claims (`use_immutable_subject: true`) across GitHub Actions OpenID Connect tokens to mitigate repository rename and account takeover (`repo-jacking`) attacks.

When `use_immutable_subject: true` is active, GitHub appends the immutable numeric Organization ID (`@11236785` for `pnwairfire`) and numeric Repository ID (`@<REPO_ID>`) directly into `token.actions.githubusercontent.com:sub`:

- **Immutable Subject Format (Standard)**: `repo:pnwairfire@11236785/<REPO_NAME>@<REPO_ID>:<context>`
- **Legacy Subject Format (Deprecated)**: `repo:pnwairfire/<REPO_NAME>:<context>`

> [!IMPORTANT]
> During migration, Terraform IAM trust policies may include both the immutable subject and the legacy subject in a `StringLike` array to maintain backward compatibility before and after `use_immutable_subject: true` is enabled on the repository. New roles and post-migration configurations should enforce the immutable subject format.

---

## 2. Standard Trust Policy Templates

### Pattern A: Environment-Scoped (Production Role - Recommended)

Restricts role assumption strictly to workflows executing inside the protected `prod` GitHub Environment (which enforces required reviewers):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GitHubActionsOIDCProdEnvironment",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:pnwairfire@11236785/<REPO_NAME>@<REPO_ID>:environment:prod"
        }
      }
    }
  ]
}
```

---

### Pattern B: Branch-Scoped (Development Role)

Restricts role assumption to pushes, merges, or pull requests targeting the `main` branch:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GitHubActionsOIDCDevBranch",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:pnwairfire@11236785/<REPO_NAME>@<REPO_ID>:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

---

### Pattern C: Tag-Scoped (Release Role)

Restricts role assumption to builds triggered by versioned Semantic Version tags:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GitHubActionsOIDCTags",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:pnwairfire@11236785/<REPO_NAME>@<REPO_ID>:ref:refs/tags/v*"
        }
      }
    }
  ]
}
```

---

## 3. Organization & Repository ID Reference (`pnwairfire` `@11236785`)

All `pnwairfire` repositories share the immutable GitHub Organization ID `11236785`. Use the table below to populate `<REPO_NAME>@<REPO_ID>` in IAM trust policies:

| Repository (`pnwairfire/<repo>`) | Numeric Repo ID | AWS Account | Immutable Subject Prefix (`sub_claim_prefix`) |
| :--- | :--- | :--- | :--- |
| `airfire-auth` | `1326940573` | EPA (`339712853872`) | `repo:pnwairfire@11236785/airfire-auth@1326940573` |
| `airfire-cicd` | `1277308994` | UW (`545607068190`) | `repo:pnwairfire@11236785/airfire-cicd@1277308994` |
| `airfire-observability` | `1393813150` | UW / EPA | `repo:pnwairfire@11236785/airfire-observability@1393813150` |
| `airfire-shared-ui` | `1184619821` | EPA (`339712853872`) | `repo:pnwairfire@11236785/airfire-shared-ui@1184619821` |
| `cmap-stack` | `1263170154` | UW (`545607068190`) | `repo:pnwairfire@11236785/cmap-stack@1263170154` |
| `elwood-pipeline` | `1295957651` | UW (`545607068190`) | `repo:pnwairfire@11236785/elwood-pipeline@1295957651` |
| `fasm-historical-service` | `1210101005` | UW (`545607068190`) | `repo:pnwairfire@11236785/fasm-historical-service@1210101005` |
| `fasm-pipeline` | `1292764358` | UW (`545607068190`) | `repo:pnwairfire@11236785/fasm-pipeline@1292764358` |
| `fasm-v4` | `579201684` | EPA (`339712853872`) | `repo:pnwairfire@11236785/fasm-v4@579201684` |
| `inciweb-pipeline` | `1296020599` | UW (`545607068190`) | `repo:pnwairfire@11236785/inciweb-pipeline@1296020599` |
| `knowledge-base` | `1365025430` | UW (`545607068190`) | `repo:pnwairfire@11236785/knowledge-base@1365025430` |
| `monitoring-v5` | `1310207779` | UW (`545607068190`) | `repo:pnwairfire@11236785/monitoring-v5@1310207779` |
| `outlook-pdf` | `1019676471` | UW (`545607068190`) | `repo:pnwairfire@11236785/outlook-pdf@1019676471` |
| `outlook-viewer-v2` | `1280566862` | UW (`545607068190`) | `repo:pnwairfire@11236785/outlook-viewer-v2@1280566862` |
| `prefect-af-managed` | `1279653924` | UW (`545607068190`) | `repo:pnwairfire@11236785/prefect-af-managed@1279653924` |
| `prefect-af-mock` | `1276512755` | UW (`545607068190`) | `repo:pnwairfire@11236785/prefect-af-mock@1276512755` |
| `smoke-airnow-gov` | `1267726073` | EPA (`339712853872`) | `repo:pnwairfire@11236785/smoke-airnow-gov@1267726073` |
| `tileserver-pwfsl` | `561554527` | EPA (`339712853872`) | `repo:pnwairfire@11236785/tileserver-pwfsl@561554527` |
| `weatherlayers-pwfsl` | `1149482117` | UW (`545607068190`) | `repo:pnwairfire@11236785/weatherlayers-pwfsl@1149482117` |
| `wiki-infra` | `1364986112` | UW (`545607068190`) | `repo:pnwairfire@11236785/wiki-infra@1364986112` |

### Inspecting and Enabling Immutable Subject Claims via GitHub CLI

Use the GitHub CLI (`gh api`) to query numeric IDs, inspect current OIDC subject settings, and opt into immutable subject claims:

```bash
# 1. Query numeric repository ID
gh api repos/pnwairfire/<repo> --jq '.id'

# 2. Inspect current OIDC subject claim configuration
gh api repos/pnwairfire/<repo>/actions/oidc/customization/sub

# 3. Enable immutable OIDC subject claims (after updating AWS IAM trust policies)
gh api -X PUT repos/pnwairfire/<repo>/actions/oidc/customization/sub \
  -F use_default=true \
  -F use_immutable_subject=true
```

---

## 4. Security Invariants

- **Wildcard Scoping**: Never configure `"repo:pnwairfire@11236785/*"` or `"repo:pnwairfire/*"` without repository, branch, environment, or tag restrictions. Overly broad wildcards permit pull requests from any repository in the organization to assume privileged cloud roles.
- **Audience Verification**: Always include `"token.actions.githubusercontent.com:aud": "sts.amazonaws.com"`. Omitting audience validation allows tokens minted for other services to be presented to STS.
- **Immutable Subject Enforcement**: Always update the AWS IAM role trust policy to accept `repo:pnwairfire@11236785/<REPO_NAME>@<REPO_ID>:...` *before* enabling `use_immutable_subject: true` on the GitHub repository.
