# CLAUDE.md Guidelines for USFS AirFire CI/CD

This repository contains Continuous Integration and Continuous Deployment (CI/CD) standards, documentation, and progressive GitHub Actions workflow examples for the USFS AirFire research group.

## Code Quality and Verification Commands
While this is a template and style guide repository rather than a runtime application, agents and developers should verify workflow syntax and document formatting using the following tools:

- **Lint and Validate GitHub Workflows**: Use [actionlint](https://github.com/rhysd/actionlint) to catch syntax errors or incorrect schema usage in `.github/workflows/`.
  ```bash
  actionlint
  ```
- **Format and Lint Markdown**: Use markdownlint to enforce formatting across the docs:
  ```bash
  markdownlint docs/ README.md
  ```
- **Verify Link Portability**: Ensure relative paths are used for all documentation references (enforced by the workspace `enforce-relative-paths` skill).

---

## Repository Style and Engineering Rules

### 1. Branching and Workflows
- **Target Branches**: Automated CI runs on pull requests targeting `main` (or `master` for legacy).
- **Environment Triggers**:
  - Pushes (merges) to `main` automatically deploy to the `dev` environment.
  - Release tags matching `vM.m.r` (e.g., `v1.0.2`) deploy to the `prod` environment (requires manual approval gate).
- **Commit Signing**: Developers must sign commits using GPG or SSH keys.

### 2. Environment Standards
- **Two-Environment Policy**: Standardize strictly on `dev` and `prod`. Do not add staging/test environments without explicit requirement approval.
- **Environment Scoping**: Scoped variables and environment secrets must be set up in GitHub settings for the `prod` environment to restrict access.

### 3. Security Requirements
- **Action Pinning**: Use major version tags (e.g., `@v4`) rather than commit SHAs to allow automatic patch updates.
- **AWS Authentication**: Never store static AWS Access Keys in GitHub. Use AWS OpenID Connect (OIDC) federation.
  - Ensure the workflow requests `id-token: write` and `contents: read` permissions.
- **Application Secrets**: Use AWS Secrets Manager for runtime secrets with:
  - Custom KMS keys (no default managed keys).
  - Explicit least-privilege policies.
  - Automatic rotation.
  - CloudTrail auditing.

### 4. Deployment Footprints
- **Legacy**: Standalone EC2 instances, Docker Compose, and Fabric SSH scripting.
- **Modern**: AWS ECS, Fargate serverless containers, and ALB routing (no Fabric/SSH required).
