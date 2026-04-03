# Agents

Instructions for AI coding agents working on this repository.

## Project

Infrastructure-as-code repository for a homelab.
Currently in the discovery phase.

## Conventions

- Prefer declarative configuration over imperative scripts
- Use semantic line breaks in markdown (one sentence per line)

### Commit discipline

Make atomic commits with conventional commit labels.
Each commit represents one logical change, labeled with a single type.

1. One logical change per commit — if `git revert` would undo something unrelated, split it
2. One conventional type per commit — if you need two types, split it
3. Separate refactoring from behavior changes
4. Separate formatting from logic changes
5. Tests travel with the code they test
6. Do not include agent references (e.g., `Co-Authored-By`) in commits unless explicitly asked

**Format:** `<type>[(scope)]: <description>`

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

**Scopes** (optional): `docs`, `infra`, `config`, `network`, `storage`

## Decision Records

Project decisions are documented in `docs/decisions/` using the [MADR 4.0.0](https://adr.github.io/madr/) format.

**Before proposing an approach**, check existing decision records to avoid contradicting prior decisions.

**When a significant decision is made** (technology choice, architectural direction, process convention, or trade-off between alternatives), it should be captured as an ADR:

1. Follow the template in `docs/decisions/TEMPLATE.md`
2. Use the next sequential number, zero-padded to 4 digits
3. Update the index table in `docs/decisions/README.md`

A decision is "significant" if it is hard to reverse, affects multiple components, or involves choosing between alternatives.
