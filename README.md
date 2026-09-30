# USFS AirFire Central CI/CD Action Hub

This repository serves as the centralized Continuous Integration (CI) action hub and authoritative engineering policy library for the United States Forest Service (USFS) Pacific Northwest Research Station AirFire team.

It publishes centralized reusable GitHub Actions workflows (`@v1`) and copy-and-paste consumer caller templates for Python, Node.js, Terraform, and Polyglot repositories across the organization.

---

## 1. Central Reusable Workflows (`@v1`)

AirFire repositories standardize their pull request and merge quality gates by calling shared `workflow_call` templates published from this repository. Workflows are pinned under the floating major tag `@v1` to automatically receive non-breaking tool updates, security patches, and performance optimizations.

| Workflow File | Focus & Key Quality Gates | Reference Documentation |
| :--- | :--- | :--- |
| **`reusable-docs.yml`** | Diátaxis frontmatter validation, Wiki.js namespace hubs, markdownlint | [docs reference](docs/reference/reusable-workflows-reference.md#1-reusable-docsyml) |
| **`reusable-python.yml`** | Astral `uv` dependency caching, `ruff check`, `ruff format`, `pytest` | [python reference](docs/reference/reusable-workflows-reference.md#2-reusable-pythonyml) |
| **`reusable-node.yml`** | Node.js 20/22 runtime caching (`npm`/`pnpm`), ESLint, tests, build checks | [node reference](docs/reference/reusable-workflows-reference.md#3-reusable-nodeyml) |
| **`reusable-terraform.yml`** | `terraform fmt -check`, `tflint` static analysis, `terraform validate` | [terraform reference](docs/reference/reusable-workflows-reference.md#4-reusable-terraformyml) |

---

## 2. Consumer Caller Archetypes

To onboard a repository without writing bespoke CI scripts from scratch, copy-and-paste caller templates are maintained in [`examples/`](examples/):

| Archetype | Caller Template | Called Workflows | Target Use Cases |
| :--- | :--- | :--- | :--- |
| **Python** | [`consumer-python-ci.yml`](examples/consumer-python-ci.yml) | `reusable-docs`, `reusable-python` | Python CLI tools, ETL pipelines, and Prefect flow repositories. |
| **Node.js** | [`consumer-node-ci.yml`](examples/consumer-node-ci.yml) | `reusable-docs`, `reusable-node` | Svelte SPAs, web maps (`fasm-v4`), and TypeScript libraries. |
| **Terraform** | [`consumer-terraform-ci.yml`](examples/consumer-terraform-ci.yml) | `reusable-docs`, `reusable-terraform` | Cloud infrastructure and Terraform module repositories. |
| **Polyglot** | [`consumer-polyglot-ci.yml`](examples/consumer-polyglot-ci.yml) | `reusable-docs`, `reusable-python`, `reusable-node` | Full-stack monorepos managing both backend APIs and web interfaces. |

For detailed mapping instructions, consult the [Consumer Caller Archetypes Catalog](docs/reference/consumer-archetypes-catalog.md).

---

## 3. Quick-Start Example

In your repository, create `.github/workflows/ci.yml`:

```yaml
name: Continuous Integration & Quality Gates

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  docs-ci:
    name: Documentation Quality Gates
    uses: pnwairfire/airfire-cicd/.github/workflows/reusable-docs.yml@v1
    with:
      docs_path: "docs"

  python-ci:
    name: Python Quality Gates
    uses: pnwairfire/airfire-cicd/.github/workflows/reusable-python.yml@v1
    with:
      python-version: "3.12"
      run-ruff: true
      run-tests: true
```

Before committing, verify all quality gates pass locally:
```bash
run-local-ci
```

---

## 4. Local Verification Utility (`run-local-ci`)

To verify repository quality gates before pushing to GitHub (catching issues locally instead of triggering failures on Actions runners and alerts in `#fasm-alerts`), install the `run-local-ci` workstation utility:

```bash
curl -fsSL https://raw.githubusercontent.com/pnwairfire/airfire-cicd/v1/scripts/run-local-ci -o ~/.local/bin/run-local-ci
chmod +x ~/.local/bin/run-local-ci
```

From any repository root, run:

```bash
# Execute local quality checks
run-local-ci

# Auto-fix formatting and linting errors
run-local-ci --fix
```

For full options and configuration details, see [How to Install and Use run-local-ci](docs/how-to/installing-and-using-run-local-ci.md).

---

## 5. Documentation Suite (Diátaxis Framework)

Complete technical documentation is maintained under [`docs/`](docs/) according to the **Diátaxis Documentation Framework**:

### Explanation (Understanding)
- **[USFS AirFire CI/CD Style Guide](docs/cicd-style-guide.md)**: The authoritative engineering policy, operational team realities, environment tiers, and security conventions.
- **[Central Reusable Hub Architecture](docs/explanation/hub-and-spoke-architecture.md)**: Rationale for centralized reusable workflows and floating major tag governance.
- **[Decoupled Documentation Plane](docs/explanation/decoupled-documentation-plane.md)**: Zero-deploy-key architecture for aggregating documentation into `pnwairfire/knowledge-base`.

### How-To Guides (Problem-Solving)
- **[How to Migrate a Repository to Standard CI](docs/how-to/migrating-a-repo-to-standard-ci.md)**: 4-step checklist to onboard any repository to `@v1`.
- **[How to Configure AWS OIDC Federation](docs/how-to/configuring-aws-oidc.md)**: Setting up keyless AWS IAM OpenID Connect authentication.
- **[How to Configure GitHub Environments](docs/how-to/configuring-github-environments.md)**: Setting up `dev`, `staging`, `prod` gates and concurrency locks.
- **[How to Manage Secrets and Variables](docs/how-to/managing-secrets-and-variables.md)**: Separating `vars.*` from `secrets.*` and dynamic AWS Secrets Manager access.
- **[How to Install and Use run-local-ci](docs/how-to/installing-and-using-run-local-ci.md)**: Installing, updating, and running local quality gate verifications.
- **[How to Release Workflow Updates](docs/how-to/releasing-workflow-updates.md)**: Maintainer instructions for publishing point releases and advancing `@v1`.

### Reference (Information)
- **[Reusable Workflows Reference Specification](docs/reference/reusable-workflows-reference.md)**: Inputs, defaults, and outputs for all central workflows.
- **[Consumer Caller Archetypes Catalog](docs/reference/consumer-archetypes-catalog.md)**: Mapping project directory layouts to caller templates.
- **[AWS IAM OIDC Trust Policy Specification](docs/reference/iam-trust-policy-spec.md)**: JSON trust policies for development and production roles.

### Tutorials (Learning)
- **[Tutorial: Onboarding Your First Repository](docs/tutorials/onboarding-your-first-repository.md)**: Step-by-step beginner tutorial for setting up CI from scratch.

For a full navigation index, see the [AirFire CI/CD Documentation Hub](docs/README.md).

---

## 6. Floating Tag Governance (Maintainers)

When publishing updates to reusable workflows:

1. Commit changes to `main`:
   ```bash
   git add .github/workflows/reusable-*.yml
   git commit -m "feat(python): upgrade ruff checks and enable ty type checking"
   git push origin main
   ```
2. Tag an immutable SemVer point release:
   ```bash
   git tag -a v1.1.0 -m "Release v1.1.0"
   git push origin v1.1.0
   ```
3. Force-advance the floating major tag (`v1`):
   ```bash
   git tag -fa v1 -m "Update v1 reusable workflows to v1.1.0"
   git push origin v1 --force
   ```

All downstream repositories referencing `@v1` automatically inherit the update.
