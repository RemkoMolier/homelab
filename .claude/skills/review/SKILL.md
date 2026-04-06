---
name: review
description: Comprehensive code review of a PR or working tree changes. Posts inline comments to PRs; discusses findings conversationally when run locally.
argument-hint: "[PR number | 'working' | empty for auto-detect]"
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
---

# Code Review Skill

You perform thorough, actionable code reviews.
Your goal is to catch real problems — not to generate noise.

## Mode Detection

Determine the review target from `$ARGUMENTS`:

- **PR number** (e.g., `42`): Review that GitHub PR. Post findings as a GitHub review with inline comments.
- **`working`** or empty with uncommitted changes: Review the working tree diff. Discuss findings conversationally with the user.
- **Empty with clean tree**: Check for an open PR on the current branch. If found, review it. Otherwise, tell the user there's nothing to review.

## Context Gathering

Before reviewing any code, build context so you can distinguish intentional choices from mistakes:

1. Read `CLAUDE.md` for project conventions, architecture, and commit discipline
2. Read `docs/decisions/README.md` to understand existing ADRs — do not contradict accepted decisions
3. Read `docs/standards/` for enforceable rules
4. Check the file types being changed to understand the domain (Terraform, Ansible, markdown, scripts, etc.)

## Gathering the Diff

### PR mode

```bash
gh pr diff <number>
gh pr view <number> --json title,body,files,baseRefName,headRefName
```

### Working tree mode

```bash
git diff
git diff --cached
git status --short
```

## Review Process

### Step 1: Understand the Change

Before looking for problems, understand what the change does and why:

- Read the PR description or commit messages
- Identify the intent: new feature, bug fix, refactoring, config change, docs update
- Note which components are affected

### Step 2: Read Changed Files in Full

Do not review the diff in isolation. For each changed file, read the full file to understand surrounding context.
Use the `Agent` tool with `subagent_type: Explore` for larger changes spanning many files.

### Step 3: Check Each Category

Review the changes against these categories, ordered by importance.
Skip categories that don't apply to the change (e.g., skip "Performance" for a docs-only PR).

#### Critical — Must fix before merge

- **Security**: Hardcoded secrets, credentials in plaintext, injection vulnerabilities, overly permissive permissions, missing input validation, sensitive data in logs
- **Secrets exposure**: Values that should be SOPS-encrypted but aren't, git-crypt patterns not covering new key files, secrets in non-encrypted state
- **Breaking changes**: Destructive resource changes in Terraform (forces replacement), backwards-incompatible API changes, removed functionality without deprecation
- **Data loss risk**: Missing backups before destructive operations, unprotected state files, irreversible migrations

#### High — Should fix

- **Bugs and logic errors**: Off-by-one errors, null/empty handling, race conditions, unhandled edge cases, incorrect conditionals
- **Error handling**: Missing error checks, swallowed errors, unhelpful error messages, missing rollback on failure
- **IaC state concerns**: Unintended resource destruction (check plan implications), missing lifecycle blocks, state drift risk, missing depends_on
- **Idempotency** (Ansible): Tasks that aren't idempotent, missing `changed_when`/`failed_when` on command tasks, `no_log: true` missing on sensitive tasks

#### Medium — Recommended

- **Complexity**: Functions doing too many things, deeply nested logic, code that requires extensive comments to understand
- **Missing tests**: New functionality without tests, changed behavior without updated tests
- **Documentation gaps**: Public APIs without docs, complex logic without explaining comments, missing ADR for significant decisions
- **Naming**: Misleading names, inconsistent conventions, abbreviations that harm readability

#### Low — Suggestions

- **Style**: Formatting inconsistencies not caught by linters, minor readability improvements
- **Performance**: Minor optimizations, unnecessary allocations (only flag if measurably impactful)
- **Simplification**: Code that could be simpler without changing behavior

### Step 4: IaC-Specific Checks

Apply these when reviewing Terraform, Ansible, or SOPS files:

**Terraform:**

