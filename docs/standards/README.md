# Standards

Enforceable rules for how the homelab infrastructure is built and operated.
Standards capture the **what** — normative rules that humans and agents must follow — while [decisions](../decisions/README.md) capture the **why**.

## How standards relate to decisions

A standard *may* link to a parent decision (ADR) that explains why the rule exists.
Not every standard needs an ADR — obvious or low-impact rules can stand alone.
But if a standard is controversial, hard to reverse, or has meaningful alternatives, the reasoning belongs in an ADR.

## How to add a standard

1. Copy `TEMPLATE.md` and fill it in
2. Use a descriptive kebab-case filename (e.g., `markdown-style-guide.md`)
3. Add it to the index below
4. If an enforcement tool exists, reference its configuration

## Index

| Standard | Scope | Enforcement | Status | Decision |
| ---------- | ------- | ------------- | -------- | ---------- |
| [Markdown style](markdown-style.md) | All `*.md` files | markdownlint-cli2, lefthook | accepted | ADR-0004 |
| [Commit discipline](commit-discipline.md) | All git commits | manual, /commit skill | accepted | ADR-0005 |
