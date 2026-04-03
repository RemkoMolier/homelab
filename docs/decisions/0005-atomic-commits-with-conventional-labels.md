---
status: accepted
date: 2026-04-03
decision-makers: Remko Molier
---

# Use atomic commits with conventional commit labels

## Context and Problem Statement

As the homelab repository grows, git history becomes an important reference for understanding what changed and why.
Without commit discipline, history degrades — monolithic commits bundle unrelated changes, making `git revert`, `git bisect`, and code review harder.
AI agents exacerbate this by defaulting to single large commits per task.

How should commits be structured to keep the git history clean, navigable, and useful?

## Decision Drivers

- Each commit should be linked to a specific goal — one logical change, revertable without side effects
- The commit message format should be parseable by both humans and machines
- AI agents need explicit rules to follow, since they default to monolithic commits
- The convention should be an established standard with tooling support
- Enforcement should match the project's incremental approach (config first, hooks later)

## Considered Options

- Atomic commits with conventional commit labels
- Conventional commits without atomicity rules
- Freeform commit messages with guidelines
- Gitmoji

## Decision Outcome

Chosen option: "Atomic commits with conventional commit labels", because atomic discipline and conventional format reinforce each other.
The type prefix acts as an atomicity check — if a commit cannot be described with a single type (`feat`, `fix`, `refactor`, etc.), it needs splitting.
A custom `/commit` skill for Claude Code adapts patterns from the [Atomic plugin](https://github.com/GreyBoxed/atomic) to enforce this when agents commit.

### Consequences

- Good, because each commit is revertable without unintended side effects
- Good, because `git log --oneline` produces a scannable, typed history
- Good, because the convention is enforced in AI agent instructions (CLAUDE.md, AGENTS.md) and the `/commit` skill
- Good, because commitlint config is ready for enforcement via hooks when the project reaches that phase
- Good, because the type prefix makes non-atomic commits obvious (needing "and" or multiple types)
- Bad, because atomic commit discipline requires more thought than dumping all changes in one commit
- Neutral, because the `/commit` skill reduces the burden on AI agents but adds a file to maintain

### Confirmation

All commits in the repository follow the conventional commit format.
No commit requires multiple types to describe its contents.
The `/commit` skill is functional and produces correctly grouped atomic commits.

## Pros and Cons of the Options

### Atomic commits with conventional commit labels

One logical change per commit, labeled with a conventional type prefix.
Enforced via documentation, a `/commit` skill, and commitlint config.

- Good, because type prefix doubles as atomicity check
- Good, because mature tooling ecosystem (commitlint, changelog generators if ever needed)
- Good, because well-known standard — lower barrier for contributors and agents
- Bad, because requires discipline to separate refactoring, formatting, and feature work

### Conventional commits without atomicity rules

Use conventional commit format but without rules about what goes into each commit.

- Good, because structured messages improve readability
- Bad, because a `feat: add auth and fix database migration` commit is technically valid
- Bad, because `git revert` and `git bisect` become unreliable with bundled changes

### Freeform commit messages with guidelines

No enforced format — rely on good judgment and code review.

- Good, because zero overhead
- Bad, because AI agents have no parseable rules to follow
- Bad, because style drifts inevitably without enforcement
- Bad, because `git log` becomes inconsistent and hard to scan

### Gitmoji

Emoji prefixes instead of text types (e.g., sparkles for features, bug for fixes).

- Good, because visually distinctive in git log
- Bad, because harder to grep and filter than text types
- Bad, because emoji semantics are ambiguous (does rocket mean deploy or performance?)
- Bad, because polarizing among developers

## More Information

- [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) — the specification
- [Google Small CLs Guide](https://google.github.io/eng-practices/review/developer/small-cls.html) — commit size best practices
- [SmartBear/Cisco Code Review Study](https://static0.smartbear.co/support/media/resources/cc/book/code-review-cisco-case-study.pdf) — 200-400 LOC optimal review size
- [GreyBoxed/Atomic](https://github.com/GreyBoxed/atomic) — Claude Code plugin (patterns adapted for `/commit` skill)
- [commitlint](https://commitlint.js.org/) — commit message linter
