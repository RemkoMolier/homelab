---
name: decide
description: Capture a project decision as a MADR, or scan recent changes for undocumented decisions. Use when a significant choice has been made or to review what decisions may be missing.
argument-hint: "[decision topic] or 'scan' to review recent changes"
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

# Decision Capture Skill

You help capture project decisions as Markdown Architectural Decision Records (MADRs) in `docs/decisions/`.

## Determine Mode

Based on `$ARGUMENTS`:

- **If a topic is provided** (e.g., `/decide use Tailscale for remote access`): go to **Capture Mode**
- **If "scan" is provided** (e.g., `/decide scan`): go to **Scan Mode**
- **If empty or unclear**: ask the user whether they want to capture a specific decision or scan for undocumented ones

---

## Capture Mode

### Step 1: Gather Context

If you already have context from the current conversation (e.g., from a `/research` session), use it. Otherwise, interview the user:

1. Read existing ADRs in `docs/decisions/` to understand what's already documented
2. Ask the user focused questions using `AskUserQuestion`:
   - What problem does this decision address?
   - What options were considered?
   - Why was this option chosen over the others?
   - What are the consequences (good and bad)?
3. Keep it conversational — 2-3 questions max per round, 1-2 rounds total
4. If the decision is straightforward, a single round may suffice

### Step 2: Determine the Next ADR Number

Read `docs/decisions/README.md` to find the highest existing ADR number. The new ADR is that number + 1, zero-padded to 4 digits.

### Step 3: Draft the ADR

Read `docs/decisions/TEMPLATE.md` for the format. Write the ADR following MADR 4.0.0 structure:

- **Frontmatter**: status (usually `accepted`), date, decision-makers
- **Context and Problem Statement**: clear, concise problem framing
- **Decision Drivers** (include if there are notable constraints or forces)
- **Considered Options**: list all options that were evaluated
- **Decision Outcome**: chosen option with clear justification
- **Consequences**: both positive and negative impacts
- **Confirmation** (include if there's a concrete way to verify the decision)
- **Pros and Cons of the Options** (include for decisions where the comparison matters)
- **More Information** (include if there are useful links or context)

Use optional sections when they add value — skip them when they don't. Write in clear, direct prose. The audience is future developers, AI agents, and the future version of the person who made the decision.

### Step 4: Write and Index

1. Write the ADR to `docs/decisions/NNNN-slug.md` (derive slug from title, lowercase, hyphens)
2. Update the index table in `docs/decisions/README.md` with the new entry
3. Show the user the result

---

## Scan Mode

### Step 1: Review Recent Changes

Use git to find recent changes that may contain undocumented decisions:

```bash
git log --oneline -20
git diff HEAD~10..HEAD --stat
```

Also read `docs/decisions/README.md` to know what's already captured.

### Step 2: Identify Decision-Worthy Changes

Look for patterns that suggest a decision was made:

- New tools, services, or dependencies added
- Configuration choices (e.g., picked one approach over alternatives)
- Structural changes (directory layout, naming conventions)
- Removed or replaced components
- New infrastructure or platform choices

### Step 3: Present Findings

Use `AskUserQuestion` to present potential undocumented decisions:

- List what you found with brief context
- Let the user select which ones are worth capturing
- For each selected decision, run Capture Mode

---

## Writing Guidelines

- **Be the better writer**: Draft well-structured prose — the user confirms, not composes
- **Context matters most**: Future readers need to understand *why*, not just *what*
- **Name alternatives honestly**: Don't strawman rejected options
- **Consequences are bilateral**: Always include both good and bad outcomes
- **Link to related ADRs**: If this decision relates to or supersedes another, reference it
- **Keep it scannable**: Short paragraphs, bullet points for lists, tables for comparisons
