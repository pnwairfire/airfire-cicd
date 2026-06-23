---
name: enforce-relative-paths
description: Enforce the use of relative paths for all links, images, and file references in documentation files. Detect and fix absolute paths (such as local filesystem paths, root-relative paths, or absolute internal domain URLs) to ensure documentation is portable and renders correctly in all environments.
---

# Enforce Relative Paths in Documentation

This skill guides the agent in identifying and correcting absolute paths in documentation files to ensure they are fully portable and link integrity is maintained across different user machines, CI environments, and hosting sites.

## Principles

1. **Never use local absolute paths:** Paths like `/home/robbl/repos/...` or `C:\Users\...` only work on the author's local machine.
2. **Never use root-relative paths:** Paths starting with a single `/` (e.g., `/docs/concepts/flows.md`) assume a specific web root and break when browsing files on GitHub or when using subpath hosting.
3. **Avoid absolute internal URLs:** If a link points to the same documentation site (e.g., `https://docs.prefect.io/concepts/flows`), it should use a relative link (e.g., `../concepts/flows.md`) so that link checkers and offline previews work correctly.
4. **Allow absolute external URLs:** Links pointing to external third-party sites (e.g., `https://github.com/` or `https://docs.python.org/`) must remain absolute.

## Workflow

### 1. Identify Target Files
Scan all changed or existing documentation files. These typically include:
- Markdown (`.md`, `.mdx`)
- HTML template files (`.tmpl`, `.html`)
- Text guides (`.txt`)

### 2. Scan for Absolute Paths
Inspect links, image tags, and code file links for these patterns:
- **Local File URLs:** Look for `file:///` or paths starting with `/home/`, `/Users/`, `/opt/`, `/tmp/`, etc.
- **Root-Relative Links:** Look for markdown links `[text](/path/...)` or HTML `<a href="/path/...` or `src="/path/...`.
- **Domain-Specific URLs:** Look for absolute URLs containing the project's documentation domain (e.g., `prefect.airfire.org`).

### 3. Compute the Relative Path
To replace an absolute path:
1. Determine the absolute path of the *source file* containing the link (e.g., `/home/user/project/docs/repository_code_map.md`).
2. Determine the absolute path of the *target file* being referenced (e.g., `/home/user/project/src/util/aqi_util.py`).
3. Compute the relative path from the source file's directory to the target file.
   - For example: from `/home/user/project/docs/` to `/home/user/project/src/util/aqi_util.py` is `../src/util/aqi_util.py`.
4. Preserve any anchor targets or line numbers (e.g., `#L69-L71` or `#concurrency-limits`).

### 4. Convert and Verify
- Update the documentation file with the calculated relative path.
- **Verification Rule:** Always verify that the computed relative path resolves to a file that actually exists in the local workspace. Do not commit broken relative links.
