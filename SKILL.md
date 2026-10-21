---
name: airfire-cicd
description: Implement and maintain USFS AirFire compliant CI/CD pipelines using centralized @v1 reusable workflows from pnwairfire/airfire-cicd, conforming to organizational archetype, environmental, security, and local verification standards.
---

# USFS AirFire CI/CD Standards Skill

## Purpose
This skill guides autonomous AI agents in implementing, refactoring, and maintaining GitHub Actions pipelines and local quality gates across all `pnwairfire` repositories in compliance with official USFS AirFire engineering standards.

---

## 1. The Central Reusable Action Hub Directive

When tasked with setting up, updating, or fixing Continuous Integration in any AirFire repository:

### Mandatory Reusable Workflow Calling
- **Do Not Write Custom Runner Scripts**: Agents **MUST NOT** generate custom, standalone GitHub Actions steps for routine tasks (e.g. running raw `pip install`, manual `ruff` execution, custom `npm test` scaffolding, or manual `terraform fmt` steps).
- **Consume Central Hub Workflows**: Agents **MUST** configure `.github/workflows/ci.yml` as a consumer caller that invokes the centralized reusable workflows hosted in `pnwairfire/airfire-cicd@v1`:
  - Documentation: `uses: pnwairfire/airfire-cicd/.github/workflows/reusable-docs.yml@v1`
  - Python: `uses: pnwairfire/airfire-cicd/.github/workflows/reusable-python.yml@v1`
  - Node.js: `uses: pnwairfire/airfire-cicd/.github/workflows/reusable-node.yml@v1`
  - Terraform: `uses: pnwairfire/airfire-cicd/.github/workflows/reusable-terraform.yml@v1`
- **Floating Major Version Tag (`@v1`)**: Always pin central workflow calls to `@v1` so downstream repositories automatically inherit linter updates, patch fixes, and dependency caching enhancements.
- **Composition Rule**: If a repository requires specialized, bespoke jobs (such as building custom binaries or specialized integration probes), agents may define additional jobs alongside the `@v1` caller jobs within the same workflow.

### Selecting the Matching Archetype
Agents must inspect repository signals to select the matching template from `examples/`:
1. **Python Service** (`pyproject.toml`, `requirements.txt`): Use `examples/consumer-python-ci.yml`.
2. **Node.js Web App** (`package.json`, `package-lock.json`): Use `examples/consumer-node-ci.yml`.
3. **Terraform IaC** (`*.tf`): Use `examples/consumer-terraform-ci.yml`.
4. **Polyglot Monorepo** (multi-runtime directories): Use `examples/consumer-polyglot-ci.yml`.

---

## 2. Mandatory Pre-Commit Local CI Quality Gate

Before staging or committing any code changes or workflow modifications in any repository:

1. **Execute Local Verification**:
   ```bash
   run-local-ci
   ```
2. **Zero-Tolerance for Failures**:
   - If any step fails (linters, formatters, type checkers, unit tests, frontmatter validators), the agent **CANNOT** create the commit.
   - Fix the root cause and re-run `run-local-ci` until it reports `ALL QUALITY GATES PASSED` (exit code 0).
   - Never commit broken code with the intent to "fix it in CI" or "fix it later".
   - Never use `--no-verify` or `-n` to bypass local pre-push or pre-commit hooks.

---

## 3. Branching, Environments & Concurrency Conventions

### Branching Model
- Primary trunk branch: `main` (or `master` for legacy repositories).
- All changes must merge via pull requests from short-lived feature branches.
- Direct pushes to `main` are restricted.

### Standard Environment Tiers
- **`dev`**: Active testing and integration. Deployed automatically on pull request merge to `main`.
- **`staging`**: Pre-production validation and regression testing. Triggered on release candidate branches or manual dispatch.
- **`prod`**: Public, user-facing production systems. Deployed on Semantic Version tags (`vM.m.r`), protected by a GitHub Environment manual approval gate.
- **`practice`**: Specialized domain tiers (e.g. Smoke Outlooks ARA exercises) permitted when formally documented.

### Deployment Concurrency Controls
Workflows performing deployments must declare concurrency locks to prevent race conditions:
```yaml
concurrency:
  group: cd-${{ github.workflow }}-${{ inputs.environment || (github.event_name == 'release' && 'prod') || (startsWith(github.ref, 'refs/tags/v') && 'prod') || 'dev' }}
  cancel-in-progress: false
```

---

## 4. Cloud Security, OIDC & Secrets Architecture

### Keyless AWS Authentication (OIDC)
- **Never** add static AWS Access Keys (`AKIA...`) or Secret Access Keys to GitHub Secrets.
- Use OpenID Connect (OIDC) federation with AWS Security Token Service (STS).
- Enforce GitHub's immutable OIDC subject claims (`use_immutable_subject: true`) and configure AWS IAM trust policies with numeric Organization and Repository IDs (`repo:pnwairfire@11236785/<repo>@<repo_id>:...`) to prevent repository rename (`repo-jacking`) attacks.
- Workflows must declare minimum permissions and specify `audience: sts.amazonaws.com`:
  ```yaml
  permissions:
    id-token: write
    contents: read

  steps:
    - name: Configure AWS Credentials (OIDC)
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: ${{ vars.AWS_ROLE_TO_ASSUME }}
        aws-region: ${{ vars.AWS_REGION || 'us-west-2' }}
        audience: sts.amazonaws.com
  ```

### Configuration Variables vs. Secrets
- Store non-sensitive configuration metadata (IAM Role ARNs, AWS Regions, S3 Bucket Names, Cluster Names) in **GitHub Environment Variables** (`vars.*`).
- Reserve **GitHub Secrets** (`secrets.*`) strictly for confidential tokens (deploy keys, third-party API tokens).

### Application Runtime Secrets
- Do not duplicate database passwords or application API keys into GitHub Secrets.
- Fetch application credentials dynamically from **AWS Secrets Manager** via AWS CLI inside the deployment job.

### Decoupled Documentation Plane (Zero Deploy Keys)
- Contributing repositories must **never** store SSH deploy keys to push documentation to `pnwairfire/knowledge-base`.
- Validate documentation locally and in CI via `reusable-docs.yml@v1`.
- The central knowledge base repository automatically pulls sources registered in `knowledge-base/catalog.yaml`.
