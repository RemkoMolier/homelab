---
status: accepted
date: 2026-04-03
decision-makers: Remko Molier
---

# Enforce markdown quality with linting and semantic line breaks

## Context and Problem Statement

As the homelab repository grows, markdown documentation will be authored by both humans and AI agents.
Without enforced standards, formatting drift is inevitable — inconsistent headings, list styles, and line wrapping accumulate over time.
Additionally, traditional paragraph wrapping produces noisy diffs where a single word change reflows an entire paragraph, making commits hard to review.

How should we ensure consistent markdown quality and reviewable diffs across the repository?

## Decision Drivers

- Diffs in commits and PRs should clearly show what changed at the sentence level
- Style must be enforced automatically, not rely on manual review
- Tooling should integrate with editors (VS Code) for real-time feedback
- The solution should work without heavy runtime dependencies in the initial phase
- MADR templates with YAML frontmatter and HTML comments must be supported

## Considered Options

- markdownlint-cli2 with semantic line breaks
- Prettier for markdown formatting
- remark-lint (unified ecosystem)
- No tooling (manual style enforcement)

## Decision Outcome

Chosen option: "markdownlint-cli2 with semantic line breaks", because it provides configurable, non-opinionated linting with auto-fix capability.
Combined with the semantic line breaks convention (one sentence per line), diffs become meaningful at the sentence level.
The `.markdownlint-cli2.yaml` config is auto-detected by the VS Code extension, giving real-time feedback without additional setup.

### Consequences

- Good, because diffs show exactly which sentences changed, not reflowed paragraphs
- Good, because markdownlint rules are individually configurable — no opinionated formatting imposed
- Good, because the VS Code extension uses the same config files as the CLI
- Good, because `.editorconfig` provides baseline settings for any editor
- Good, because MADR compatibility is achieved with targeted rule overrides (MD013, MD024, MD025, MD033)
- Good, because compact table style (MD060) avoids noisy diffs from column realignment
- Bad, because semantic line breaks are unfamiliar to some contributors and look different in source
- Neutral, because the custom rule for enforcing semantic breaks (`markdownlint-sentences-per-line`) requires npm installation, deferred to when CLI tooling is set up

### Confirmation

All markdown files in the repository pass `markdownlint-cli2` with no violations.
Prose paragraphs use one sentence per line.
The `.markdownlint-cli2.yaml` and `.editorconfig` config files exist in the repository root.

## Pros and Cons of the Options

### markdownlint-cli2 with semantic line breaks

Configurable linter with 60+ rules, `--fix` auto-correction, and VS Code extension support.
Semantic line breaks (SemBr) convention places one sentence per line for clean diffs.

- Good, because rules are individually toggleable — not opinionated
- Good, because `--fix` mode auto-corrects many violations
- Good, because VS Code extension provides real-time linting with no extra config
- Good, because MADR project itself uses markdownlint
- Bad, because enforcing semantic breaks requires a custom rule (`markdownlint-sentences-per-line`)

### Prettier for markdown

Opinionated formatter that deterministically rewrites files.

- Good, because zero configuration needed — one canonical output
- Good, because handles table alignment, list indentation, and code blocks
- Bad, because opinionated by design — formatting choices cannot be overridden
- Bad, because `proseWrap: "preserve"` is compatible with semantic breaks but cannot enforce them
- Bad, because adds a heavy runtime dependency for formatting alone

### remark-lint

Plugin-based linter built on the unified/remark AST ecosystem.

- Good, because highly composable with deep AST access
- Good, because part of the larger unified ecosystem (also handles HTML, text)
- Bad, because more complex to configure — rules are separate npm packages
- Bad, because smaller community adoption than markdownlint for standalone linting

### No tooling

Rely on manual review and contributor discipline.

- Good, because zero setup and no dependencies
- Bad, because style drift is inevitable as the repo grows
- Bad, because AI agents have no machine-readable rules to follow
- Bad, because review burden increases with every PR

## More Information

- [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2) — the linter CLI
- [VS Code markdownlint extension](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint) — IDE integration
- [SemBr specification](https://sembr.org) — semantic line breaks convention
- [sentences-per-line](https://github.com/JoshuaKGoldberg/sentences-per-line) — custom markdownlint rule for enforcement
- [MADR markdownlint config](https://github.com/adr/madr/blob/develop/.markdownlint.yml) — the MADR project's own linter settings
