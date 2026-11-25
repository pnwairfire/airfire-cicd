---
title: "ADR-CICD-0001: Org-Level Ephemeral AWS CodeBuild GitHub Actions Runners (UW and EPA)"
description: "Adopt dual-account ephemeral AWS CodeBuild GitHub Actions runners (UW and EPA) with opt-in workflow routing to bypass GitHub Free-tier private-repo quota exhaustion."
published: true
date: 2026-11-25T10:15:00.000Z
tags:
  - airfire-cicd
  - explanation
  - adr
  - architecture
editor: markdown
dateCreated: 2026-11-25T10:15:00.000Z
---

# ADR-CICD-0001: Org-Level Ephemeral AWS CodeBuild GitHub Actions Runners (UW and EPA)

- **Status:** Accepted
- **Date:** 2026-11-25
- **Author / Implementer:** Robb Lankston
- **Domain:** CI/CD Infrastructure, AWS CodeBuild, GitHub Actions, Cloud Security

## 1. Context & Problem Statement

The `pnwairfire` GitHub organization operates on the GitHub Free plan, which includes 2,000 Linux Actions minutes per month for private repositories with a `$0` spending limit and no payment method on file. On 2026-11-24, private-repository usage reached 2,008.0 billed minutes (led by `prefect-af-managed` at 934m, `fasm-v4` at 247m, `outlook-viewer-v2` at 203m, `knowledge-base` at 137m, and `tileserver-pwfsl` at 114m), immediately blocking new CI and CD jobs across private repositories until the monthly quota reset.

Prior months (July: 1,977m, August: 1,704m, September: 1,527m, October: 1,101m) confirm that 2,000 minutes per month is a recurring structural ceiling. Public repositories (including `airfire-cicd`) continue to receive unlimited free `ubuntu-latest` minutes on GitHub and do not consume the private-repository quota.

## 2. Decision Drivers

- **Unblock private-repository CI/CD immediately** without requiring a GitHub organization credit card or paid Team plan.
- **Zero idle infrastructure cost** and low per-minute compute cost (`$0.005/min` on `BUILD_GENERAL1_SMALL`, below GitHub's `$0.006/min` overage rate).
- **Clean UW vs. EPA billing attribution** by hosting separate runner projects in the UW (`545607068190`) and EPA (`339712853872`) AWS accounts.
- **Native Docker build support** (`privileged_mode = true`) for containerized ECS/Fargate deployments.
- **Strict security isolation** preventing untrusted public-repository fork pull requests from invoking AWS compute and preserving keyless GitHub OIDC (`aws-actions/configure-aws-credentials@v4`) per-repository IAM trust boundaries.
- **Zero blast radius rollout** so untouched repositories continue running on `ubuntu-latest`.

## 3. Considered Options

### Option 1: Dual-Account Ephemeral AWS CodeBuild GitHub Actions Runners (Chosen)
Deploy a shared Terraform module (`terraform/modules/codebuild_runner/`) instantiated in `terraform/uw/` (`pnwairfire-uw-gh-runner`) and `terraform/epa/` (`pnwairfire-epa-gh-runner`), authenticated via AWS CodeConnections (*AWS Connector for GitHub* App scoped strictly to selected private repositories), with opt-in `runs-on` support in `airfire-cicd@v1`.

- **Pros:** `$0` idle cost; `$0.005/min` active Linux compute; ephemeral container per job (no cross-run state leakage); native `docker build` via `privileged_mode = true`; no static PATs; clean UW/EPA cost separation; per-job compute overrides (`-build-general1-medium`) without Terraform changes.
- **Cons:** Requires a one-time AWS Console OAuth handshake per AWS account; `aws/codebuild/standard:7.0` has minor preinstalled-tool differences vs. `ubuntu-latest` (mitigated by explicit `setup-*` actions).

### Option 2: Static EC2 Self-Hosted Runners
Provision always-on `t3.medium` / `t4g.medium` EC2 instances running `actions/runner`.

- **Pros:** Fast warm Docker layer cache; can register per-repo without installing a GitHub App.
- **Cons:** Persistent idle EC2 cost (`$25-30/mo` per runner); OS patching and disk cleanup maintenance; shared mutable state across jobs unless rebuilt per run.

### Option 3: Repo-Level CodeBuild with Personal Access Tokens (PATs)
Authenticate per-repo CodeBuild webhooks with GitHub PATs.

- **Pros:** No GitHub App installation email to organization owners.
- **Cons:** Static user-tied credentials requiring manual rotation; contradicts modern GitHub App / keyless security standards.

## 4. Decision Outcome

Adopted **Option 1**:

1. **Dual-Account Terraform Architecture (`terraform/`):**
   - Shared module in `terraform/modules/codebuild_runner/` provisioning `aws_codeconnections_connection`, 14-day `aws_cloudwatch_log_group`, least-privilege `aws_iam_role` (CloudWatch Logs + CodeConnections only, zero AWS deploy permissions), `aws_codebuild_project` (`aws/codebuild/standard:7.0`, `BUILD_GENERAL1_SMALL`, `privileged_mode = true`, 60m timeout), and `GITHUB_ORGANIZATION` `WORKFLOW_JOB_QUEUED` webhook.
   - `terraform/uw/` (`pnwairfire-uw-gh-runner`, UW state bucket `global-terraform-state-545607068190`) for UW-account repos (`prefect-af-managed`, `knowledge-base`, `wiki-infra`, `met-lakehouse`, `outlook-viewer-v2`).
   - `terraform/epa/` (`pnwairfire-epa-gh-runner`, EPA state bucket `airfire-cicd-tfstate-339712853872-us-west-2`) for EPA-account repos (`fasm-v4`, `tileserver-pwfsl`, `smoke-airnow-gov`, `airfire-auth`, `airfire-edge-infra`, `airfire-observability`).
2. **Two-Layer Opt-In & Public-Repo Exclusion (Option A):**
   - *AWS Connector for GitHub* is installed on `pnwairfire` with **Only select repositories** restricted strictly to private repositories (public repos stay free on `ubuntu-latest` and cannot trigger AWS CodeBuild).
   - All four reusable workflows in `.github/workflows/reusable-*.yml` add an optional `runs-on` input defaulting to `"ubuntu-latest"`. Passing `"codebuild-uw"` (or `"codebuild"`) routes to `pnwairfire-uw-gh-runner`; passing `"codebuild-epa"` routes to `pnwairfire-epa-gh-runner`.
3. **Preserved Keyless OIDC:**
   - Deployment jobs continue authenticating via `aws-actions/configure-aws-credentials@v4` with immutable GitHub OIDC subject claims (`repo:pnwairfire@11236785/<repo>@<repo_id>:*`).

## 5. Verification & Operational Runbook

- **Verify connections:** `aws --profile <uw|epa> --region us-west-2 codeconnections list-connections` must show `AVAILABLE`.
- **Add a new private repository:** Check the repository in GitHub Organization Settings -> Installed GitHub Apps -> *AWS Connector for GitHub*, then add `runs-on: "codebuild-uw"` or `runs-on: "codebuild-epa"` to the repository's workflows.
- **Per-job compute override:** Append `-build-general1-medium` to the CodeBuild `runs-on` label (e.g., `codebuild-pnwairfire-uw-gh-runner-${{ github.run_id }}-${{ github.run_attempt }}-build-general1-medium`) for memory-intensive builds.
- **Rollback:** Remove `runs-on` in any individual repository workflow to revert immediately to `ubuntu-latest`, or retag `v1` to `v1.4.1` in `airfire-cicd`.
