---
status: "accepted"
date: "2026-04-03"
decision-makers: "Remko Molier"
consulted: ""
informed: ""
---

# Use SRE-style runbooks for operational procedures

## Context and Problem Statement

As the homelab grows, operational knowledge — how to respond to incidents, perform maintenance, and onboard new users — needs to be captured somewhere.
Without structured runbooks, this knowledge lives only in the operator's head and is lost under stress or after time away.
How should operational procedures be documented?

## Decision Drivers

* Runbooks must be usable under stress (incidents, late-night alerts)
* Procedures need enough context for diagnosis, not just resolution steps
* The primary audience is Remko, but others should be able to follow them for onboarding
* Documentation should be version-controlled alongside infrastructure code
* The format should be consistent with the existing MADR and standards approach (Markdown + YAML frontmatter)

## Considered Options

* Checklist-only runbooks
* SRE-style runbooks with diagnosis context
* Wiki-based documentation (external to the repo)

## Decision Outcome

Chosen option: "SRE-style runbooks with diagnosis context", because incident response requires understanding *what's wrong* before acting, and checklists alone don't provide enough context for diagnosis or rollback under stress.

### Consequences

* Good, because symptoms and diagnosis sections help identify the right runbook and confirm the problem before acting
* Good, because rollback and escalation sections reduce risk during incidents
* Good, because `last-verified` frontmatter field encourages periodic review
* Good, because post-incident notes capture learnings for future use
* Bad, because SRE-style templates are heavier to write than simple checklists
* Neutral, because optional sections (escalation, post-incident notes) can be skipped for simple procedures

### Confirmation

Runbook documents exist in `docs/runbooks/` following the SRE-style template with symptoms, diagnosis, resolution, rollback, and escalation sections.

## Pros and Cons of the Options

### Checklist-only runbooks

Short, action-oriented checklists: step, expected result, next step.

* Good, because fast to write and easy to follow
* Good, because low maintenance burden
* Bad, because no diagnosis context — assumes you already know the problem
* Bad, because no rollback guidance when a step goes wrong

### SRE-style runbooks with diagnosis context

Includes symptoms, diagnosis steps, resolution actions, rollback, escalation paths, and post-incident notes.

* Good, because supports the full incident lifecycle
* Good, because symptoms section helps route to the right runbook
* Bad, because more effort to write and maintain
* Neutral, because heavier template — but optional sections keep it flexible

### Wiki-based documentation

External wiki (e.g., Notion, Confluence, GitHub Wiki) for procedures.

* Good, because rich editing experience
* Bad, because not version-controlled with the infrastructure code
* Bad, because breaks the docs-as-code pattern established by MADRs and standards
* Bad, because external dependency for critical operational knowledge
