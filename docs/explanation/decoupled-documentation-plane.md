---
title: "Explanation: Decoupled Documentation Plane (Zero-Deploy-Key Architecture)"
description: "Architectural rationale for decoupling documentation authoring from central knowledge base ingestion without cross-repository deploy keys."
published: true
editor: markdown
dateCreated: 2026-09-29T12:00:00.000Z
tags:
  - cicd
  - explanation
  - documentation
  - security
  - diataxis
---

# Explanation: Decoupled Documentation Plane (Zero-Deploy-Key Architecture)

This document explains the security and architectural rationale behind AirFire's **zero-deploy-key decoupled documentation model**.

---

## 1. The Legacy Push Model and Its Vulnerabilities

Historically, AirFire satellite repositories synchronized their documentation into `pnwairfire/knowledge-base` or the team Wiki via automated post-merge push workflows (`sync-docs-to-knowledge-base.yml`).

This model suffered from serious architectural and security defects:

1. **Proliferation of Privileged SSH Deploy Keys**: Every satellite repository required a secret (`KNOWLEDGE_BASE_DEPLOY_KEY` or `CI_DEPLOY_KEY`) possessing write access to the centralized documentation repository. A compromise of any single satellite repo's GitHub Secrets would grant write access to the central knowledge base.
2. **Fragile Synchronization Scripts**: Each repository maintained custom bash or python synchronization scripts (e.g. `sync_docs_to_kb.sh`), creating script duplication and inconsistent error handling.
3. **Merge Collisions**: Simultaneous merges across multiple repositories caused Git push rejections and lock races against the target wiki repository.

---

## 2. The Decoupled Architecture

AirFire replaces the legacy push model with a strictly decoupled **authoring, validation, and ingestion architecture**:

```text
┌────────────────────────────────────────────────────────┐
│             Satellite Repository (e.g. fasm-v4)        │
│                                                        │
│  - Authors docs in docs/ (Diátaxis Framework)          │
│  - Runs reusable-docs.yml@v1 in CI                     │
│  - ZERO external write keys or deploy tokens           │
└───────────────────────────┬────────────────────────────┘
                            │
                            │ Registered in catalog.yaml
                            ▼
┌────────────────────────────────────────────────────────┐
│           pnwairfire/knowledge-base (Central Hub)      │
│                                                        │
│  - catalog.yaml tracks sources across the organization │
│  - Central scheduled workflow pulls docs from remotes  │
│  - Validates and indexes unified Diátaxis site         │
└────────────────────────────────────────────────────────┘
```

---

## 3. Core Planes of Operation

### 1. Authoring Plane (Satellite Repositories)
Developers author documentation directly alongside application code in `docs/`. Documentation adheres to the four Diátaxis quadrants (Explanation, How-To, Reference, Tutorials) and carries standard YAML frontmatter (`title`, `description`, `published`, `editor`, `tags`).

### 2. Validation Plane (`reusable-docs.yml@v1`)
On every pull request, the satellite repository calls `reusable-docs.yml@v1`. This workflow executes:
- Frontmatter validation ensuring mandatory tags and metadata exist.
- Markdownlint checks enforcing group formatting standards.
- Link verification ensuring all relative paths resolve locally.

### 3. Ingestion Plane (`knowledge-base/catalog.yaml`)
The central repository (`pnwairfire/knowledge-base`) declares participating documentation sources in a declarative manifest:

```yaml
sources:
  - repo: "pnwairfire/fasm-v4"
    branch: "main"
    source_dir: "docs"
    dest_dir: "services/fasm/web-app"
    description: "FASM interactive map and mobile client"
```

A scheduled, centralized pipeline in the knowledge base repository clones the registered branches, extracts the specified source directories, and rebuilds the organizational documentation site.

---

## 4. Key Benefits

- **Zero-Deploy-Key Security**: Satellite repositories require zero external write tokens or secrets.
- **Fail-Safe Independence**: A syntax error or broken link in one satellite repository's docs fails only its local CI; it cannot corrupt the central knowledge base.
- **Local Parity**: Developers run `run-local-ci` to validate documentation formatting locally before committing, eliminating surprise CI failures.
