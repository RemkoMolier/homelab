---
status: accepted
date: 2026-04-06
decision-makers: Remko Molier
---

# Use GitHub Actions for CI linting

## Context and Problem Statement

The repository enforces code quality locally via lefthook pre-commit hooks (see [ADR-0011](0011-use-lefthook-for-pre-commit-linting.md)), but nothing prevents unformatted or invalid code from reaching the remote repository.
Contributors can skip hooks (`--no-verify`), use a client without hooks installed, or push directly via the GitHub web UI.
How should we enforce lint checks on every change that reaches the repository?

## Decision Drivers

* Pre-commit hooks are client-side and can be bypassed
* Pull requests should show a clear pass/fail status before merge
* The CI environment should mirror the local lint toolchain to avoid drift
* mise already defines all tool versions and lint tasks

## Considered Options

* GitHub Actions with mise
* GitHub Actions with pinned tool versions (no mise)
* Third-party CI service (e.g., CircleCI, GitLab CI)

## Decision Outcome

Chosen option: "GitHub Actions with mise", because it reuses the existing `mise.toml` tool definitions and task commands, keeping local and CI linting identical with minimal duplication.

### Consequences

* Good, because CI runs the same lint commands as local hooks — no drift
* Good, because mise manages tool versions in one place (`mise.toml`)
* Good, because `jdx/mise-action` handles mise installation and caching
* Good, because markdown and terraform lint jobs run in parallel
* Neutral, because `tofu validate` requires a dummy `state_passphrase` in CI since the encryption block references a variable
* Bad, because adding a new lint task to `mise.toml` may also require updating the workflow if it needs different tools installed

### Confirmation

A push to `main` or a pull request triggers the workflow.
Both the **Markdown** and **Terraform** jobs must pass.

## Pros and Cons of the Options

### GitHub Actions with mise

Reuse `mise.toml` for tool versions and `mise run` for tasks inside GitHub Actions.

* Good, because single source of truth for tool versions
* Good, because native GitHub integration (status checks, PR annotations)
* Good, because `jdx/mise-action` provides caching out of the box
* Neutral, because requires `jdx/mise-action` as a third-party action

### GitHub Actions with pinned tool versions

Install each tool manually in the workflow with explicit version pins.

* Good, because no dependency on mise in CI
* Bad, because tool versions must be maintained in two places
* Bad, because lint commands must be duplicated rather than calling `mise run`

### Third-party CI service

Use an external CI provider instead of GitHub Actions.

* Good, because decoupled from GitHub
* Bad, because adds operational complexity for a single-person homelab
* Bad, because requires additional account and configuration

## More Information

* Workflow file: `.github/workflows/lint.yml`
* Local hooks: [ADR-0011](0011-use-lefthook-for-pre-commit-linting.md)
* Tool management: [ADR-0006](0006-use-mise-for-tool-version-management.md)
