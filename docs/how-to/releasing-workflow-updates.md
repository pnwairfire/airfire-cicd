---
title: "How to Release and Publish Workflow Updates in AirFire CI/CD"
description: "Maintainer recipe for committing changes, tagging immutable point releases, and advancing the floating v1 major tag."
published: true
editor: markdown
dateCreated: 2026-09-29T12:00:00.000Z
tags:
  - cicd
  - how-to
  - maintainer
  - release
  - git
---

# How to Release and Publish Workflow Updates in AirFire CI/CD

This recipe describes the procedure for repository maintainers releasing updates to the central reusable workflow suite in `pnwairfire/airfire-cicd`.

---

## 1. Overview of Floating Major Versioning

To balance pipeline stability with automated adoption of security fixes and linter updates across consuming repositories, `airfire-cicd` workflows follow the **floating major tag** pattern:

- **Immutable Point Tags (`v1.x.y`)**: Preserved for auditability, rollback, or repositories requiring strict immutable pins.
- **Floating Major Tag (`v1`)**: Automatically updated to point to the newest point release commit. Consuming repositories call `@v1` and automatically inherit improvements without manual configuration changes.

---

## 2. Step-by-Step Release Procedure

### Step 1: Verify All Workflows Locally
Before releasing any workflow modifications, run all local verification gates:

```bash
# Validate GitHub Actions syntax and schemas
actionlint

# Check markdown formatting
markdownlint docs/ README.md

# Run repository quality gates
run-local-ci
```

Ensure all commands exit with code 0.

### Step 2: Commit Changes to `main`
Stage the updated workflow definitions and commit using conventional commit syntax:

```bash
git add .github/workflows/reusable-*.yml
git commit -m "feat(python): upgrade ruff checks and enable ty type checking"
git push origin main
```

### Step 3: Tag an Immutable Point Release
Tag the release with an annotated SemVer tag describing the changes:

```bash
git tag -a v1.1.0 -m "Release v1.1.0: Add Astral uv dependency caching and ty type check"
git push origin v1.1.0
```

### Step 4: Advance the Floating Major Tag (`v1`)
Force-update the local `v1` tag to point to the new commit, then force-push the tag to GitHub:

```bash
git tag -fa v1 -m "Update v1 reusable workflows to v1.1.0"
git push origin v1 --force
```

---

## 3. Verifying Consumer Propagation

1. Open a downstream repository that consumes `@v1` (e.g. `prefect` or `outlook-v2`).
2. Trigger a test workflow run via `workflow_dispatch` or push.
3. Inspect the run logs to confirm the updated workflow steps execute.

---

## 4. Rollback Procedure

If a bug or breaking change is discovered in `@v1`:
1. Identify the last known stable point release commit SHA (e.g. `v1.0.0` at `ab13342`).
2. Retarget the `v1` tag back to that stable commit:
   ```bash
   git tag -fa v1 ab13342 -m "Rollback v1 to stable release v1.0.0"
   git push origin v1 --force
   ```
3. Consuming repositories will immediately fall back to the stable workflow version on their next execution.
