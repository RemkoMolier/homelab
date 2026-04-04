---
status: accepted
date: 2026-04-04
decision-makers: Remko Molier
---

# Use lefthook for pre-commit linting

## Context and Problem Statement

Terraform validation errors and markdown formatting issues were committed to the repository without being caught.
The existing `mise run lint` task catches these problems, but only when run manually.
How should linting be enforced automatically before code enters git history?

## Decision Drivers

- Must integrate with the existing `mise run lint` task suite
- Should be installable via mise (no manual tool setup)
- Should only run relevant linters when files in their scope change
- Minimal configuration and runtime dependencies

## Considered Options

- lefthook (Go-based hook manager)
- pre-commit (Python-based hook framework)
- husky (Node.js hook manager)
- Plain git hook script

## Decision Outcome

Chosen option: "lefthook", because it is a single Go binary installable via mise, runs shell commands natively, and supports glob-based filtering to only trigger relevant linters.

The hook is installed automatically via mise's `enter` hook when entering the project directory.

### Consequences

- Good, because linting errors are caught before they enter git history
- Good, because glob filters skip irrelevant linters (markdown lint skipped when only `.tf` files change, and vice versa)
- Good, because lefthook is managed by mise like all other tools — no separate install step
- Good, because automatic installation via mise `enter` hook means new clones get hooks without manual setup
- Neutral, because tflint warnings cause the hook to fail until they are resolved
- Neutral, because developers can bypass with `git commit --no-verify` in exceptional cases

### Confirmation

`lefthook run pre-commit` runs only the relevant linters based on staged file globs.
Committing a `.tf` file triggers `lint:terraform` but skips `lint:markdown`.

## Pros and Cons of the Options

### lefthook

Go-based hook manager with minimal YAML configuration.

- Good, because single binary, no runtime dependencies, installable via mise
- Good, because runs arbitrary shell commands natively — `mise run lint` works directly
- Good, because glob-based filtering is built in
- Good, because parallel execution of hooks
- Bad, because no ecosystem of pre-built hooks (not needed here)

### pre-commit

Python-based framework with a large ecosystem of managed hooks.

- Good, because large ecosystem of pre-built hooks with isolated environments
- Good, because installable via mise
- Bad, because designed around managed environments, overkill for running `mise run lint`
- Bad, because heavier conceptual model (repos, revs, language runtimes)

### husky

Node.js hook manager using plain shell scripts.

- Good, because hooks are just shell scripts in `.husky/` directory
- Bad, because requires Node.js and `package.json` — wrong fit for an infrastructure repo
- Bad, because not installable via mise as a standalone tool

### Plain git hook script

No extra tool — write `.git/hooks/pre-commit` directly.

- Good, because zero dependencies
- Bad, because `.git/hooks/` is not version-controlled — requires manual setup or a symlink script
- Bad, because no built-in glob filtering or parallel execution

## More Information

- [lefthook documentation](https://github.com/evilmartians/lefthook)
- [mise hooks](https://mise.jdx.dev/hooks.html) — used for automatic lefthook installation
