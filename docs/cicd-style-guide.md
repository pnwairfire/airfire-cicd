# USFS AirFire CI/CD Style Guide and Reference Manual

This document establishes the official Continuous Integration and Continuous Deployment (CI/CD) standards, conventions, and implementation patterns for the United States Forest Service (USFS) AirFire research group. It serves as a teaching instrument and style guide for onboarding developers and ensuring security, consistency, and reliability across all applications.

---

## 0. Introduction to CI/CD: The Problem and the Solution

### The Integration and Deployment Problem
In traditional software development, integrating code from multiple developers is an infrequent, manual, and error-prone process. Developers work in isolation for long periods, leading to significant merge conflicts (often referred to as integration hell) when combining changes. Manual testing is time-consuming and inconsistent, allowing bugs to reach production. Furthermore, manually packaging and deploying software to servers relies on custom developer machine configurations, creating deployment discrepancies, security vulnerabilities, and unpredictable downtime.

### The CI/CD Solution
Continuous Integration (CI) and Continuous Deployment (CD) solve these problems by automating the build, test, and release cycles:
- **Continuous Integration (CI)** addresses the integration problem. Developers merge their code changes back to the primary branch frequently. Every merge triggers an automated pipeline that builds the application, runs syntax checkers (linting/formatting), and executes unit test suites. This provides rapid feedback and prevents code regression.
- **Continuous Deployment (CD)** addresses the deployment problem. Once code passes all CI checks, the CD pipeline automatically packages the application and deploys it to the target environments (e.g., development or production) without manual intervention. This ensures deployments are consistent, repeatable, and independent of individual developer setups.

---

## 1. Branching Strategy and Git Workflow

### Branching Conventions
- The primary development branch is `main` (or `master` for legacy repositories).
- All direct pushes to primary branches are restricted. *This would be a new policy rolled out after team discussions and agreement.*
- Changes must be introduced via Pull Requests (PRs) from feature branches.

### Pull Requests and Code Review
- CI checks run automatically on every pull request targeting `main` or `master`.
- Formal code reviews are encouraged to maintain code quality, but not programmatically enforced for all repositories. 
- Assignees may review and merge their own pull requests once all automated CI checks pass.

### Commit Signing
- Developers are encouraged to sign all commits using GPG or SSH keys.
- Signed commits guarantee that the code originates from a verified author, protecting the group's software supply chain from unauthorized modifications.
- To configure Git to sign commits by default, use the following commands:
  ```bash
  git config --global commit.gpgsign true
  git config --global user.signingkey <YOUR_KEY_ID>
  ```

---

## 2. Environments and Deployment Strategy

AirFire applications target two primary environments, which must be named exactly as follows:

| Environment | Purpose | Access Control | Deployment Trigger |
| :--- | :--- | :--- | :--- |
| `dev` | Active testing, integration, and development verification. | Open access for team members. | Automatic on code merge (push) to `main` or `master`. |
| `prod` | User-facing production applications. | Restricted access. Requires manual approval gates. *Pending team review.* | Automatic on versioned release tags matching the format `vM.m.r`. |

