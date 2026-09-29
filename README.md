# USFS AirFire CI/CD Style Guide and Examples

This repository serves as a style guide and educational resource for introducing developers on the USFS AirFire team to Continuous Integration and Continuous Deployment (CI/CD) using GitHub Actions.

It provides centralized reusable workflows (`@v1`) and copy-and-paste consumer caller templates for Python, Node.js, Terraform, and polyglot repositories across the organization.

---

## 1. Documentation Roadmap

For detailed explanations of the group's standards, conventions, architectural layouts, and setup guides, refer to the following documentation:
- [USFS AirFire CI/CD Style Guide](docs/cicd-style-guide.md): The core style guide detailing workflow logic, environment conventions, branching structures, OIDC configuration, and security rules.
- [Repository Migration Runbook](docs/how-to/migrating-a-repo-to-standard-ci.md): Step-by-step checklist for migrating repositories to standard CI/CD and the centralized knowledge base.
- [Reusable Workflows Reference](docs/reference/reusable-workflows-reference.md): Technical parameter specification for all central workflows.
- [Configuring AWS OIDC Federation](docs/aws-oidc-setup.md): A step-by-step setup guide for creating the OIDC Identity Provider in AWS IAM and configuring restricted Trust Policies for GitHub Action roles.
- [Configuring GitHub Environments](docs/github-environments-setup.md): A step-by-step setup guide for creating development and production environment gates in GitHub settings.
- [GitHub Secrets Scoping and Management Guide](docs/github-secrets-management.md): Detailed instructions on declaring global repository secrets and scoping environment secrets to development and production targets.

---

## 2. Consumer Caller Workflow Examples

To onboard a repository to AirFire CI/CD without writing bespoke pipelines from scratch, copy-and-paste caller templates are provided in the [`examples/`](examples/) directory:

| Archetype | Caller Template | Reusable Workflows Invoked | Focus & Key Gates |
| :--- | :--- | :--- | :--- |
| **Python** | [`consumer-python-ci.yml`](examples/consumer-python-ci.yml) | `reusable-docs.yml@v1`, `reusable-python.yml@v1` | Astral `uv` setup, Ruff lint/format checks, Pytest suite, Diátaxis frontmatter, and markdownlint. |
| **NodeJS** | [`consumer-node-ci.yml`](examples/consumer-node-ci.yml) | `reusable-docs.yml@v1`, `reusable-node.yml@v1` | Node.js runtime caching, ESLint, Jest unit testing, bundle build verification, and markdownlint. |
| **Terraform** | [`consumer-terraform-ci.yml`](examples/consumer-terraform-ci.yml) | `reusable-docs.yml@v1`, `reusable-terraform.yml@v1` | `terraform fmt`, `tflint` static analysis, `terraform validate`, and documentation checks. |
| **Polyglot** | [`consumer-polyglot-ci.yml`](examples/consumer-polyglot-ci.yml) | `reusable-docs.yml@v1`, `reusable-python.yml@v1`, `reusable-node.yml@v1` | Multi-language quality gates scoped by subdirectories (`backend` and `frontend`). |

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
