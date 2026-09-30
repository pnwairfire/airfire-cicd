# AGENTS.md Guidelines for USFS AirFire CI/CD

This repository serves as the central Continuous Integration (CI) action hub and authoritative engineering policy repository for the USFS Pacific Northwest Research Station AirFire team.

All autonomous AI agents operating within this repository must adhere to the following instructions and quality gates.

---

## 1. Code Quality & Verification Commands

Before staging any git commit, agents must execute local verification commands to ensure zero regressions:

- **Validate GitHub Actions Workflows**: Use [actionlint](https://github.com/rhysd/actionlint) to catch YAML syntax errors, schema violations, and unpinned actions:
  ```bash
  actionlint .github/workflows/*.yml examples/*.yml
  ```
- **Lint and Format Markdown**: Use markdownlint to enforce Diátaxis formatting and style standards:
  ```bash
  markdownlint docs/ README.md examples/README.md AGENTS.md CLAUDE.md
  ```
- **Mandatory Pre-Commit Quality Gate**: Run the repository verification script and confirm 100% check pass rate:
  ```bash
  run-local-ci
  ```
- **Link Portability**: Ensure all markdown links use relative file paths (`enforce-relative-paths`).
- **No Emojis**: Prohibit emojis in documentation, policies, commit messages, and workflows (`professional-documentation`).

---

## 2. Repository Mission and Governance

`airfire-cicd` provides:
1. **Central Reusable Workflows (`.github/workflows/`)**: Callable workflows (`reusable-docs.yml`, `reusable-python.yml`, `reusable-node.yml`, `reusable-terraform.yml`) invoked by downstream repositories via `workflow_call`.
2. **Consumer Caller Archetypes (`examples/`)**: Pre-configured caller templates for Python, Node.js, Terraform, and Polyglot repositories.
3. **Diátaxis Documentation Suite (`docs/`)**: Comprehensive technical documentation organized into Explanation, How-To Guides, Reference, and Tutorials.

### Releasing Workflow Updates (Maintainer Procedure)
1. Commit workflow modifications to `main`.
2. Tag an immutable SemVer point release (e.g. `v1.1.0`).
3. Force-advance the floating major tag (`v1`) and push:
   ```bash
   git tag -fa v1 -m "Update v1 reusable workflows to v1.1.0"
   git push origin v1 --force
   ```

---

## 3. Organizational Engineering Standards

When updating policies, examples, or documentation, agents must conform to group standards:

### 1. Operational Reality
- Small collaborative engineering team across USFS, DRI, and UW.
- Monitoring alarms route to Slack `#fasm-alerts`; active triage and remediation occur in `#critical`.
- Never fabricate corporate enterprise hierarchy, secondary on-call rotations, PagerDuty schedules, or artificial commercial SaaS response SLAs.

### 2. Branching & Environments
- Trunk-based development on `main`.
- Standard environment tiers: `dev` (push to `main`), `staging` (pre-release validation), `prod` (versioned release tags `vM.m.r` with manual approval gates). Specialized domain tiers like `practice` permitted when justified.
- Deployment jobs must declare concurrency locks (`cancel-in-progress: false`).

### 3. Cloud Security & OIDC
- Keyless AWS OIDC authentication (`audience: sts.amazonaws.com`). Never commit static access keys.
- Store configuration metadata in GitHub Variables (`vars.AWS_ROLE_TO_ASSUME`, `vars.AWS_REGION`, etc.).
- Store confidential tokens in GitHub Secrets (`secrets.*`).
- Application runtime credentials reside in AWS Secrets Manager and are fetched dynamically via AWS CLI.

### 4. Zero-Deploy-Key Documentation Plane
- Contributing repositories author docs in `docs/` and run `reusable-docs.yml@v1`.
- Contributing repositories never maintain SSH deploy keys to push to `pnwairfire/knowledge-base`.
- The central knowledge base repository automatically pulls documentation registered in `catalog.yaml`.

### 5. Ephemeral Planning Hygiene
- Store transient plans, scratch outlines, and superpowers execution artifacts in `.superpowers/` or `.plans/`.
- Ensure `.superpowers/` and `.plans/` are excluded in `.gitignore` and never committed to version control.
