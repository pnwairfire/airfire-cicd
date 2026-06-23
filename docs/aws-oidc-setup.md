# Configuring AWS OpenID Connect (OIDC) Federation for GitHub Actions

This document outlines the steps required on the AWS side to establish a secure, keyless trust relationship with GitHub Actions. Setting up OIDC eliminates the need to store static AWS Access Keys in GitHub.

---

## 1. Create the OIDC Identity Provider in IAM

You only need to perform this step once per AWS Account.

1. Log in to the **AWS Management Console** and navigate to the **IAM console**.
2. In the left navigation pane, click on **Identity providers**, then click **Add provider**.
3. Under **Provider type**, select **OpenID Connect**.
4. For **Provider URL**, enter exactly:
   `https://token.actions.githubusercontent.com`
5. Click the **Get thumbprint** button to verify the certificate authority thumbprint.
6. For **Audience**, enter exactly:
   `sts.amazonaws.com`
7. Click **Add provider**.

---

## 2. Create the IAM Role for GitHub Actions

Create separate IAM roles for the `dev` and `prod` workflows to maintain environment isolation.

1. In the IAM console, click on **Roles** in the left navigation pane, then click **Create role**.
2. Under **Trusted entity type**, select **Web identity**.
3. Under **Identity provider**, select `token.actions.githubusercontent.com`.
4. Under **Audience**, select `sts.amazonaws.com`.
5. Click **Next**.
6. Assign the minimum required permission policies for the role (e.g., ECR push permissions, ECS deployment permissions, or S3 bucket access). *Do not grant administrator access.*
7. Click **Next**.
8. Name the role clearly (e.g., `github-actions-airfire-dev` or `github-actions-airfire-prod`).
9. Click **Create role**.

---

## 3. Configure the Role Trust Policy

To prevent unauthorized repositories or branches from assuming the IAM role, you must restrict the Trust Policy.

1. Locate the newly created IAM role in the console and click on the **Trust relationships** tab, then click **Edit trust policy**.
2. Replace the JSON statement with the following template. Customize the account ID, organization/user name, repository name, and trigger filters.

### Trust Policy Template

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
          "token.actions.githubusercontent.com:sub": "repo:<ORGANIZATION_OR_USER>/<REPOSITORY_NAME>:*"
        }
      }
    }
  ]
}
```

### Trust Scoping Options
To enforce security boundaries, modify the `token.actions.githubusercontent.com:sub` claim condition:

- **Restrict by Branch (recommended for dev role)**:
  Restrict role assumption strictly to pushes or pull requests on the `main` or `master` branches:
  ```json
  "token.actions.githubusercontent.com:sub": "repo:pnwairfire/airfire-cicd:ref:refs/heads/main"
  ```
- **Restrict by Environment (recommended for prod role)**:
  Restrict role assumption to jobs targeting the `prod` GitHub Environment (which has manual approval gates):
  ```json
  "token.actions.githubusercontent.com:sub": "repo:pnwairfire/airfire-cicd:environment:prod"
  ```
- **Restrict by Versioned Tags**:
  Restrict role assumption to version tags starting with `v`:
  ```json
  "token.actions.githubusercontent.com:sub": "repo:pnwairfire/airfire-cicd:ref:refs/tags/v*"
  ```

---

## 4. Verification

Once the IAM Role is created and the Trust Policy is restricted:
1. Copy the Role ARN (e.g., `arn:aws:iam::<ACCOUNT_ID>:role/github-actions-airfire-dev`).
2. Add this ARN as an environment-scoped GitHub Secret named `AWS_ROLE_ARN` in your repository.
3. Trigger the workflow to verify that the `Configure AWS Credentials` step succeeds without credentials.
