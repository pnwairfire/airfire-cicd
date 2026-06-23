# Managing and Scoping GitHub Secrets for USFS AirFire

This document provides instructions for adding and scoping secrets within GitHub Actions. Properly configuring secrets prevents sensitive data leaks and ensures that development and production parameters remain isolated.

---

## 1. Secrets Overview

GitHub Actions supports two types of secrets:
- **Repository Secrets**: Shared across all jobs in the repository regardless of the target environment.
- **Environment Secrets**: Scoped strictly to a specific GitHub Environment (e.g., `dev` or `prod`). A workflow job can only access these secrets if it explicitly declares the corresponding environment.

For further architectural context, refer to the [USFS AirFire CI/CD Style Guide](cicd-style-guide.md).

---

## 2. Differentiating Scopes

| Secret Name | Scoping Level | Purpose |
| :--- | :--- | :--- |
| `AWS_ROLE_ARN` | Environment-scoped (`dev` and `prod`) | Represents the separate IAM Roles to assume for development and production AWS resources. |
| `DEPLOY_TARGET_API_KEY` | Environment-scoped (`dev` and `prod`) | Target-specific API tokens. |
| `DEPLOY_HOST` | Environment-scoped variables | Host addresses or IP ranges for target environments. |
| `GLOBAL_METRICS_KEY` | Repository-wide | Keys that are identical across all workflows (e.g., global third-party alerting integrations). |

---

## 3. Adding Repository Secrets

Use Repository Secrets for parameters that do not change between development and production environments.

1. Navigate to the repository home page on GitHub.
2. Click on the **Settings** tab.
3. In the left sidebar, click on **Secrets and variables** > **Actions**.
4. Under the **Secrets** tab, click **New repository secret**.
5. Enter a clear, uppercase name (e.g., `GLOBAL_METRICS_KEY`).
6. Paste the secret value into the text area.
7. Click **Add secret**.

---

## 4. Adding Environment-Scoped Secrets

Use Environment Secrets to isolate development variables from production variables. This ensures that a bug or a compromise in a development pipeline cannot expose production resources.

1. Navigate to **Settings** > **Environments** on GitHub.
2. Click on the name of the target environment (e.g., `dev` or `prod`).
3. Scroll down to the **Environment secrets** section.
4. Click **Add secret**.
5. Enter the secret name (e.g., `AWS_ROLE_ARN`).
6. Paste the value representing that specific environment's resource.
7. Click **Add secret**.
8. Repeat these steps for the other environment to configure the corresponding value.

---

## 5. Security Restrictions

- **Do Not Store Static AWS Credentials**: Never add `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` to GitHub. Use AWS OIDC identity federation instead, as detailed in the style guide.
- **Limit Access Permissions**: GitHub Environment secrets are protected by the environment's approval gates. If a job requires a secret from the `prod` environment, the deployment approval gate must be cleared before the job runs and accesses the secret.
- **Environment Variables**: For non-sensitive configurations that change between environments (e.g., domain names, host URLs, port configurations), use **Environment Variables** (located below the Secrets section on the environment configuration page) instead of Secrets.
