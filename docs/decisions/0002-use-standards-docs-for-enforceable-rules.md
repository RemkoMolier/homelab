---
status: "accepted"
date: "2026-04-03"
decision-makers: "Remko Molier"
consulted: ""
informed: ""
---

# Use separate standards documents for enforceable rules

## Context and Problem Statement

The homelab repository uses MADRs to capture architectural decisions and their rationale.
However, decisions describe *why* a choice was made — they don't prescribe the normative rules that follow from that choice.
Where should enforceable rules (naming conventions, security baselines, configuration patterns) be documented so that both humans and agents can follow and tooling can validate against them?

## Decision Drivers

* Standards need to be precise and unambiguous — testable by linters, CI, and agent instructions
* Decisions (ADRs) are point-in-time records; standards are living documents that evolve
* Agents need clear, machine-readable rules to follow during implementation
* The relationship between "why we decided" and "what to do" should be traceable

## Considered Options

* Embed standards in ADR "Consequences" sections
* Use a different ADR status or template variant for standards
* Separate `docs/standards/` directory with its own template

## Decision Outcome

Chosen option: "Separate `docs/standards/` directory with its own template", because standards have a different lifecycle (living, updatable) than decisions (point-in-time), and a purpose-built template with scope, enforcement method, and pass/fail examples is better suited for machine-enforceable rules than the MADR format.

### Consequences

* Good, because standards can evolve independently without rewriting decision records
* Good, because the template enforces precision (scope, examples, enforcement method)
* Good, because standards can link back to their parent decision via frontmatter
* Good, because agents and tooling get unambiguous rules to validate against
* Bad, because two documentation types to maintain instead of one
* Neutral, because not every standard needs a parent ADR — obvious rules can stand alone

### Confirmation

A standard document exists in `docs/standards/` with accepted status.
The template includes scope, enforcement method, and compliant/non-compliant examples.
