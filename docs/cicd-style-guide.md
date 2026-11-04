---
title: "USFS AirFire CI/CD Style Guide and Engineering Policy"
description: "Authoritative engineering policy, operational reality, and standards for GitHub Actions CI/CD across the USFS AirFire research group."
published: true
editor: markdown
dateCreated: 2026-09-29T12:00:00.000Z
tags:
  - cicd
  - policy
  - style-guide
  - explanation
  - standards
---

# USFS AirFire CI/CD Style Guide and Engineering Policy

This document establishes the official Continuous Integration and Continuous Deployment (CI/CD) engineering standards, operational conventions, and architectural patterns for the United States Forest Service (USFS) Pacific Northwest Research Station AirFire team.

It serves as the definitive policy for both human engineers and autonomous AI agents authoring or maintaining pipelines across all `pnwairfire` repositories.

---

## 0. Philosophy, Objectives & Operational Reality

### 0.1 The Integration and Deployment Problem
In distributed, high-consequence scientific operations, code changes must be validated, packaged, and deployed reliably. Uncoordinated manual deployments risk runtime discrepancies, regression failures in mission-critical wildland fire forecasts, security exposures, and service interruptions for interagency partners such as the EPA, InciWeb, and state air quality agencies.

### 0.2 The CI/CD Solution
AirFire enforces automated Continuous Integration (CI) and Continuous Deployment (CD):
- **Continuous Integration (CI)**: Validates every code change automatically against strict formatting, linting, type-checking, documentation, and automated test gates on pull requests prior to merging into primary branches.
- **Continuous Deployment (CD)**: Deterministically deploys verified software to target environments (`dev`, `staging`, `prod`) using keyless cloud authentication, zero-downtime rolling strategies, and atomic asset synchronization.

### 0.3 Operational Team Reality & Incident Culture
When designing pipelines, runbooks, or alerting logic, all policies must reflect the group's real-world team structure:
- **Small Multi-Disciplinary Team**: AirFire operates as a lean, collaborative team of software engineers (focusing on cloud infrastructure, backend pipelines, and web clients), scientific developers, and atmospheric/wildfire research scientists across USFS, Desert Research Institute (DRI), and the University of Washington (UW).
- **Shared Operational Ownership**: There is no dedicated 24/7 tiered Network Operations Center (NOC), no secondary on-call rotation, and no commercial PagerDuty scheduling. Team members share operational awareness collaboratively.
- **Alert Routing and Coordination**: Automated monitoring alerts, health probe warnings, and CloudWatch alarms dispatch directly to Slack `#fasm-alerts`. Active incident investigation and operational remediation are coordinated in `#critical` to ensure mutual visibility and eliminate redundant troubleshooting.
- **Prohibited Enterprise Tropes**: Documentation, runbooks, and workflow policies must never reference corporate hierarchy, multi-tiered escalation trees, or artificial commercial SaaS response targets (e.g. "< 15 minutes SLA").

### 0.4 The Local CI Pre-Commit Gate
All engineers and autonomous AI agents operating in any repository must satisfy the pre-commit quality gate. Before creating a git commit or pushing changes, the local verification tool must be executed:

```bash
run-local-ci
```

No code may be committed with the assumption that CI will "fix it later." Local parity requires 100% check pass rate before staging.

---

## 1. Git Workflow and Branching Conventions

### 1.1 Branching Strategy
AirFire standardizes on trunk-based development:
- **Primary Branch**: The canonical trunk branch is `main` (or `master` in legacy repositories).
- **Feature Branches**: Changes are developed on short-lived branches cut from `main` (e.g. `feat/<topic>`, `fix/<topic>`, `chore/<topic>`).
- **Direct Pushes**: Direct pushes to `main` are restricted. All changes must be integrated via Pull Requests.

### 1.2 Pull Requests & Quality Gates
- Every pull request targeting `main` automatically triggers CI quality checks.
- Pull requests require all automated CI checks to pass before merging.
- Self-review and peer review are encouraged, but merging is permitted once all automated gates succeed.

### 1.3 Commit Signing
- Engineers are strongly encouraged to sign git commits using verified GPG or SSH keys:
  ```bash
  git config --global commit.gpgsign true
  git config --global user.signingkey <YOUR_KEY_ID>
  ```
- Signed commits protect the software supply chain against author impersonation and unauthorized modifications.

---

## 2. Environment Topology and Deployment Strategy

