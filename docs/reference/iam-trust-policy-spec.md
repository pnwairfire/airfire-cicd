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
          "token.actions.githubusercontent.com:sub": "repo:pnwairfire/<REPO_NAME>:environment:prod"
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
          "token.actions.githubusercontent.com:sub": "repo:pnwairfire/<REPO_NAME>:ref:refs/heads/main"
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
          "token.actions.githubusercontent.com:sub": "repo:pnwairfire/<REPO_NAME>:ref:refs/tags/v*"
        }
      }
    }
  ]
}
```

---

## 3. Security Invariants

- **Wildcard Scoping**: Never configure `"repo:pnwairfire/*"` without branch, environment, or tag restrictions. Overly broad wildcards permit pull requests from any repository in the organization to assume privileged cloud roles.
- **Audience Verification**: Always include `"token.actions.githubusercontent.com:aud": "sts.amazonaws.com"`. Omitting audience validation allows tokens minted for other services to be presented to STS.
