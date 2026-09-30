---
title: "How to Configure AWS OIDC Federation for GitHub Actions"
description: "Step-by-step recipe for establishing secure, keyless AWS IAM OpenID Connect authentication for AirFire GitHub Actions workflows."
published: true
editor: markdown
dateCreated: 2026-09-29T12:00:00.000Z
tags:
  - cicd
  - how-to
  - aws
  - oidc
  - security
---

# How to Configure AWS OIDC Federation for GitHub Actions

This guide describes how to configure OpenID Connect (OIDC) identity federation in AWS IAM. Setting up OIDC eliminates static, long-lived AWS Access Keys (`AKIA...`) in favor of short-lived AWS STS credentials requested directly by GitHub Actions.

For architectural context on cloud security policies, consult the [AirFire CI/CD Style Guide](../cicd-style-guide.md).

---

## Prerequisites

- Administrative access to the AWS Management Console or IAM CLI for the target account (EPA `339712853872` or UW `545607068190`).
- Administrator or maintainer permissions on the target GitHub repository in `pnwairfire`.

---

## 1. Create the OIDC Identity Provider in IAM

This step is executed once per AWS account. If the provider already exists, proceed to Step 2.

1. Open the **AWS IAM Console** in `us-west-2`.
2. In the navigation pane, select **Identity providers**, then click **Add provider**.
3. Under **Provider type**, select **OpenID Connect**.
4. Set **Provider URL** to:
   ```text
   https://token.actions.githubusercontent.com
   ```
5. Click **Get thumbprint** to verify the GitHub CA thumbprint.
6. Set **Audience** to:
   ```text
   sts.amazonaws.com
   ```
7. Click **Add provider**.

---

## 2. Create the IAM Deployment Role

Maintain environment isolation by creating distinct IAM roles for development and production workflows:

1. In the IAM console, select **Roles**, then click **Create role**.
2. Select **Web identity** as the trusted entity type.
3. Select `token.actions.githubusercontent.com` as the **Identity provider**.
4. Select `sts.amazonaws.com` as the **Audience**.
5. Click **Next** to proceed to permissions.
6. Attach least-privilege permission policies required for the specific workload (e.g., ECR push, ECS service updates, or S3 bucket synchronization). Do not attach broad administrative policies.
7. Name the role following group conventions:
   - Development: `github-actions-<repo-name>-dev`
   - Production: `github-actions-<repo-name>-prod`
8. Click **Create role**.

---

## 3. Restrict the Role Trust Policy

To prevent unauthorized GitHub repositories or branches from assuming the role, restrict the trust relationship using GitHub subject (`sub`) claims.

1. Navigate to the created IAM role and open the **Trust relationships** tab.
2. Click **Edit trust policy** and update the policy document:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GitHubActionsOIDCAuthentication",
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
          "token.actions.githubusercontent.com:sub": "repo:pnwairfire/<REPOSITORY_NAME>:*"
        }
      }
    }
  ]
}
```

### Trust Scoping Patterns

Refine the `StringLike` or `StringEquals` condition to enforce least-privilege role assumption:

- **Branch-Restricted (Development Role)**:
  Permits role assumption strictly from pushes or pull requests targeting `main`:
  ```json
  "token.actions.githubusercontent.com:sub": "repo:pnwairfire/<REPO_NAME>:ref:refs/heads/main"
  ```
- **Environment-Restricted (Production Role - Recommended)**:
  Restricts role assumption to workflow jobs running inside the protected `prod` GitHub Environment (which requires human approval):
  ```json
  "token.actions.githubusercontent.com:sub": "repo:pnwairfire/<REPO_NAME>:environment:prod"
  ```
- **Tag-Restricted (Release Builds)**:
  Restricts role assumption to versioned Semantic Version tags:
  ```json
  "token.actions.githubusercontent.com:sub": "repo:pnwairfire/<REPO_NAME>:ref:refs/tags/v*"
  ```

---

## 4. Configure GitHub Repository Variables

Because AWS Role ARNs are non-sensitive configuration metadata rather than secret credentials, store them in GitHub Environment Variables (`vars.*`):

1. In your GitHub repository, navigate to **Settings** > **Environments**.
2. Select the target environment (`dev` or `prod`).
3. Under **Environment variables**, click **Add variable**.
4. Set the name to `AWS_ROLE_TO_ASSUME` (or `AWS_ROLE_ARN`).
5. Set the value to the IAM Role ARN (e.g. `arn:aws:iam::339712853872:role/github-actions-fasm-dev`).
6. For step-by-step instructions on secret and variable management, see [How to Manage Secrets and Variables](managing-secrets-and-variables.md).

---

## 5. Verification

Verify the OIDC configuration by adding the authentication step to a workflow:

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - name: Configure AWS Credentials (OIDC)
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ vars.AWS_ROLE_TO_ASSUME }}
      aws-region: us-west-2
      audience: sts.amazonaws.com

  - name: Verify Identity
    run: aws sts get-caller-identity
```

Trigger the workflow and confirm the step outputs the assumed IAM role identity.
