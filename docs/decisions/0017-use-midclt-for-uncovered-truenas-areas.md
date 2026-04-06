---
status: accepted
date: 2026-04-06
decision-makers: Remko Molier
---

# Use midclt for TrueNAS configuration areas not covered by arensb.truenas

## Context and Problem Statement

The `arensb.truenas` Ansible collection provides 18 modules for TrueNAS SCALE, but several configuration areas have no corresponding module: UPS, cloud sync, network interfaces, Docker/app config, GUI certificate assignment, and system settings like timezone and NTP.
How should these gaps be filled?

## Decision Drivers

- The uncovered areas are stable, rarely-changed configuration
- Maintaining custom Ansible modules adds ongoing development burden
- The `midclt` CLI is TrueNAS's official tool for interacting with middlewared
- The `arensb.truenas` collection already connects via SSH, so `midclt` is available on the target

## Considered Options

- Raw `midclt call` tasks via `ansible.builtin.command`
- Custom Ansible modules wrapping the TrueNAS Python API client
- Wait for upstream collection to add modules

## Decision Outcome

Chosen option: "Raw `midclt call` tasks", because these configuration areas change infrequently, the `midclt` CLI is stable and well-documented, and building custom modules would add maintenance overhead disproportionate to the benefit.

### Pattern

Each `midclt` task should follow this pattern for idempotency:

1. Query the current state with `midclt call <service>.config` or `<service>.query`
2. Compare with desired state
3. Only call `<service>.update` or `<service>.create` when changes are needed
4. Use `changed_when` and `failed_when` to report correct status

### Consequences

- Good, because no custom code to maintain — uses TrueNAS's own CLI
- Good, because covers 100% of the TrueNAS API surface
- Good, because can be implemented immediately without waiting for upstream
- Bad, because `midclt` tasks lack the declarative feel of native Ansible modules
- Bad, because idempotency must be implemented manually per task
- Neutral, because if `arensb.truenas` adds modules later, tasks can be migrated incrementally

### Confirmation

`midclt` tasks produce correct `changed`/`ok` status when run twice in a row.
Tasks with `changed_when: false` do not report spurious changes.

## Pros and Cons of the Options

### Raw midclt call tasks

Use `ansible.builtin.command` to run `midclt call` on the TrueNAS host.

- Good, because zero additional code or dependencies
- Good, because `midclt` is the same tool the TrueNAS UI uses internally
- Good, because any TrueNAS API endpoint is accessible
- Bad, because manual idempotency logic per task
- Bad, because no automatic `--check` / `--diff` mode support

### Custom Ansible modules

Write Python modules using the `truenas_api_client` library.

- Good, because full Ansible integration (check mode, diff, idempotency)
- Good, because cleaner playbook syntax
- Bad, because significant development and testing effort
- Bad, because must track TrueNAS API changes across versions
- Bad, because disproportionate to the frequency of changes in these areas

### Wait for upstream

Wait for `arensb.truenas` to add modules for missing areas.

- Good, because no work required
- Bad, because no timeline — open PRs for UPS (#52) and apps (#32) have been pending for months
- Bad, because blocks automation for these areas indefinitely

## More Information

- [ADR-0008](0008-split-tooling-opentofu-and-ansible.md) — Ansible chosen for TrueNAS management
- [arensb/ansible-truenas](https://github.com/arensb/ansible-truenas) — the collection and its module coverage
- [TrueNAS midclt documentation](https://www.truenas.com/docs/scale/25.10/api/) — API reference
