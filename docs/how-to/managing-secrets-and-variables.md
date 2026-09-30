---
title: "How to Manage Secrets and Variables in AirFire CI/CD"
description: "Step-by-step recipe for configuring GitHub Variables (vars.*), GitHub Secrets (secrets.*), and dynamic AWS Secrets Manager credential extraction."
published: true
editor: markdown
dateCreated: 2026-09-29T12:00:00.000Z
tags:
  - cicd
  - how-to
  - secrets
  - variables
  - security
---

# How to Manage Secrets and Variables in AirFire CI/CD

This guide provides instructions for managing configuration variables and sensitive credentials across GitHub Actions workflows and target cloud environments. Properly scoping values isolates development resources from production, prevents accidental credential exposure, and ensures compliance with federal security standards.

For group security standards, consult the [AirFire CI/CD Style Guide](../cicd-style-guide.md).

---

## 1. Differentiating Variables from Secrets

GitHub Actions provides two distinct configuration stores. Use the correct store based on data sensitivity:

| Store Type | Context Syntax | Use Cases | Sensitivity |
| :--- | :--- | :--- | :--- |
| **GitHub Variables** | `${{ vars.NAME }}` | IAM Role ARNs, AWS Regions, S3 Bucket Names, ECS Cluster/Service Names, Hostnames. | Public / Non-sensitive configuration metadata. |
| **GitHub Secrets** | `${{ secrets.NAME }}` | GitHub personal access tokens, external deployment keys, webhook URLs, third-party API keys. | Highly confidential credentials; masked in runner logs. |
| **AWS Secrets Manager** | *Fetched via CLI* | Database connection strings, API signing keys, backend application tokens. | Highly confidential runtime data; rotated centrally. |

---

## 2. Configuring GitHub Variables (`vars.*`)

Store non-sensitive configuration values in Variables so they can be viewed and edited without credential re-entry:

### Repository-Level Variables
For settings consistent across all environments (e.g. `AWS_REGION: us-west-2`):
1. In the repository, navigate to **Settings** > **Secrets and variables** > **Actions**.
2. Select the **Variables** tab.
3. Click **New repository variable**.
4. Enter the name (e.g. `AWS_REGION`) and value (`us-west-2`).
5. Click **Add variable**.

### Environment-Scoped Variables
For settings that vary per tier (e.g. `AWS_ROLE_TO_ASSUME` or `S3_BUCKET_NAME`):
1. Navigate to **Settings** > **Environments**.
2. Select the target environment (`dev`, `staging`, or `prod`).
3. Under **Environment variables**, click **Add variable**.
4. Set the variable name (e.g. `AWS_ROLE_TO_ASSUME`) and value (e.g. `arn:aws:iam::339712853872:role/github-actions-fasm-dev`).
5. Click **Save variable**.

---

## 3. Configuring GitHub Secrets (`secrets.*`)

Reserve GitHub Secrets exclusively for sensitive authentication credentials:

1. Navigate to **Settings** > **Environments** (for environment-scoped secrets) or **Secrets and variables** > **Actions** (for global repository secrets).
2. Click **New secret** (or **Add secret** under Environment secrets).
3. Provide the name in uppercase (e.g. `CLOUDFLARE_API_TOKEN`).
4. Paste the value. Once saved, GitHub will mask this value in all runner outputs.
5. Click **Add secret**.

---

## 4. Dynamic Credential Extraction from AWS Secrets Manager

To eliminate secret duplication and leverage centralized credential rotation, application runtime secrets (such as database credentials or API keys) should not be duplicated into GitHub Secrets.

Instead, workflows authenticate via keyless AWS OIDC and fetch required runtime secrets dynamically via the AWS CLI:

```yaml
steps:
  - name: Configure AWS Credentials (OIDC)
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ vars.AWS_ROLE_TO_ASSUME }}
      aws-region: ${{ vars.AWS_REGION || 'us-west-2' }}
      audience: sts.amazonaws.com

  - name: Fetch Application Secret
    env:
      ENV_NAME: ${{ inputs.environment || 'dev' }}
    run: |
      API_SECRET=$(aws secretsmanager get-secret-value \
        --secret-id "prefect-af/${ENV_NAME}/api-secret-key" \
        --query SecretString \
        --output text)
      # Mask the fetched secret so GitHub runner protects it
      echo "::add-mask::$API_SECRET"
      echo "PREFECT_API_KEY=$API_SECRET" >> $GITHUB_ENV
```

### Security Benefits
- **Zero Secret Drift**: Database passwords and API keys update in AWS Secrets Manager and apply on the next job execution.
- **Audit Logging**: Secret retrievals generate CloudTrail event records detailing exact IAM principal, timestamp, and client identity.
- **Least-Privilege Scoping**: Workflows only request access to their specific secret path prefix (e.g. `arn:aws:secretsmanager:us-west-2:<account>:secret:fasm/dev/*`).

---

## 5. Next Steps

- Set up deployment environments: [How to Configure GitHub Environments](configuring-github-environments.md)
- Configure AWS IAM OIDC federation: [How to Configure AWS OIDC](configuring-aws-oidc.md)
