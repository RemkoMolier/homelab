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
| [ADR-0006](0006-use-mise-for-tool-version-management.md) | Use mise for tool version management | accepted | 2026-04-03 |
| [ADR-0007](0007-use-opentofu-for-infrastructure-provisioning.md) | Use OpenTofu for infrastructure provisioning | accepted | 2026-04-03 |
| [ADR-0008](0008-split-tooling-opentofu-and-ansible.md) | Use OpenTofu for network devices and Ansible for TrueNAS | accepted | 2026-04-03 |
| [ADR-0009](0009-use-sops-for-secrets-management.md) | Use SOPS for secrets management | accepted | 2026-04-03 |
| [ADR-0010](0010-internal-pki-with-offline-root-ca.md) | Use an internal PKI with an offline root CA | accepted | 2026-04-03 |
| [ADR-0011](0011-use-lefthook-for-pre-commit-linting.md) | Use lefthook for pre-commit linting | accepted | 2026-04-04 |
| [ADR-0012](0012-use-github-actions-for-ci-linting.md) | Use GitHub Actions for CI linting | accepted | 2026-04-06 |
| [ADR-0013](0013-use-gitleaks-for-secret-scanning.md) | Use gitleaks for secret scanning | accepted | 2026-04-06 |
| [ADR-0014](0014-manage-github-repo-settings-with-opentofu.md) | Manage GitHub repo settings with OpenTofu | accepted | 2026-04-06 |
| [ADR-0015](0015-use-renovate-for-dependency-updates.md) | Use Renovate for automated dependency updates | accepted | 2026-04-06 |
