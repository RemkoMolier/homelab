---
status: accepted
date: 2026-04-04
decision: ADR-0005
scope: all git commits
enforcement: manual, /commit skill
---

# Commit discipline

## Rule

1. One logical change per commit.
   If `git revert` would undo something unrelated, the commit must be split.
2. One conventional commit type per commit.
   If a commit needs two types, it must be split.
3. Commit message format: `<type>[(scope)]: <description>`
   - Imperative mood, lowercase, no trailing period, max 72 characters.
4. Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
5. Scopes are optional: `docs`, `infra`, `config`, `network`, `storage` — expand as components are added.
6. Separate refactoring from behavior changes.
7. Separate formatting from logic changes.
8. Tests travel with the code they test (same commit).
9. Each commit must leave the repository in a buildable state.
10. If the commit message needs "and", split the commit.
11. Do not include agent references (e.g., `Co-Authored-By`) unless explicitly asked.

## Rationale

Atomic commits make `git revert`, `git bisect`, and code review reliable.
Conventional labels make `git log --oneline` scannable and machine-parseable.
The type prefix doubles as an atomicity check: a commit that cannot be described with a single type needs splitting.
See [ADR-0005](../decisions/0005-atomic-commits-with-conventional-labels.md) for full context.

## Scope

All commits to the repository, whether authored by humans or AI agents.

## Examples

### Compliant

```text
feat(infra): add CRS226 switch-chip VLAN configuration
fix(infra): resolve routeros provider validation errors
docs: add ADR-0011 and document pre-commit hooks
refactor(infra): reorganize modules into components/ and devices/
```

### Non-compliant

```text
Add CRS226 config and fix validation errors
(bundles unrelated changes, missing type)

feat(infra): add VLAN config and refactor module structure
(two types needed — split into feat + refactor)

Fix stuff
(vague, no type, not imperative)

feat(infra): Add CRS226 switch-chip VLAN configuration.
(uppercase, trailing period)
```

## Enforcement

- **AI agents**: rules are codified in `CLAUDE.md` and enforced by the `/commit` skill
- **Future**: commitlint hook via lefthook (configuration prepared, not yet activated)
- **Manual**: review commit messages before push

## Exceptions

None.