AirFire applications target three standardized environment tiers alongside recognized domain-specific tiers:

| Environment | Purpose | Access & Approvals | Deployment Trigger |
| :--- | :--- | :--- | :--- |
| **`dev`** | Integration testing, active development verification. | Open to team members. | Automatic on pull request merge (push) to `main`. |
| **`staging`** | Pre-production validation, schema migration testing, regression gates. | Open or restricted by branch. | Manual dispatch or push to release candidate branches (`release/*`). |
| **`prod`** | Public, user-facing production applications and partner APIs. | Restricted access. Requires manual reviewer approval gate. | Automatic on Semantic Version release tags (`vM.m.r`). |
| **`practice`** | Specialized simulation tier (e.g. Smoke Outlooks training). | Open for authorized team members. | Parameterized manual dispatch (`workflow_dispatch`). |

### 2.1 Versioned Release Tags (`vM.m.r`)
Production releases must adhere to [Semantic Versioning (SemVer)](https://semver.org/) and be tagged with the prefix `v` followed by major, minor, and patch numbers (e.g. `v1.2.4`, `v4.5.4`).

### 2.2 GitHub Environment Approval Gates
To prevent unauthorized production rollouts, repositories deploying to production must configure a protected GitHub Environment named `prod`:
1. **Required Reviewers**: Designate repository administrators or senior developers to approve deployments.
2. **Environment Variables & Secrets**: Isolate production cloud credentials and variables from development targets.
3. For step-by-step setup instructions, see [How to Configure GitHub Environments](how-to/configuring-github-environments.md).

### 2.3 Deployment Concurrency Controls
Deployments must enforce concurrency locks to eliminate race conditions and prevent partial rollouts:

```yaml
concurrency:
  group: cd-${{ github.workflow }}-${{ inputs.environment || (github.event_name == 'release' && 'prod') || (startsWith(github.ref, 'refs/tags/v') && 'prod') || 'dev' }}
  cancel-in-progress: false
```

Setting `cancel-in-progress: false` ensures that an in-flight deployment completes cleanly rather than being aborted mid-step by a subsequent run.

---

## 3. Cloud Security, OIDC & Secrets Architecture

### 3.1 Keyless AWS Authentication via OpenID Connect (OIDC)
AirFire strictly prohibits storing static, long-lived AWS Access Keys (`AKIA...`) or Secret Access Keys in GitHub Secrets.

All workflows authenticate to AWS using OpenID Connect (OIDC) federation, requesting short-lived, auto-expiring STS credentials:

- Workflows must declare minimum required permissions:
  ```yaml
  permissions:
    id-token: write
    contents: read
  ```
- Workflows assume designated IAM roles with explicit audience validation:
  ```yaml
  - name: Configure AWS Credentials (OIDC)
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ vars.AWS_ROLE_TO_ASSUME }}
      aws-region: ${{ vars.AWS_REGION || 'us-west-2' }}
      audience: sts.amazonaws.com
  ```
- IAM role trust policies must enforce GitHub's immutable OIDC subject claim format (`repo:pnwairfire@11236785/<repo>@<repo_id>:...`) and repositories must enable `use_immutable_subject: true` to mitigate repository rename (`repo-jacking`) attacks.
- Detailed setup instructions are available in [How to Configure AWS OIDC](how-to/configuring-aws-oidc.md) and the [AWS IAM OIDC Trust Policy Specification](reference/iam-trust-policy-spec.md).

### 3.2 Clear Scoping: GitHub Variables vs. GitHub Secrets
AirFire enforces a strict separation between configuration metadata and sensitive secrets:

- **GitHub Variables (`vars.*`)**: Non-sensitive configuration metadata such as AWS Role ARNs, AWS Regions, S3 Bucket Names, and ECS Cluster/Service names. These are stored as Variables to facilitate visibility and maintenance.
- **GitHub Secrets (`secrets.*`)**: Confidential authentication tokens such as third-party API keys, webhook URLs, and external tokens. These are masked in logs.
- For configuration steps, consult [How to Manage Secrets and Variables](how-to/managing-secrets-and-variables.md).

### 3.3 Application Runtime Secrets (AWS Secrets Manager)
Application credentials (database connection strings, signing keys, API secrets) must not be duplicated into GitHub Secrets.

Workflows authenticate via AWS OIDC and pull runtime secrets dynamically using the AWS CLI during deployment:

```bash
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id "fasm/${ENV}/db-password" \
  --query SecretString \
  --output text)
```

All AWS Secrets Manager secrets must enforce:
1. Dedicated customer-managed KMS encryption keys.
2. Least-privilege IAM resource policies.
3. Automatic rotation policies.
4. AWS CloudTrail auditing.

### 3.4 Multi-Account Operational Boundaries
Infrastructure is partitioned across two operational AWS accounts:
- **EPA Production Account (`339712853872`)**: Public tile serving (`tileserver.airfire.org`), CloudFront CDN distributions, production spatial databases (`tileserver-db`), and containerized Fargate clusters.
- **UW Operations Account (`545607068190`)**: Real-time data ingestion pipelines (`fasm-worker-1`, `purpleair-prefect-worker`, `elwood`), legacy `near-me` API fleet, and experimental research pipelines.

---

## 4. Recognized Architectural Deployment Footprints

Depending on operational requirements, applications target one of five architectural footprints:

### Footprint A: Modern Serverless Container Services (AWS ECS + Fargate)
- **Use Cases**: Containerized backend services, API servers, and dynamic tileservers (`tileserver-pwfsl`, `outlook-pdf`, `wiki-infra`).
- **Deployment Pattern**: Multi-tag Docker build (`sha-<commit>` and environment tag) pushed to AWS ECR using Buildx with GitHub Actions layer caching (`type=gha`), followed by ECS rolling deployment (`aws ecs update-service --force-new-deployment`).
- **Routing**: Application Load Balancers (ALBs) with Cloudflare WAF integration.

### Footprint B: Static Web & Edge SPAs (AWS S3 + CloudFront + Cloudflare)
- **Use Cases**: Interactive web maps and frontend portals (`fasm-v4`, `outlook-viewer-v2`, `smoke-airnow-gov`).
- **Deployment Pattern**: Vite/Svelte compilation -> Two-pass atomic S3 synchronization:
  - *Pass 1*: Upload hashed assets (`/assets/*`) with `Cache-Control: public, max-age=31536000, immutable`.
  - *Pass 2*: Upload `index.html` with `Cache-Control: no-cache, no-store, must-revalidate`.
  - *Pass 3*: Targeted CloudFront cache invalidation on `/index.html`.
- **Eliminates**: Browser `ChunkLoadError` crashes, deployment downtime, and static web server compute costs.

### Footprint C: Data Ingestion & Orchestration Pipelines (Prefect Flows + ECS Workers)
- **Use Cases**: Scheduled wildfire data collectors, PurpleAir ingestion, weather layer generation (`prefect-af-managed`, `fasm-pipeline`).
- **Deployment Pattern**: Dynamic changed-path matrix detection -> Base image build and push -> Rolling restart of ECS worker services -> Matrix registration of Prefect flow deployments.

### Footprint D: Serverless Observability & Sentries (AWS Lambda + EventBridge + SNS)
- **Use Cases**: Automated health probers, DNSSEC monitors, and alert forwarders (`airfire-observability`).
- **Deployment Pattern**: Python package bundling via `uv` -> Lambda function deployment -> CloudWatch EventBridge cron triggers -> SNS alert dispatch to Slack `#fasm-alerts`.

### Footprint E: Legacy Compute Fleet (EC2 + Docker Compose + Fabric)
- **Use Cases**: Older standalone services (`near-me` fleet, historical sync nodes).
- **Deployment Pattern**: SSH key retrieval -> Remote invocation of Python Fabric scripts -> `docker compose pull` and container restarts. Maintained until scheduled migration to ECS.

---

## 5. The Central Reusable Action Hub Standard

To prevent configuration drift and eliminate copy-pasted workflow files, AirFire standardizes on a **Central Reusable Action Hub** architecture hosted in `pnwairfire/airfire-cicd`.

### 5.1 Mandatory Caller Pattern
Downstream repositories must not maintain duplicate YAML pipelines for standard linting, formatting, testing, and IaC validation. Instead, repositories must call centralized reusable workflows:

```text
uses: pnwairfire/airfire-cicd/.github/workflows/reusable-<type>.yml@v1
```

For architectural rationale, consult the [Central Reusable Hub Architecture Deep-Dive](explanation/hub-and-spoke-architecture.md).

### 5.2 Available Central Workflows (`.github/workflows/`)

| Workflow File | Key Capabilities | Parameter Reference |
| :--- | :--- | :--- |
| **`reusable-docs.yml`** | Validates Diátaxis YAML frontmatter, Wiki.js namespace hubs, and markdownlint formatting. | [reusable-docs reference](reference/reusable-workflows-reference.md#1-reusable-docsyml) |
| **`reusable-python.yml`** | Modern Python CI using Astral `uv`, Python 3.12, `ruff check`, `ruff format --check`, and `pytest`. | [reusable-python reference](reference/reusable-workflows-reference.md#2-reusable-pythonyml) |
| **`reusable-node.yml`** | Node.js 20/22 LTS CI with npm/pnpm caching, ESLint, unit testing, and build bundle validation. | [reusable-node reference](reference/reusable-workflows-reference.md#3-reusable-nodeyml) |
| **`reusable-terraform.yml`** | Infrastructure-as-Code checks running `terraform fmt -check`, `tflint`, and `terraform validate`. | [reusable-terraform reference](reference/reusable-workflows-reference.md#4-reusable-terraformyml) |

### 5.3 Consumer Caller Archetypes (`examples/`)
Ready-to-copy caller workflow templates are maintained under `examples/`:
- **[consumer-python-ci.yml](../examples/consumer-python-ci.yml)**: Standard for Python services and CLI tools.
- **[consumer-node-ci.yml](../examples/consumer-node-ci.yml)**: Standard for web frontends and TypeScript libraries.
- **[consumer-terraform-ci.yml](../examples/consumer-terraform-ci.yml)**: Standard for cloud infrastructure repositories.
- **[consumer-polyglot-ci.yml](../examples/consumer-polyglot-ci.yml)**: Standard for multi-language repositories.
- For complete mapping guidance, see the [Consumer Caller Archetypes Catalog](reference/consumer-archetypes-catalog.md).

### 5.4 Decoupled Documentation Plane (Zero Deploy Keys)
Contributing repositories never push documentation directly to `pnwairfire/knowledge-base` or maintain cross-repository write SSH keys:
1. Repositories author documentation in `docs/` adhering to the Diátaxis framework.
2. Repositories validate documentation locally and in CI using `reusable-docs.yml@v1`.
3. Repositories register their source path in `pnwairfire/knowledge-base/catalog.yaml`.
4. The central knowledge base repository automatically pulls documentation sources on a scheduled cadence.
5. For deep-dive architectural context, see [Decoupled Documentation Plane Explanation](explanation/decoupled-documentation-plane.md).

---

## 6. Diátaxis Documentation Navigation Hub

This repository maintains complete documentation partitioned across the four Diátaxis quadrants:

### Explanation (Understanding)
- [Central Reusable Hub Architecture](explanation/hub-and-spoke-architecture.md): Rationale for centralizing CI/CD, `workflow_call`, and floating tag governance.
- [Decoupled Documentation Plane](explanation/decoupled-documentation-plane.md): Security and operational benefits of zero-deploy-key documentation ingestion.

### How-To Guides (Problem-Solving)
- [How to Migrate a Repository to Standard CI](how-to/migrating-a-repo-to-standard-ci.md): 4-step checklist to adopt `@v1` reusable workflows.
- [How to Configure AWS OIDC](how-to/configuring-aws-oidc.md): Step-by-step IAM identity provider and role setup.
- [How to Configure GitHub Environments](how-to/configuring-github-environments.md): Setting up `dev`, `staging`, `prod` gates and concurrency locks.
- [How to Manage Secrets and Variables](how-to/managing-secrets-and-variables.md): Distinguishing `vars.*` from `secrets.*` and dynamic AWS Secrets Manager access.
- [How to Release Workflow Updates](how-to/releasing-workflow-updates.md): Maintainer instructions for tagging releases and updating the `@v1` floating tag.

### Reference (Information)
- [Reusable Workflows Reference](reference/reusable-workflows-reference.md): Input parameters and specifications for all central workflows.
- [Consumer Caller Archetypes Catalog](reference/consumer-archetypes-catalog.md): Directory signals and templates for Python, Node, Terraform, and Polyglot projects.
- [AWS IAM OIDC Trust Policy Specification](reference/iam-trust-policy-spec.md): Standard JSON trust policy documents.

### Tutorials (Learning)
- [Tutorial: Onboarding Your First Repository](tutorials/onboarding-your-first-repository.md): Practical hands-on lesson for setting up CI from scratch.
