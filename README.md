# USFS AirFire CI/CD Style Guide and Examples

This repository serves as a style guide and educational resource for introducing developers on the USFS AirFire team to Continuous Integration and Continuous Deployment (CI/CD) using GitHub Actions.

It provides a progressive roadmap of workflows, moving from simple quality checks to multi-environment deployment pipelines and GitOps infrastructure automation.

---

## 1. Documentation Roadmap

For detailed explanations of the group's standards, conventions, architectural layouts, and setup guides, refer to the following documentation:
- [USFS AirFire CI/CD Style Guide](docs/cicd-style-guide.md): The core style guide detailing workflow logic, environment conventions, branching structures, OIDC configuration, and security rules.
- [Configuring AWS OIDC Federation](docs/aws-oidc-setup.md): A step-by-step setup guide for creating the OIDC Identity Provider in AWS IAM and configuring restricted Trust Policies for GitHub Action roles.
- [Configuring GitHub Environments](docs/github-environments-setup.md): A step-by-step setup guide for creating development and production environment gates in GitHub settings.
- [GitHub Secrets Scoping and Management Guide](docs/github-secrets-management.md): Detailed instructions on declaring global repository secrets and scoping environment secrets to development and production targets.

---

## 2. Directory Structure and Workflow Files

The progressive workflows are organized in sequence under the `.github/workflows/` directory:

| Sequence | Workflow File | Focus Areas | Key Actions and Concepts |
| :--- | :--- | :--- | :--- |
| **01 (Python)** | [01-basic-ci.yml](.github/workflows/01-basic-ci.yml) | Base Continuous Integration (Python) | Code checkout, Python environment setup, dependency caching, Ruff linting, Black formatting, Pytest unit testing, artifact upload. |
| **01 (NodeJS)** | [01-basic-ci-node.yml](.github/workflows/01-basic-ci-node.yml) | Base Continuous Integration (NodeJS) | Code checkout, Node.js environment setup, npm dependency caching, ESLint linting, Prettier formatting check, Jest unit testing, artifact upload. |
| **02 (Python)** | [02-environments-matrix.yml](.github/workflows/02-environments-matrix.yml) | Parameterization & Environments (Python) | Multi-version testing matrix, environmental target scoping (`dev` vs. `prod`), environmental secrets, and conditional execution. |
| **02 (NodeJS)** | [02-environments-matrix-node.yml](.github/workflows/02-environments-matrix-node.yml) | Parameterization & Environments (NodeJS) | Multi-version testing matrix, environmental target scoping (`dev` vs. `prod`), environmental secrets, and conditional execution. |
| **03 (Python)** | [03-aws-oidc.yml](.github/workflows/03-aws-oidc.yml) | Secure Cloud Deployment (Python) | AWS OpenID Connect (OIDC) keyless authentication, Docker image construction, ECR pushes, and comparative setup for Legacy (EC2/Fabric) and Modern (ECS/Fargate) deploys. |
| **03 (NodeJS)** | [03-aws-oidc-node.yml](.github/workflows/03-aws-oidc-node.yml) | Secure Cloud Deployment (NodeJS) | AWS OpenID Connect (OIDC) keyless authentication, Docker image construction, ECR pushes, and comparative setup for Legacy (EC2/SSH script) and Modern (ECS/Fargate) deploys. |
| **04** | [04-terraform-cicd.yml](.github/workflows/04-terraform-cicd.yml) | Infrastructure as Code | Terraform formatting, validation, planning, commenting plans on PRs, and auto-applying plans inside environment gates. |

---

## 3. Quick Reference: Branching and Triggers

Workflows conform to the following AirFire branch and tag triggers:

```
                  [ Pull Request targeting main/master ]
                                   │
                                   ▼
                      Runs Automated CI Checks
               (Linting, Testing, Terraform Validation)
                                   │
                                   ▼
                   [ Merge PR into main/master (Push) ]
                                   │
                                   ▼
                      Deploys to 'dev' Environment
                                   │
                                   ▼
                     [ Create Version Tag vM.m.r ]
                                   │
                                   ▼
                     Deploys to 'prod' Environment
              (Requires manual approval gate on GitHub)
```

---

## 4. Central Reusable Workflows (`@v1`)

AirFire repositories standardize their pull request quality gates by calling shared `workflow_call` templates published from this repository. Workflows are tagged under floating major version `@v1` for automatic stability and non-breaking tool updates.

### Available Reusable Workflows

| Reusable Workflow | Focus & Quality Gates | Key Inputs & Defaults |
| :--- | :--- | :--- |
| **`reusable-docs.yml`** | Diátaxis frontmatter, namespace `README.md` hubs, markdownlint | `docs_path: "docs"`, `validate_frontmatter: true`, `run_markdownlint: true` |
| **`reusable-python.yml`** | `uv` dependency sync, `ruff check`, `ruff format`, `pytest` | `python-version: "3.12"`, `run-ruff: true`, `run-tests: true`, `pytest-args: "-v"` |
| **`reusable-node.yml`** | `npm`/`pnpm` cache, ESLint, unit testing, build check | `node-version: "20"`, `package-manager: "npm"`, `run-lint: true`, `run-test: true`, `run-build: true` |
| **`reusable-terraform.yml`** | `terraform fmt`, `tflint`, `terraform validate` | `terraform-version: "1.9.0"`, `run-fmt: true`, `run-validate: true`, `run-tflint: true` |

### Consumer Repository Example

In contributing repositories, create `.github/workflows/ci.yml`:

```yaml
name: Continuous Integration

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  docs-quality-gates:
    name: Documentation
    uses: pnwairfire/airfire-cicd/.github/workflows/reusable-docs.yml@v1
    with:
      docs_path: "docs"

  python-ci:
    name: Python Pipeline
    uses: pnwairfire/airfire-cicd/.github/workflows/reusable-python.yml@v1
    with:
      python-version: "3.12"
```
