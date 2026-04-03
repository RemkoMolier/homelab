---
status: accepted
date: 2026-04-03
decision-makers: Remko Molier
---

# Use MADRs for decision documentation

## Context and Problem Statement

As the homelab project grows, decisions about technology, architecture, and process need to be recorded so that future contributors, AI agents, and the future version of the decision-maker can understand *why* things were built a certain way.
Without a structured approach, decisions scatter across git history, conversations, and memory — making them hard to find and easy to contradict.

## Decision Drivers

* Decisions must be readable by humans, AI coding agents, and future contributors equally
* The format should be plain markdown stored in the repository — no external tools or platforms required
* Recording decisions should be low-friction, ideally assisted by AI agents during working sessions
* The format should be an established standard with community adoption, not a custom invention

## Considered Options

* MADR 4.0.0 (Markdown Architectural Decision Records)
* Nygard minimal ADR (Context / Decision / Consequences)
* Single-file decision log (one DECISIONS.md table)
* Inline code comments only

## Decision Outcome

Chosen option: "MADR 4.0.0", because it provides the right balance of structure and flexibility.
The format is an established standard with community adoption, supports optional sections that can be skipped for simpler decisions, and its structured headings make it easy for AI agents to parse and reference.
The template lives in the repo, making it self-documenting.

### Consequences

* Good, because decisions are versioned alongside the code they describe
* Good, because AI agents can read existing ADRs before proposing approaches, reducing contradictory suggestions
* Good, because the MADR format is well-known and documented, lowering the barrier for contributors
* Good, because optional sections (Decision Drivers, Pros/Cons, Confirmation) allow scaling detail to the decision's importance
* Bad, because it requires discipline to keep ADRs up-to-date as decisions are superseded
* Neutral, because AI-assisted capture reduces but does not eliminate the effort of writing ADRs

### Confirmation

The decision is confirmed when: the template exists in `docs/decisions/TEMPLATE.md`, the CLAUDE.md and AGENTS.md files instruct agents to check and write ADRs, and the `/decide` skill is functional.

## Pros and Cons of the Options

### MADR 4.0.0

The structured MADR format with YAML frontmatter, optional sections, and a focus on considered options.

* Good, because established standard with active maintenance and community adoption
* Good, because structured sections are easy for AI agents to parse
* Good, because optional sections allow lightweight use for simple decisions
* Neutral, because the full template may be more than needed for trivial choices — but those should be skipped entirely

### Nygard minimal ADR

The original ADR format: Context, Decision, Consequences.

* Good, because extremely simple and quick to write
* Bad, because no structured place for alternatives considered — which is critical context for understanding *why*

### Single-file decision log

One `DECISIONS.md` with a table of date, decision, rationale, status.

* Good, because zero overhead — just append a row
* Bad, because no room for context, alternatives, or consequences
* Bad, because becomes unwieldy past ~30 entries

### Inline code comments

Document decisions as comments in the configuration files they affect.

* Good, because context is right where it's used
* Bad, because decisions that span multiple files have no single home
* Bad, because difficult to get an overview of all decisions made

## More Information

* [MADR 4.0.0 specification](https://adr.github.io/madr/)
* [Michael Nygard's original ADR post](https://www.cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
* [AGENTS.md specification](https://agents.md/) — cross-tool AI agent instruction standard
