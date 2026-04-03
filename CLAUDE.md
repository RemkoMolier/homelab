# Homelab

Infrastructure-as-code repository for Remko's homelab.

## Status

This project is in the **discovery phase**.
Run `/research` to continue the structured research and implementation-planning process.

## Setup

Tool versions are managed with [mise](https://mise.jdx.dev/) — see [ADR-0006](docs/decisions/0006-use-mise-for-tool-version-management.md).

- Install mise: `curl https://mise.run | sh`
- Install project tools: `mise install`
- Or run `./setup.sh` to do both (used automatically on Claude web)

## Infrastructure

The repository manages homelab infrastructure with two tools — see [ADR-0008](docs/decisions/0008-split-tooling-opentofu-and-ansible.md):

- **OpenTofu** (`terraform/`) — network device configuration (MikroTik, Horaco switches)
- **Ansible** (`ansible/`) — TrueNAS SCALE configuration

Secrets are encrypted with SOPS using GPG — see [ADR-0009](docs/decisions/0009-use-sops-for-secrets-management.md).
OpenTofu state is encrypted with PBKDF2+AES-GCM and committed to git.

## Conventions

- Prefer declarative configuration over imperative scripts
- Use semantic line breaks in markdown (one sentence per line) — see [ADR-0004](docs/decisions/0004-markdown-quality-standard.md)
- Run `mise exec -- markdownlint-cli2` to check markdown quality (config in `.markdownlint-cli2.yaml`)

### Commit discipline

Make atomic commits with conventional commit labels — see [ADR-0005](docs/decisions/0005-atomic-commits-with-conventional-labels.md).
Use the `/commit` skill to analyze changes and create properly grouped commits.

**Rules:**

1. One logical change per commit — if `git revert` would undo something unrelated, split it
2. One conventional type per commit — if you need two types, split it
3. Separate refactoring from behavior changes
4. Separate formatting from logic changes
5. Tests travel with the code they test
6. Each commit must leave the repo in a buildable state
7. If the message needs "and", split the commit
8. Do not include agent references (e.g., `Co-Authored-By`) in commits unless explicitly asked

**Format:** `<type>[(scope)]: <description>` (imperative mood, lowercase, no period, max 72 chars)

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

**Scopes** (optional): `docs`, `infra`, `config`, `network`, `storage` — expand as components are added

## Documentation

The repository uses three types of documentation in `docs/`:

- **Decisions** (`docs/decisions/`) — MADRs capturing the *why* behind significant choices ([MADR 4.0.0](https://adr.github.io/madr/))
- **Standards** (`docs/standards/`) — Enforceable rules capturing the *what* — normative rules for humans, agents, and tooling
- **Runbooks** (`docs/runbooks/`) — SRE-style operational procedures capturing the *how*

The chain is: **Decision** (why) → **Standard** (what) → **Runbook** (how to operate it)

### Standing rule for agents

When a significant project decision is made during a session — a technology choice, architectural direction, process convention, or trade-off between alternatives — capture it as an ADR:

1. Confirm with the user that the decision is worth recording
2. Draft the ADR following the template in `docs/decisions/TEMPLATE.md`
3. Write it to `docs/decisions/NNNN-slug.md` (next sequential number)
4. Update the index in `docs/decisions/README.md`

A decision is "significant" if it is hard to reverse, affects multiple components, or involves choosing between alternatives.
Skip trivial or easily reversible choices.

Before proposing an approach, check existing ADRs in `docs/decisions/` and standards in `docs/standards/` to avoid contradicting prior decisions or violating existing standards.

## Skills

- `/research [topic]` - Structured research: interviews you, researches the internet, and produces an implementation-ready plan in the conversation
- `/decide [topic|scan]` - Capture a decision as a MADR, or scan recent changes for undocumented decisions
- `/standard [topic|scan]` - Capture an enforceable standard, or scan decisions for missing standards
- `/runbook [topic|scan]` - Capture an operational runbook, or scan for services/procedures that lack runbooks
- `/commit` - Analyze working tree changes and create atomic conventional commits
