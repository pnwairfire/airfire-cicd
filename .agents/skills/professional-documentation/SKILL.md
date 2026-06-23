---
name: professional-documentation
description: Enforce a professional, concise, and serious tone in all documentation files, and prohibit the use of emojis.
---

# Professional and Concise Documentation (No Emojis)

This skill guides the agent to ensure that all documentation is written in a professional, concise, and serious manner, and explicitly prohibits the use of emojis.

## Principles

1. **No Emojis:** Do not use emojis (e.g., 😄, 🚀, ⚠️, 💡) anywhere in documentation files, including titles, headings, body text, tables, list items, or callouts. Use standard markdown formatting (like blockquotes or alerts) for emphasis instead.
2. **Professional Tone:** Maintain a formal, objective, and authoritative voice. Avoid slang, overly casual phrasing, exclamation marks, or conversational filler.
3. **Concise and Direct:** Keep explanations brief and to the point. Focus on delivering maximum information with minimal words. Avoid redundant phrasing.
4. **Serious Demeanor:** Present technical details soberly and accurately, aligning with enterprise-grade software standards.

## Target Files

Scan and apply these principles to all documentation files, including but not limited to:
- Markdown files (`*.md`, `*.mdx`)
- OpenAPI/Swagger specs
- Inline documentation/docstrings (where they generate public API docs)
- Guides, walkthroughs, and tutorials

## Workflow

### 1. Detection
When writing or updating documentation files, inspect the content for:
- Emojis (both Unicode characters like `🚀` and shortcodes like `:rocket:`).
- Conversational or informal text (e.g., "Let's dive in!", "Awesome!").
- Exclamation marks (`!`) used to show excitement.
- Wordy or redundant sentences.

### 2. Refactoring & Correction
- **Remove Emojis:** Replace any emoji with professional formatting or clear text.
  - *Casual/Emoji:* "### Setup 🚀" -> *Professional:* "### Setup"
  - *Casual/Emoji:* "⚠️ Warning: This action cannot be undone." -> *Professional:* "> [!WARNING]\n> This action cannot be undone."
- **Simplify Sentence Structure:** Rewrite long, winding explanations into direct instructions.
- **Adjust Tone:** Replace casual/enthusiastic phrasing with objective statements.
  - *Casual:* "We are super excited to introduce our new AWS integration!"
  - *Professional:* "This section documents the AWS integration features."
