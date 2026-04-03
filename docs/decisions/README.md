# Decision Records

This directory contains architectural and project decision records following the [MADR 4.0.0](https://adr.github.io/madr/) format.

## How decisions are captured

- **During AI sessions**: Agents detect significant decisions and draft ADRs collaboratively with the user
- **On demand**: Use `/decide` to capture a decision or scan for undocumented ones
- **Manually**: Copy `TEMPLATE.md`, fill it in, and add it to the index below

## What to record

Decisions that are hard to reverse, affect multiple components, or involve choosing between alternatives.
Skip trivial or easily reversible choices.

## Index

| ADR | Decision | Status | Date |
| ----- | ---------- | -------- | ------ |
| [ADR-0001](0001-use-madrs-for-decision-documentation.md) | Use MADRs for decision documentation | accepted | 2026-04-03 |
| [ADR-0002](0002-use-standards-docs-for-enforceable-rules.md) | Use separate standards docs for enforceable rules | accepted | 2026-04-03 |
| [ADR-0003](0003-use-sre-style-runbooks-for-operations.md) | Use SRE-style runbooks for operational procedures | accepted | 2026-04-03 |
| [ADR-0004](0004-markdown-quality-standard.md) | Enforce markdown quality with linting and semantic line breaks | accepted | 2026-04-03 |
| [ADR-0005](0005-atomic-commits-with-conventional-labels.md) | Use atomic commits with conventional commit labels | accepted | 2026-04-03 |
