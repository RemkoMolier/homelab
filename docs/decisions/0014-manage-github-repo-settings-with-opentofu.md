---
status: accepted
date: 2026-04-06
decision-makers: Remko Molier
---

# Manage GitHub repository settings with OpenTofu

## Context and Problem Statement

Enabling GitHub secret scanning and other repository security settings requires configuration in the GitHub UI.
These settings are invisible in the codebase and can drift without notice.
How should GitHub repository settings be managed?

## Decision Drivers

- Repository settings (secret scanning, branch protection) should be version-controlled
- Must be consistent with the existing IaC approach (OpenTofu for declarative config)
- Should not require a separate tool or workflow
- The `integrations/github` OpenTofu provider is mature and actively maintained

## Considered Options

- OpenTofu with the `integrations/github` provider
- Shell script using `gh api` commands
- Manual configuration via GitHub UI

## Decision Outcome

Chosen option: "OpenTofu with the `integrations/github` provider", because it follows the existing declarative IaC pattern, keeps GitHub config versioned alongside infrastructure, and uses a well-maintained provider.

Configuration lives in `terraform/github/` as a separate OpenTofu root module, independent of the `terraform/routeros/` network config.

### Consequences

- Good, because GitHub settings are version-controlled and auditable
- Good, because changes go through the same review process as infrastructure changes
- Good, because consistent tooling — same `tofu plan`/`tofu apply` workflow
- Good, because drift is detectable via `tofu plan`
- Bad, because requires a GitHub personal access token with repo admin permissions
- Neutral, because separate state from routeros — intentional to avoid coupling

### Confirmation

`tofu plan` in `terraform/github/` shows no drift after initial apply.
Secret scanning is enabled and visible in the repository's Security tab.

## Pros and Cons of the Options

### OpenTofu with integrations/github provider

Declarative Terraform-style configuration for GitHub resources.

- Good, because follows existing IaC patterns in this repo
- Good, because the provider supports repositories, branch protection, actions, and security settings
- Good, because state tracking detects configuration drift
- Bad, because requires managing a GitHub token as a secret
- Bad, because adds a second OpenTofu root module to maintain

### Shell script using gh api

Imperative script calling GitHub's REST API.

- Good, because simpler — no state file or provider to manage
- Good, because `gh` CLI is already available
- Bad, because imperative — no drift detection
- Bad, because scripts must handle idempotency manually

### Manual configuration via GitHub UI

Click through settings in the browser.

- Good, because zero tooling overhead
- Bad, because not version-controlled — invisible to code review
- Bad, because prone to drift — no way to verify settings match intent
- Bad, because not reproducible if the repository is recreated

## More Information

- [integrations/github provider](https://registry.terraform.io/providers/integrations/github/latest/docs)
- [ADR-0007](0007-use-opentofu-for-infrastructure-provisioning.md) — OpenTofu as IaC tool