- Variables have descriptions and type constraints
- Resources follow naming conventions
- Provider versions are constrained
- Sensitive values marked with `sensitive = true`
- No hardcoded values that should be variables
- Module structure is clean (not mixing concerns)

**Ansible:**

- Tasks have descriptive names
- Fully qualified collection names (FQCNs) used
- `no_log: true` on tasks handling passwords, keys, or tokens
- Command/shell tasks have `changed_when` / `failed_when`
- Variables follow naming conventions

**SOPS:**

- Values under `secrets` keys are actually ENC[...] blobs
- `.sops.yaml` creation rules match new file patterns
- New secret files are covered by encryption

**Markdown:**

- Semantic line breaks (one sentence per line) per ADR-0004
- Links are valid
- Tables are properly formatted

### Step 5: Check Commit Discipline

If reviewing a PR with multiple commits:

- Each commit should be one logical change (ADR-0005)
- Commit messages follow conventional format
- No "fix typo" or "oops" commits that should be squashed
- Each commit leaves the repo in a valid state

## Output Format

### PR Mode — Post GitHub Review

Use `gh api` to create a review with inline comments.
Structure the review body as a summary, then post individual comments on specific lines.

**Review body (summary comment):**

```markdown
## Review Summary

[1-2 sentence description of what the PR does]

### Findings

[Only list categories that have findings]

**Critical** (N)
- Brief description of each critical finding

**High** (N)
- Brief description of each high finding

**Medium** (N)
- Brief description of each medium finding

[Omit empty categories entirely]

### What's Done Well
- [Briefly note 1-2 positive aspects, if any stand out — do not force this]
```

**Inline comments:**

Each comment should include:

- Severity tag: `**[Critical]**`, `**[High]**`, `**[Medium]**`, or `**[Low]**`
- Category: `Security`, `Bug`, `Error Handling`, `IaC`, `Complexity`, `Style`, etc.
- Clear description of the issue
- Why it matters (impact)
- Suggested fix (code block when possible)

Example:

```text
**[High]** Error Handling — This `midclt call` task has no `failed_when` condition.
If the API returns an error, Ansible will report success because the command itself exited 0.

Suggested fix:
  failed_when: result.rc != 0 or 'error' in result.stderr
```

**Posting the review:**

```bash
# Collect all comments into a JSON array, then post as a single review
gh api repos/{owner}/{repo}/pulls/{number}/reviews \
  -f event=COMMENT \
  -f body="<summary>" \
  -f 'comments=[{"path":"file.tf","line":42,"body":"comment text"}]'
```

Use `COMMENT` event (not `REQUEST_CHANGES` or `APPROVE`) — leave merge decisions to the human.

### Working Tree Mode — Conversational

Present findings directly in the conversation, grouped by severity.
Use the same category tags and structure, but in markdown.
After presenting findings, ask the user if they want to fix any of them.

## Behavioral Rules

### Stay Silent When Code is Fine

If the change is clean and well-written, say so briefly and stop.
Do not invent concerns to appear thorough.
A review with zero findings is a valid review.

### Limit Noise

- Target ~5 high-signal comments per review, never more than 10
- Cluster repeated patterns into a single comment (e.g., "These 4 tasks all need `no_log: true`")
- Do not flag issues that linters already catch (formatting, trailing whitespace)
- Do not suggest refactoring that isn't related to the change

### Be Actionable

- Every finding must include a suggested fix or clear next step
- Provide code snippets for fixes when possible
- Reference specific project standards or ADRs when applicable

### Respect Project Context

- Do not contradict accepted ADRs
- Do not suggest tools or patterns the project has deliberately avoided
- Match the project's style — don't impose external conventions
- Understand that IaC repos have different concerns than application repos

### Do Not Review Generated or Encrypted Content

- Skip SOPS-encrypted values (ENC[...] blobs) — only check that they ARE encrypted
- Skip lock files (.terraform.lock.hcl) — these are generated
- Skip state files (terraform.tfstate) — encrypted and managed by OpenTofu
- Skip git-crypt encrypted files — binary blobs when locked
