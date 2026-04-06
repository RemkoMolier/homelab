---
status: accepted
date: 2026-04-06
decision-makers: Remko Molier
---

# Use gitleaks for secret scanning

## Context and Problem Statement

An age private key was accidentally committed in plaintext before git-crypt was configured for the `secrets/` directory.
The repository contains SOPS-encrypted files where encrypted blobs coexist with plaintext keys.
How should secrets be detected before they enter git history?

## Decision Drivers

- Must run both as a pre-commit hook (fast feedback) and in CI (enforcement)
- Must handle SOPS-encrypted values without false positives
- Must work with git-crypt (locked files appear as binary blobs in CI)
- Should be a single binary with no runtime dependencies (consistent with mise tooling)
- Must integrate with the existing lefthook pre-commit setup

## Considered Options

- Gitleaks
- TruffleHog
- detect-secrets (Yelp)
- git-secrets (AWS)

## Decision Outcome

Chosen option: "Gitleaks", because it is the fastest pre-commit scanner, ships as a single Go binary installable via mise, supports regex-based allowlists that can match SOPS ENC blobs, and has an official GitHub Action.

A complementary SOPS validation script runs alongside gitleaks to verify that values in SOPS files are actually encrypted — a check gitleaks cannot perform natively.

### Consequences

- Good, because sub-second pre-commit scanning via `gitleaks protect --staged`
- Good, because 850+ built-in rules detect known secret patterns without configuration
- Good, because `regexTarget = "secret"` allowlists can match SOPS ENC blobs precisely
- Good, because binary files (git-crypt locked) are skipped automatically in git mode
- Good, because MIT licensed — no AGPL concerns
- Bad, because gitleaks cannot assert "this value MUST be encrypted" — requires a separate script
- Neutral, because custom rules may need tuning if false positives arise

### Confirmation

`gitleaks protect --staged` blocks a commit containing a test secret.
SOPS ENC blobs in `*.sops.json` files do not trigger alerts.
The SOPS validation script flags plaintext values in `secrets` keys.

## Pros and Cons of the Options

### Gitleaks

Single Go binary with 850+ regex-based detection rules.

- Good, because fastest scanner — sub-second for staged files
- Good, because single binary, installable via mise
- Good, because regex allowlists with `regexTarget` handle SOPS precisely
- Good, because official GitHub Action for CI
- Good, because MIT license
- Bad, because regex-only — no entropy analysis by default

### TruffleHog

Go binary with regex + entropy + live credential verification.

- Good, because verifies if detected secrets are actually active
- Good, because entropy analysis catches novel secret formats
- Bad, because AGPL-3.0 license
- Bad, because verification adds network calls — too slow for pre-commit
- Bad, because entropy analysis may flag SOPS blobs despite not being real secrets

### detect-secrets (Yelp)

Python tool with plugin-based detection and baseline workflow.

- Good, because baseline file tracks known false positives
- Good, because entropy + regex detection
- Bad, because requires Python runtime — inconsistent with Go/binary tooling
- Bad, because slow release cadence (last release May 2024)
- Bad, because entropy plugins flag SOPS encrypted blobs as high-entropy strings

### git-secrets (AWS)

Bash script with regex-based scanning focused on AWS credentials.

- Good, because simple and fast
- Bad, because effectively abandoned — no release since 2019
- Bad, because only ships AWS patterns — everything else requires manual configuration
- Bad, because installs its own git hooks — conflicts with lefthook

## More Information

- [Gitleaks](https://github.com/gitleaks/gitleaks) — v8.30+, MIT license
- [Gitleaks GitHub Action](https://github.com/gitleaks/gitleaks-action)
- [ADR-0011](0011-use-lefthook-for-pre-commit-linting.md) — lefthook for pre-commit hooks
- [ADR-0009](0009-use-sops-for-secrets-management.md) — SOPS for secrets encryption
