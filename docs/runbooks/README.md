# Runbooks

Operational procedures for running the homelab.
Runbooks capture the **how** — step-by-step instructions for operations, incident response, and onboarding.

## Runbook types

- **Operations** — day-to-day tasks (backups, upgrades, service restarts)
- **Recovery** — incident response and disaster recovery procedures
- **Onboarding** — guides for understanding and operating the homelab

## How to add a runbook

1. Copy `TEMPLATE.md` and fill it in
2. Use a descriptive kebab-case filename (e.g., `disk-full-nas.md`)
3. Add it to the index below
4. Set `last-verified` to today's date

## Keeping runbooks current

The `last-verified` field in each runbook's frontmatter tracks when it was last confirmed accurate.
When you use a runbook, update this date and add post-incident notes if applicable.

## Index

| Runbook | Type | Severity | Owner | Last Verified |
| --------- | ------ | ---------- | ------- | --------------- |
| [Bootstrap MikroTik device](bootstrap-mikrotik-device.md) | Onboarding | Medium | Remko Molier | 2026-04-03 |
| [PKI operations](pki-operations.md) | Operations | High | Remko Molier | 2026-04-03 |
| [git-crypt onboarding](git-crypt-onboarding.md) | Onboarding | Medium | Remko Molier | 2026-04-03 |
| [Switch-chip VLAN operations](switch-chip-vlan-operations.md) | Operations | Medium | Remko Molier | 2026-04-04 |
| [Terraform state recovery](terraform-state-recovery.md) | Recovery | Critical | Remko Molier | 2026-04-04 |
