---
status: accepted
date: 2026-04-03
decision-makers: Remko Molier
---

# Use SOPS for secrets management

## Context and Problem Statement

Infrastructure-as-code requires credentials (API keys, passwords) to manage devices.
These secrets must be stored in the repository to enable reproducibility, but must not be committed in plaintext.
How should secrets be encrypted in git?

## Decision Drivers

- Secrets must be safe to commit to git — encrypted at rest, decryptable only by authorized keys
- The solution should work without external infrastructure (no vault server, no cloud service)
- Diffs should remain readable — only values should be encrypted, not entire files
- Must support both OpenTofu variable files and Ansible variable files
- The operator already has a working GPG key (used for commit signing)

## Considered Options

- SOPS (with GPG now, age for machine keys later)
- git-crypt
- External Secrets Operator + vault
- Manual secrets management

## Decision Outcome

Chosen option: "SOPS", because it encrypts only values while leaving keys and structure readable, supports both YAML and JSON (covering OpenTofu tfvars and Ansible group_vars), and requires no external infrastructure.

GPG is used initially since the operator already has a key.
Age keys will be added later when machine or service identities need decryption access (age has no keyring overhead, making it ideal for automated systems).

### Consequences

- Good, because encrypted files produce readable diffs (keys visible, only values change)
- Good, because supports YAML, JSON, INI, and dotenv — covers all IaC file formats
- Good, because GPG key is already available — zero additional setup
- Good, because `.sops.yaml` creation rules can target different keys per directory (e.g., GPG for personal, age for machines later)
- Good, because native Flux CD integration when Kubernetes is added later
- Bad, because GPG key must be available on any machine that needs to decrypt secrets
- Neutral, because age keys can be added alongside GPG later without changing the workflow

### Confirmation

`.sops.yaml` exists with creation rules targeting the operator's GPG fingerprint.
`sops terraform/routeros/terraform.tfvars.sops` opens an editor with decrypted values.
`sops -d` decrypts files successfully; `sops -e` re-encrypts them.

## Pros and Cons of the Options

### SOPS (with GPG + age)

Mozilla SOPS encrypts values in-place within structured files.

- Good, because encrypts values only — keys and file structure remain readable
- Good, because supports multiple key types (GPG, age, cloud KMS) simultaneously
- Good, because `.sops.yaml` rules can scope different keys to different paths
- Good, because widely adopted in the homelab GitOps community (Flux native support)
- Bad, because state files (`.tfstate`) still contain plaintext secrets — must be gitignored

### git-crypt

Transparent file-level encryption in git using GPG.

- Good, because fully transparent — encrypt/decrypt happens on git operations
- Good, because simple setup with existing GPG keys
- Bad, because encrypts entire files — diffs are unreadable for encrypted files
- Bad, because no selective value encryption — all-or-nothing per file
- Bad, because cannot encrypt only the values in a YAML file

### External Secrets Operator + vault

Secrets stored in an external vault (HashiCorp Vault, 1Password, etc.) and synced to the runtime.

- Good, because secrets never touch git at all
- Good, because centralized secret management with access controls and audit logging
- Bad, because requires running and maintaining a vault server — significant infrastructure overhead for a homelab
- Bad, because adds a critical dependency — if the vault is down, nothing can deploy

### Manual secrets management

Keep secrets out of git entirely; manage them manually on each device.

- Good, because zero tooling overhead
- Bad, because not reproducible — secrets must be manually re-entered on each setup
- Bad, because no version history for secret changes
- Bad, because defeats the purpose of infrastructure-as-code

## More Information

- [SOPS](https://github.com/getsops/sops) — secrets management tool
- [SOPS usage with GPG](https://github.com/getsops/sops#pgp) — GPG key configuration
- [SOPS usage with age](https://github.com/getsops/sops#age) — age key configuration
- [Flux SOPS guide](https://fluxcd.io/flux/guides/mozilla-sops/) — native Flux CD integration
