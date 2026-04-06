---
status: accepted
date: 2026-04-06
decision-makers: Remko Molier
---

# Use Renovate for automated dependency updates

## Context and Problem Statement

The repository depends on CLI tools (via mise), OpenTofu providers, Ansible collections, and GitHub Actions.
These dependencies need regular updates for security patches and new features.
How should dependency updates be automated?

## Decision Drivers

- Must cover mise-managed tools, OpenTofu providers, Ansible collections, and GitHub Actions
- Should create PRs automatically with minimal manual intervention
- Must work with the existing CI pipeline (updates should pass lint before merging)
- Should support auto-merge when CI passes

## Considered Options

- Renovate
- Dependabot
- Custom GitHub Actions workflow

## Decision Outcome

Chosen option: "Renovate", because it is the only tool that covers all four dependency types (mise, terraform, ansible-galaxy, github-actions) in a single configuration.

All mise.toml tools are pinned to minor versions (e.g., `opentofu = "1.11"`) to enable meaningful update PRs.
Renovate runs weekly and auto-merges PRs when CI passes.

### Consequences

- Good, because single tool covers all dependency types
- Good, because auto-merge reduces manual toil for a solo developer
- Good, because update PRs provide an audit trail of version changes
- Good, because pinned versions ensure reproducible builds across environments
- Bad, because Renovate's OpenTofu registry support has known hash issues for lock files
- Neutral, because the Renovate GitHub App is free for public repositories

### Confirmation

Renovate creates weekly PRs for outdated dependencies.
PRs pass CI checks and auto-merge without manual intervention.
`mise install` produces the same tool versions locally and in CI.

## Pros and Cons of the Options

### Renovate

Multi-ecosystem dependency update bot with broad manager support.

- Good, because covers mise, terraform, ansible-galaxy, and github-actions
- Good, because free GitHub App, zero infrastructure to maintain
- Good, because highly configurable (grouping, scheduling, auto-merge)
- Bad, because OpenTofu registry hash computation has known issues
- Bad, because adds a third-party app with repository access

### Dependabot

GitHub's built-in dependency update tool.

- Good, because native GitHub integration, zero setup
- Good, because dedicated `opentofu` ecosystem with correct lock file updates
- Bad, because no mise.toml support
- Bad, because no Ansible Galaxy support
- Bad, because two dependency types would remain unmanaged

### Custom GitHub Actions workflow

Scheduled workflow running `mise upgrade --bump`, `tofu init -upgrade`, etc.

- Good, because full control over update logic
- Good, because no third-party app access needed
- Bad, because significant maintenance burden to write and maintain scripts
- Bad, because must handle PR creation, conflict resolution, and auto-merge manually

## More Information

- [Renovate GitHub App](https://github.com/marketplace/renovate)
- [Renovate mise manager](https://docs.renovatebot.com/modules/manager/mise/)
- [Renovate terraform manager](https://docs.renovatebot.com/modules/manager/terraform/)
- [Renovate ansible-galaxy manager](https://docs.renovatebot.com/modules/manager/ansible-galaxy/)
