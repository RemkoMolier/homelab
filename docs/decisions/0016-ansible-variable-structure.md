---
status: accepted
date: 2026-04-06
decision-makers: Remko Molier
---

# Use plaintext YAML with SOPS encrypted secrets for Ansible variables

## Context and Problem Statement

Ansible needs host-specific configuration to manage TrueNAS SCALE.
This includes both non-sensitive values (hostnames, paths, share names, schedules) and secrets (passwords, API tokens, cloud credentials).
How should these variables be structured and stored?

## Decision Drivers

- Must integrate with the existing SOPS-based secrets workflow (ADR-0009)
- Non-secret configuration should be readable in diffs without decryption
- Should match the pattern already established for OpenTofu variables
- Must support the `community.sops` Ansible collection for runtime decryption

## Considered Options

- Plaintext YAML + SOPS-encrypted secrets file with `encrypted_regex`
- Single SOPS-encrypted file for all variables
- Ansible Vault for secrets

## Decision Outcome

Chosen option: "Plaintext YAML + SOPS-encrypted secrets file with `encrypted_regex`", because it mirrors the OpenTofu pattern (`terraform.tfvars.sops.json` with `encrypted_regex: "^secrets$"`), keeps non-secret values reviewable in plain text, and reuses the existing SOPS + GPG infrastructure.

### Structure

```text
ansible/inventory/host_vars/truenas.home.molier.net/
  vars.yaml              Plaintext configuration
  secrets.sops.yaml      SOPS-encrypted, only "secrets" keys encrypted
```

The `secrets.sops.yaml` file uses the existing `.sops.yaml` creation rule that matches `*.sops.yaml` with `encrypted_regex: "^secrets$"`.
This means the file structure remains readable — only values under keys named `secrets` are encrypted.

### Consequences

- Good, because non-secret config (IPs, paths, share names) is readable without GPG access
- Good, because diffs of `secrets.sops.yaml` show which secret keys changed, even if values are opaque
- Good, because the same `.sops.yaml` rules and GPG key cover both OpenTofu and Ansible
- Good, because `community.sops` lookup plugin decrypts at runtime without manual steps
- Bad, because two files per host adds mild complexity vs. a single file
- Neutral, because the pattern scales to additional hosts if needed

### Confirmation

`sops -d ansible/inventory/host_vars/truenas.home.molier.net/secrets.sops.yaml` decrypts successfully.
Ansible playbook loads both files automatically from `host_vars/`.

## Pros and Cons of the Options

### Plaintext YAML + SOPS-encrypted secrets

Split variables into two files: plain `vars.yaml` and SOPS-encrypted `secrets.sops.yaml`.

- Good, because matches the existing OpenTofu variable pattern
- Good, because non-secret values are always readable
- Good, because reuses existing `.sops.yaml` creation rules
- Bad, because requires `community.sops` collection as an Ansible dependency

### Single SOPS-encrypted file

All variables (including non-secrets) in one SOPS-encrypted file.

- Good, because single source of truth per host
- Bad, because non-secret values (paths, share names) require GPG to read
- Bad, because diffs are less useful when everything is encrypted

### Ansible Vault

Use Ansible's built-in vault encryption for secrets.

- Good, because no additional tooling — built into Ansible
- Bad, because introduces a second encryption system alongside SOPS
- Bad, because vault-encrypted files are fully opaque (no selective encryption)
- Bad, because vault passwords must be managed separately from GPG keys

## More Information

- [ADR-0009](0009-use-sops-for-secrets-management.md) — SOPS as the secrets management tool
- [community.sops collection](https://github.com/ansible-collections/community.sops) — Ansible SOPS integration
