# Configuring GitHub Environments for USFS AirFire

This document provides step-by-step instructions for repository administrators to configure GitHub Environments. Standardizing environments ensures consistent pipeline targets and prevents unauthorized deployments to production.

---

## 1. Overview of Environments

AirFire repositories use two primary environments:
- `dev`: Dedicated for integration, active testing, and development validation. Access is open.
- `prod`: Dedicated for stable, user-facing releases. Access is protected by manual approval gates.

For detailed guidelines on environmental architecture, refer to the [USFS AirFire CI/CD Style Guide](cicd-style-guide.md).

---

## 2. Setting Up the dev Environment

1. Navigate to the repository home page on GitHub.
2. Click on the **Settings** tab at the top of the repository interface.
3. In the left sidebar, locate the **Security** section and click on **Environments**.
4. Click the **New environment** button.
5. In the **Name** field, enter `dev` (all lowercase, exactly matching workflow declarations).
6. Click **Configure environment**.
7. Keep default settings (no deployment protection rules are required for the development environment).

---

## 3. Setting Up the prod Environment and Approval Gates

To protect the production environment, you must configure deployment protection rules. This prevents any workflow from applying production deployments without authorization.

1. Go back to the **Environments** page (**Settings** > **Environments**).
2. Click the **New environment** button.
3. In the **Name** field, enter `prod` (all lowercase).
4. Click **Configure environment**.
5. Under **Deployment protection rules**, check the box for **Required reviewers**.
6. In the search box, enter the GitHub usernames of the designated repository administrators or senior developers authorized to approve production releases. You can add up to 6 reviewers.
7. (Optional) Set the **Deployment wait timer** if you want to enforce a delay before the deployment proceeds.
8. Click **Save protection rules**.

---

## 4. Troubleshooting Environment Configuration

- **Environment Name Mismatch**: If a workflow fails with an error stating the environment cannot be resolved, check that the environment name in the workflow YAML matches the environment name in GitHub settings exactly (e.g., `dev` vs. `DEV`).
- **Required Reviewers Grayed Out**: Required reviewers are a feature of GitHub Enterprise or public repositories. If you are working in a private repository under a standard GitHub plan, this feature may require upgrading the repository's subscription or team plan.
