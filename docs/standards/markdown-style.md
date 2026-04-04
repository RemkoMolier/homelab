---
status: accepted
date: 2026-04-04
decision: ADR-0004
scope: all Markdown files (*.md)
enforcement: markdownlint-cli2, lefthook pre-commit hook
---

# Markdown style

## Rule

1. One sentence per line (semantic line breaks).
   Do not hard-wrap paragraphs at a fixed column width.
2. All files must pass `markdownlint-cli2` with the project configuration (`.markdownlint-cli2.yaml`).
3. Tables use compact style: single space around cell content, no alignment padding.
4. YAML frontmatter is permitted and must not be treated as an implicit heading.
5. HTML comments are permitted (used in MADR templates).
6. Duplicate headings are allowed under different parent headings.

## Rationale

Semantic line breaks produce diffs at the sentence level, making commits and PRs easy to review.
Automated linting prevents style drift across human and AI-authored documentation.
See [ADR-0004](../decisions/0004-markdown-quality-standard.md) for full context.

## Scope

All `*.md` files in the repository.
The `.gitignore` is respected — generated or vendored markdown is excluded.

## Examples

### Compliant

```markdown
Infrastructure is managed with OpenTofu.
Device configuration uses the routeros provider.
See the module README for details.

| Device | IP | Role |
| --- | --- | --- |
| crs226 | 172.16.1.13 | Switch |
```

### Non-compliant

```markdown
Infrastructure is managed with OpenTofu. Device configuration uses the
routeros provider. See the module README for details.

| Device | IP         | Role   |
| ------ | ---------- | ------ |
| crs226 | 172.16.1.13 | Switch |
```

## Enforcement

- **Linter**: `markdownlint-cli2` with `.markdownlint-cli2.yaml` in the repository root
- **Pre-commit hook**: lefthook runs `mise run lint:markdown` on staged `*.md` files
- **IDE**: VS Code extension `DavidAnson.vscode-markdownlint` auto-detects the config
- **Manual**: `mise run lint:markdown` or `mise run lint`

## Exceptions

None.
