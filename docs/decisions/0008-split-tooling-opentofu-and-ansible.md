---
status: accepted
date: 2026-04-03
decision-makers: Remko Molier
---

# Use OpenTofu for network devices and Ansible for TrueNAS

## Context and Problem Statement

The homelab has two categories of infrastructure to manage: network devices (MikroTik, Horaco) and storage (TrueNAS SCALE).
Should we use a single IaC tool for everything, or pick the best tool for each target?

## Decision Drivers

- TrueNAS SCALE is deprecating its REST API in 25.04, replacing it with a WebSocket JSON-RPC 2.0 API — all existing Terraform providers are archived or broken
- MikroTik has an excellent Terraform provider (terraform-provider-routeros, 337★, actively maintained)
- The chosen tools must have a viable path forward as APIs evolve
- Minimizing tool count is desirable but not at the cost of using a broken provider

## Considered Options

- OpenTofu for network devices + Ansible for TrueNAS
- Ansible for everything
- OpenTofu for everything

## Decision Outcome

Chosen option: "OpenTofu for network devices + Ansible for TrueNAS", because the tooling landscape forces this split.
MikroTik and Horaco have mature Terraform providers, making OpenTofu the natural fit for declarative network management.
TrueNAS has no viable Terraform provider post-25.04, but the arensb.truenas Ansible collection already uses the WebSocket API and survives the transition.

### Consequences

- Good, because each tool is used where it has the strongest provider support
- Good, because arensb.truenas already uses WebSocket API — future-proof against the REST deprecation
- Good, because terraform-provider-routeros has near-complete RouterOS resource coverage
- Bad, because two IaC tools to learn and maintain instead of one
- Neutral, because the tools have different mental models (declarative state vs procedural playbooks), which adds cognitive load but also means each is used in its natural mode

### Confirmation

OpenTofu manages MikroTik and Horaco devices via `tofu plan` / `tofu apply`.
Ansible manages TrueNAS SCALE via `ansible-playbook` with the arensb.truenas collection.
Both tools run from the same repository with shared secrets management.

## Pros and Cons of the Options

### OpenTofu for network + Ansible for TrueNAS

Use each tool where its provider ecosystem is strongest.

- Good, because best provider support for each target
- Good, because Ansible's arensb.truenas collection is WebSocket-ready
- Good, because OpenTofu's routeros provider is the most mature network device provider available
- Bad, because two tools to maintain

### Ansible for everything

Use community.routeros for MikroTik and arensb.truenas for TrueNAS.

- Good, because single tool for all infrastructure
- Good, because community.routeros is a mature, official Ansible collection
- Bad, because Ansible is more procedural than declarative for network state management
- Bad, because no Ansible equivalent for the Horaco switches (terraform-provider-hrui has no Ansible counterpart)

### OpenTofu for everything

Use terraform-provider-routeros for MikroTik, terraform-provider-hrui for Horaco, and a TrueNAS provider.

- Good, because single declarative tool
- Bad, because all TrueNAS Terraform providers are archived or broken after the REST→WebSocket API transition
- Bad, because no viable path forward for TrueNAS management

## More Information

- [terraform-provider-routeros](https://github.com/terraform-routeros/terraform-provider-routeros) — MikroTik provider (337★, v1.99, RouterOS 7.x)
- [terraform-provider-hrui](https://github.com/brennoo/terraform-provider-hrui) — Horaco switch provider (53★, web UI scraping)
- [arensb/ansible-truenas](https://github.com/arensb/ansible-truenas) — TrueNAS Ansible collection (95★, WebSocket-ready)
- [community.routeros](https://github.com/ansible-collections/community.routeros) — MikroTik Ansible collection (136★)
- [TrueNAS API transition](https://www.truenas.com/docs/scale/api/) — REST deprecated in 25.04, removed in 26.04
