---
status: accepted
date: 2026-04-03
decision-makers: Remko Molier
---

# Use OpenTofu for infrastructure provisioning

## Context and Problem Statement

The homelab includes network devices (MikroTik routers and switches, Horaco managed switches) that need to be managed declaratively.
Several IaC tools can drive these devices via their APIs.
Which provisioning engine should we use?

## Decision Drivers

- Must support the MikroTik RouterOS provider (terraform-provider-routeros) and the Horaco switch provider (terraform-provider-hrui)
- Should be open-source with an active community
- Should be a well-known tool to build transferable skills
- Provider ecosystem must be compatible with existing Terraform providers

## Considered Options

- OpenTofu
- Terraform (HashiCorp)
- Pulumi

## Decision Outcome

Chosen option: "OpenTofu", because it is a fully compatible open-source fork of Terraform under the Linux Foundation, using the same HCL language and provider ecosystem.
All existing Terraform providers (routeros, hrui) work without modification.

### Consequences

- Good, because open-source license (MPL 2.0) with no usage restrictions
- Good, because full compatibility with the Terraform provider ecosystem
- Good, because community-governed under the Linux Foundation
- Good, because HCL is widely known — documentation and examples are abundant
- Bad, because slightly smaller community than Terraform itself
- Neutral, because migration from OpenTofu to Terraform (or vice versa) is trivial if needed

### Confirmation

`tofu init` succeeds with the routeros and hrui providers.
`tofu plan` runs against live devices and produces a valid execution plan.

## Pros and Cons of the Options

### OpenTofu

Open-source Terraform fork under the Linux Foundation.

- Good, because MPL 2.0 license — no commercial restrictions
- Good, because drop-in replacement for Terraform with identical provider compatibility
- Good, because active development and growing adoption
- Neutral, because smaller community than Terraform, but growing

### Terraform (HashiCorp)

The original IaC tool, now under the Business Source License (BSL).

- Good, because largest community, most documentation and examples
- Good, because mature and battle-tested
- Bad, because BSL license restricts competitive use — philosophically at odds with open-source values
- Neutral, because functionally identical to OpenTofu for this use case

### Pulumi

IaC tool using general-purpose programming languages (Python, TypeScript, Go).

- Good, because real programming languages enable testing, loops, and abstractions
- Good, because Apache 2.0 license
- Bad, because smaller provider ecosystem — MikroTik and Horaco providers may not be available
- Bad, because more complex setup for declarative infrastructure that HCL handles well

## More Information

- [OpenTofu](https://opentofu.org/) — project homepage
- [OpenTofu manifesto](https://opentofu.org/manifesto/) — Linux Foundation governance
- [terraform-provider-routeros](https://github.com/terraform-routeros/terraform-provider-routeros) — MikroTik provider (337★)
- [terraform-provider-hrui](https://github.com/brennoo/terraform-provider-hrui) — Horaco/budget switch provider (53★)