### Versioned Tag Format (vM.m.r)
Production releases must follow [Semantic Versioning (SemVer) standards](https://semver.org/) and be tagged with the prefix `v` followed by major, minor, and patch numbers separated by periods (e.g., `v1.2.4`, `v0.8.0`).

### Environment Gates in GitHub
To prevent unauthorized deployments to `prod`, repositories must configure a GitHub Environment named `prod` (see [Configuring GitHub Environments](github-environments-setup.md)) with:
1. **Required Reviewers**: Specify at least one administrator or senior developer to manually approve the deployment.
2. **Environment Secrets**: Keep production-specific keys separate from development keys.

### Environment Count and Terminology Standards

#### Two-Environment Policy
For small development teams, maintaining more than two persistent environments (e.g., `dev`, `test`, `staging`, `prod`) introduces significant infrastructure management overhead, increased cloud costs, and pipeline complexity. Therefore, AirFire standardizes on a lean two-environment model (`dev` and `prod`). A third persistent test or staging environment is discouraged unless required by specific external compliance constraints.

---

## 3. Security Best Practices for CI/CD

<!-- ### Pinning Action Versions
To guard against third-party dependency compromises (supply-chain attacks), all GitHub Actions workflows in AirFire repositories must use full 40-character commit SHAs instead of mutable tags like `@v4` or `@latest`. A comment indicating the human-readable version must be appended.

*Incorrect:*
```yaml
uses: actions/checkout@v4
```

*Correct:*
```yaml
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
``` -->

### AWS OpenID Connect (OIDC) Authentication
AirFire pipelines do not store long-lived, high-risk AWS Access Keys (`AKIA...`) or Secret Keys in GitHub. Instead, they use OpenID Connect (OIDC) to request short-term, auto-expiring credentials from AWS Security Token Service (STS). Detailed instructions for configuring AWS OIDC are available in the [AWS OIDC Identity Provider and IAM Role Setup Guide](aws-oidc-setup.md).

Note that GitHub Secrets are still utilized to store non-credential configuration metadata, such as the AWS Role ARN (`AWS_ROLE_ARN`) or reference identifiers. OIDC replaces only the need to store long-lived static credentials, while preserving the use of GitHub Secrets for variables that require confidentiality.

- Workflows must declare the `permissions` block explicitly to request the OIDC JWT token:
  ```yaml
  permissions:
    id-token: write
    contents: read
  ```
- Use the official configuration action to assume the designated IAM role:
  ```yaml
  - name: Configure AWS Credentials
    uses: aws-actions/configure-aws-credentials@e3dd8a4bbb33cb94027a195350c4c2be23d8c138 # v4.0.2
    with:
      role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
      aws-region: us-west-2
  ```

### Secrets Management Best Practices
- **Never commit secrets**: No API keys, passwords, or private keys may ever be added to repository files.
- **GitHub Secrets**: Store sensitive values in GitHub Secrets scoped to the appropriate Environment (`dev` or `prod`). Refer to the [GitHub Secrets Scoping and Management Guide](github-secrets-management.md) for detailed configuration steps.
- **AWS Secrets Manager**: For application-level secrets (databases, API integrations), utilize AWS Secrets Manager. Always configure:
  1. Dedicated KMS encryption keys instead of default AWS managed keys.
  2. Least-privilege IAM policies permitting access only to specific application roles.
  3. Automatic secret rotation policies.
  4. CloudTrail auditing to log secret retrieval events.

---

## 4. Architectural Deployment Footprints

The USFS AirFire team maintains two deployment architectures depending on project lifecycle:

### Legacy Footprint (EC2 + Docker Compose + Fabric)
For older applications, compute is hosted on standalone EC2 instances.
- **Docker Compose** defines and runs the services locally on the server.
- **Fabric** (Python SSH scripting tool) is invoked by the CI/CD runner. Fabric connects to the target EC2 instances over SSH, pulls the updated container image from ECR, and restarts the containers with zero downtime.
- **Prefect** and **AWS CloudWatch** monitor running services and send alerts if any failures occur.

### Modern Footprint (AWS ECS + Fargate)
For new applications, compute is serverless and managed natively by AWS.
- **AWS ECS** manages container execution.
- **Fargate** runs the containers without requiring EC2 management.
- **Application Load Balancers (ALBs)** handle dynamic routing and traffic shifting.
- Deployment is executed natively by the CI/CD runner using the AWS CLI and ECS API to register a new Task Definition and update the Service. This eliminates SSH access, keys, and manual scripting.

---

## 5. Overview of Progressive Example Workflows

The repository contains four progressive workflows located under the `.github/workflows/` directory:

1. **Level 1: Basic Continuous Integration**
   - File Path: [01-basic-ci.yml](../.github/workflows/01-basic-ci.yml)
   - Scope: Checks code linting and formatting (Ruff, Black) and runs automated test suites on pull requests.
   - Purpose: Establishes base quality gates before merging.

2. **Level 2: Matrix Builds and Environments**
   - File Path: [02-environments-matrix.yml](../.github/workflows/02-environments-matrix.yml)
   - Scope: Introduces Python runtime testing matrices and separates deployment jobs for `dev` and `prod` environments based on branch pushes and versioned tags.
   - Purpose: Demonstrates environmental routing and parameterization.

3. **Level 3: Secure AWS Deployment**
   - File Path: [03-aws-oidc.yml](../.github/workflows/03-aws-oidc.yml)
   - Scope: Adds AWS OIDC configuration and container image builds. Illustrates deployment setups for both the legacy (EC2/Fabric) and modern (ECS/Fargate) execution footprints.
   - Purpose: Teaches secure cloud authentication and Docker deployment patterns.

4. **Level 4: Infrastructure as Code (IaC) GitOps**
   - File Path: [04-terraform-cicd.yml](../.github/workflows/04-terraform-cicd.yml)
   - Scope: Implements validation and planning for Terraform code. Automates posting the planned changes back to pull requests as comments and auto-applies configurations on merge.
   - Purpose: Integrates cloud resource provisioning into the software delivery pipeline.
