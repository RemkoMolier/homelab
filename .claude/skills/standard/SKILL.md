---
name: standard
description: Capture an enforceable standard, or scan decisions for missing standards. Use when a rule needs to be documented for humans, agents, and tooling to follow.
argument-hint: "[standard topic] or 'scan' to find decisions without standards"
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
  - Agent
---

# Standard Capture Skill

You help capture enforceable standards in `docs/standards/`. Standards define the **what** — normative rules that implement decisions. They must be precise enough for tooling and agents to validate against.

## Determine Mode

Based on `$ARGUMENTS`:

- **If a topic is provided** (e.g., `/standard markdown style guide`): go to **Capture Mode**
- **If "scan" is provided** (e.g., `/standard scan`): go to **Scan Mode**
- **If empty or unclear**: ask the user whether they want to capture a specific standard or scan for gaps

---

## Capture Mode

### Step 1: Gather Context

If you already have context from the current conversation (e.g., from a `/decide` or `/research` session), use it. Otherwise:

1. Read existing standards in `docs/standards/` to understand what's already documented
2. Read existing ADRs in `docs/decisions/` to find related decisions
3. Ask the user focused questions using `AskUserQuestion`:
   - What is the rule? (State it as a testable requirement)
   - What does it apply to? (Files, resources, services, environments)
   - Is there a parent decision that explains why this rule exists?
   - How is it enforced? (Linter, CI check, hook, agent instruction, manual)
4. Keep it to 1-2 rounds of questions

### Step 2: Draft the Standard

Read `docs/standards/TEMPLATE.md` for the format. Write the standard with:

- **Frontmatter**: status, date, parent decision reference, scope, enforcement method
- **Rule**: unambiguous, testable statements — no "should consider" or "where possible"
- **Rationale**: brief why (link to ADR for full context)
- **Scope**: what this applies to
- **Examples**: compliant and non-compliant usage (concrete, not hypothetical)
- **Enforcement**: which tool checks this, or "manual" if not yet automated
- **Exceptions**: any known exceptions, or "None."

### Step 3: Write and Index

1. Write the standard to `docs/standards/{kebab-case-name}.md`
2. Update the index table in `docs/standards/README.md` with the new entry
3. Show the user the result

---

## Scan Mode

### Step 1: Inventory

Read all existing ADRs in `docs/decisions/` and all existing standards in `docs/standards/`.

### Step 2: Identify Gaps

Look for accepted decisions that imply enforceable rules but lack a corresponding standard:

- Decisions about conventions, naming, formatting, or structure
- Decisions about security policies or baselines
- Decisions about required tooling, configurations, or patterns
- Decisions with "Consequences" that describe things that "must" or "should" happen

Also check for standards that reference non-existent or deprecated decisions.

### Step 3: Present Findings

Use `AskUserQuestion` to present gaps:

- List decisions that likely need standards, with brief reasoning
- Let the user select which ones to capture
- For each selected gap, run Capture Mode

---

## Writing Guidelines

- **Rules, not guidelines**: every statement in the Rule section must be testable — either compliant or not
- **Concrete examples**: show real file paths, real config snippets, real naming patterns
- **Scope precisely**: "all Markdown files in docs/" is better than "documentation"
- **Name the enforcer**: if a linter or hook checks this, say which one and where it's configured
- **Link to decisions**: use the `decision` frontmatter field to connect the why to the what
- **Keep it short**: a standard that takes 5 minutes to read won't be followed
