---
name: runbook
description: Capture an operational runbook, or scan for services and procedures that lack runbooks. Use when a procedure needs to be documented for operations, incident response, or onboarding.
argument-hint: "[runbook topic] or 'scan' to find gaps"
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

# Runbook Capture Skill

You help capture operational runbooks in `docs/runbooks/`. Runbooks define the **how** — step-by-step procedures for operations, incident response, and onboarding.

## Determine Mode

Based on `$ARGUMENTS`:

- **If a topic is provided** (e.g., `/runbook disk full on nas`): go to **Capture Mode**
- **If "scan" is provided** (e.g., `/runbook scan`): go to **Scan Mode**
- **If empty or unclear**: ask the user whether they want to capture a specific runbook or scan for gaps

---

## Capture Mode

### Step 1: Gather Context

If you already have context from the current conversation (e.g., from a recent incident or setup task), use it. Otherwise:

1. Read existing runbooks in `docs/runbooks/` to understand what's already documented
2. Ask the user focused questions using `AskUserQuestion`:
   - What situation or task does this runbook cover?
   - What symptoms or triggers indicate this runbook is needed?
   - What are the resolution steps? (Walk through them in order)
   - What could go wrong, and how do you roll back?
   - Is there an escalation path if this doesn't resolve the issue?
3. Keep it to 1-2 rounds of questions
4. If the user just completed a task or resolved an incident, extract the steps from the conversation

### Step 2: Determine Runbook Type

Classify the runbook:

- **Operations**: routine tasks (backups, upgrades, restarts, provisioning)
- **Recovery**: incident response and disaster recovery
- **Onboarding**: guides for understanding and operating a system

### Step 3: Draft the Runbook

Read `docs/runbooks/TEMPLATE.md` for the format. Write the runbook with:

- **Frontmatter**: title, owner, last-verified (today), severity, related runbooks
- **Overview**: when to use this runbook (1-2 sentences)
- **Symptoms**: observable signs that point to this runbook
- **Prerequisites**: access, tools, credentials needed
- **Diagnosis**: steps to confirm the problem before acting, with expected results
- **Resolution**: step-by-step actions with expected results after each step
- **Rollback**: how to undo if something goes wrong
- **Escalation**: what to do if this runbook doesn't resolve the issue
- **Post-incident notes**: empty table for future use

For simple operations runbooks, the Symptoms and Diagnosis sections can be brief or combined. For incident response runbooks, these sections should be thorough.

### Step 4: Write and Index

1. Write the runbook to `docs/runbooks/{kebab-case-name}.md`
2. Update the index table in `docs/runbooks/README.md` with the new entry
3. Show the user the result

---

## Scan Mode

### Step 1: Inventory

1. Read all existing runbooks in `docs/runbooks/`
2. Scan the repository for infrastructure code, service definitions, and configuration:
   - Look for services, applications, and infrastructure components
   - Check for deployment configs, docker-compose files, Kubernetes manifests, Ansible playbooks
   - Identify critical systems (networking, storage, auth, backups)

### Step 2: Identify Gaps

Look for:

- Services or components without any associated runbook
- Common operational tasks that aren't documented (backup, restore, upgrade, restart)
- Incident scenarios for critical systems without recovery runbooks
- Onboarding gaps — would someone new know how to operate this?

### Step 3: Present Findings

Use `AskUserQuestion` to present gaps:

- List services or scenarios that likely need runbooks, with brief reasoning
- Prioritize by severity: critical systems and incident recovery first
- Let the user select which ones to capture
- For each selected gap, run Capture Mode

---

## Writing Guidelines

- **Stress-proof**: write for someone at 2am with an alert firing — short sentences, clear steps
- **Expected results**: after every action step, state what the operator should see if it worked
- **One step, one action**: don't combine multiple commands in a single step
- **Copy-pasteable commands**: use actual commands, not pseudocode — include the full command with realistic paths and arguments
- **Diagnosis before action**: always confirm the problem before applying a fix
- **Rollback is mandatory**: every resolution must have an undo path, even if it's "restore from backup"
- **Keep it current**: set `last-verified` to today's date when writing or updating
- **Link related runbooks**: if diagnosis reveals a different problem, point to the right runbook
