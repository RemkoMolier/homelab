---
name: commit
description: Analyze working tree changes and create atomic conventional commits. Groups changes by logical concern and commits each group separately with a conventional commit message.
argument-hint: "[optional: description of what was done]"
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - AskUserQuestion
---

# Atomic Commit Skill

You create atomic conventional commits from the current working tree.
Each commit represents one logical change, labeled with a single conventional commit type.

## Context

Gather the current state before analyzing:

1. Run `git status --short` to see all changed/untracked files
2. Run `git diff` to see unstaged changes
3. Run `git diff --cached` to see already-staged changes
4. Run `git log --oneline -5` to see recent commit style

## Process

### Step 1: Analyze Changes

Review all diffs and group files by logical concern.
Each group must satisfy the atomicity test: if you `git revert` this commit, it should undo exactly one thing.

**Grouping heuristics:**

- Files in the same module or component belong together
- Test files group with the source files they test
- Config changes that are mechanically required by a code change belong with that code change
- Independent config changes (tuning, new settings) get their own commit
- Documentation changes separate from code changes
- Formatting or style changes separate from logic changes
- If a group needs the word "and" in its description, split it

### Step 2: Plan Commits

For each group, determine:

- **Files**: which files belong to this group
- **Type**: one conventional commit type (`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`)
- **Scope**: optional component name in parentheses (e.g., `docs`, `infra`, `config`)
- **Description**: concise summary of what and why (imperative mood, lowercase, no period)

Present the plan to the user with `AskUserQuestion` before executing.
Show each planned commit with its type, scope, files, and description.

### Step 2.5: Pre-commit Lint

Before creating any commits, run the full lint suite once:

```bash
mise run lint
```

If lint fails, fix the issues (e.g., run `tofu fmt -recursive` for formatting) and include the fixes in the appropriate commit group.
Do not proceed with commits until lint passes.

### Step 3: Execute Commits

For each group, in dependency order (foundational changes first):

1. `git add <specific files>` — never use `git add -A` or `git add .`
2. `git commit -m "<type>[(scope)]: <description>"` — use a HEREDOC for multi-line messages
3. Verify with `git status` that only the intended files were committed

**Safety rules:**

- Never use `git add -A`, `git add .`, or `git add --all`
- Never amend existing commits
- Never force-push
- Always stage specific files by name
- Each commit must leave the repository in a valid state
- If unsure about grouping, ask the user

## Commit Message Format

```text
<type>[(scope)][!]: <description>

[optional body]

[optional footer(s)]
```

**Rules:**

- Subject line: imperative mood, lowercase after type prefix, no trailing period, max 72 characters
- Body: explain *why*, not *what* (the diff shows what)
- Breaking changes: append `!` after type/scope and/or add `BREAKING CHANGE:` footer
- Reference issues in footers when applicable: `Refs: #123`

## Conventional Commit Types

| Type | When to use |
| ------ | -------- |
| `feat` | New capability or feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, whitespace (no logic change) |
| `refactor` | Code restructuring (no feature or fix) |
| `perf` | Performance improvement |
| `test` | Adding or correcting tests |
| `build` | Build system or dependency changes |
| `ci` | CI/CD configuration |
| `chore` | Maintenance tasks |
| `revert` | Revert a previous commit |

## Edge Cases

- **Single logical change across many files**: one commit is correct, even if the diff is large
- **Unrelated changes in the working tree**: split into separate commits by concern
- **Already-staged changes**: respect the user's staging; ask before unstaging
- **No changes**: inform the user there is nothing to commit
- **Mixed staged and unstaged for the same file**: ask the user which version to commit
