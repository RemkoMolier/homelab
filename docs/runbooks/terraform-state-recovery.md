---
title: "Terraform state recovery"
owner: "Remko Molier"
last-verified: "2026-04-04"
severity: "critical"
related: ["pki-operations", "git-crypt-onboarding"]
---

# Terraform state recovery

## Overview

Recovery procedures for OpenTofu state files that are encrypted with PBKDF2+AES-GCM and committed to git.
Covers passphrase issues, state corruption, and full state rebuild.

## Symptoms

- `tofu plan` fails with a decryption or state-loading error
- `tofu plan` shows every resource as needing creation (state lost or empty)
- `tofu apply` fails with `Passphrase must be at least 16 characters` (passphrase not loaded)
- State file is empty, truncated, or contains invalid JSON

## Prerequisites

- [ ] GPG private key for SOPS decryption (fingerprint: `1F476D92728DFC65F15E40464F3984ECAE4A5BAF`)
- [ ] mise environment active (`eval "$(mise activate bash)"`)
- [ ] Access to the git repository with full history
- [ ] Network connectivity to managed devices (for state rebuild)

## Diagnosis

1. Verify the passphrase is loaded:

   ```bash
   env | grep TF_VAR_state_passphrase
   ```

   Expected result: variable is set (value hidden).
   If missing, check that mise is active and `.env.sops.json` can be decrypted.

2. Verify SOPS decryption works:

   ```bash
   sops -d .env.sops.json
   ```

   Expected result: JSON output with `TF_VAR_state_passphrase` in plaintext.
   If this fails, your GPG key is missing or expired.

3. Check the state file exists and is not empty:

   ```bash
   ls -la terraform/routeros/terraform.tfstate
   head -c 100 terraform/routeros/terraform.tfstate
   ```

   Expected result: file exists, starts with `{"meta":` (encrypted format).

4. Check git history for the last known good state:

   ```bash
   git log --oneline -- terraform/routeros/terraform.tfstate
   ```

   Expected result: list of commits that modified the state file.

## Resolution

### Scenario 1: Passphrase not loaded

The passphrase is stored in `.env.sops.json` and loaded automatically by mise.

1. Activate mise:

   ```bash
   eval "$(mise activate bash)"
   ```

2. Verify:

   ```bash
   cd terraform/routeros && tofu plan
   ```

   Expected result: plan runs without passphrase errors.

### Scenario 2: GPG key missing

The `.env.sops.json` file is encrypted with GPG.
Without the private key, the passphrase cannot be recovered.

1. If you have a GPG key backup, import it:

   ```bash
   gpg --import /path/to/private-key.asc
   ```

2. Verify the key is present:

   ```bash
   gpg --list-secret-keys 1F476D92728DFC65F15E40464F3984ECAE4A5BAF
   ```

   Expected result: key details are shown.

3. Retry SOPS decryption:

   ```bash
   sops -d .env.sops.json
   ```

If the GPG key is permanently lost, see Scenario 4 (full state rebuild).

### Scenario 3: State file corrupted

1. Restore from the automatic backup:

   ```bash
   cp terraform/routeros/terraform.tfstate.backup terraform/routeros/terraform.tfstate
   ```

   Note: the backup may be slightly behind the primary state.

2. If no backup exists, restore from git:

   ```bash
   git log --oneline -5 -- terraform/routeros/terraform.tfstate
   git checkout <commit-hash> -- terraform/routeros/terraform.tfstate
   ```

3. Verify:

   ```bash
   cd terraform/routeros && tofu plan
   ```

   Expected result: plan shows only the changes made since the restored state, not full recreation.

### Scenario 4: Full state rebuild

If both the state file and passphrase are lost, rebuild state by importing existing infrastructure.

1. Generate a new passphrase (minimum 16 characters):

   ```bash
   openssl rand -base64 32
   ```

2. Store it in `.env.sops.json`:

   ```bash
   sops .env.sops.json
   ```

   Update the `TF_VAR_state_passphrase` value.

3. Initialize OpenTofu:

   ```bash
   cd terraform/routeros
   tofu init
   ```

4. Import each device's resources.
   The `device-*.tf` files contain `import` blocks for bootstrapped resources.
   For resources without import blocks, use `tofu import`:

   ```bash
   tofu import 'module.crs226.routeros_ip_address.management' '*1'
   ```

   Repeat for all managed resources across all devices.

5. After importing, run a plan to verify:

   ```bash
   tofu plan
   ```

   Expected result: minimal or no changes (configuration matches live state).

### Scenario 5: Passphrase rotation

1. Decrypt the current state (requires the old passphrase to be active):

   ```bash
   cd terraform/routeros
   tofu plan
   ```

   This confirms the current passphrase works.

2. Generate a new passphrase and update `.env.sops.json`:

   ```bash
   sops .env.sops.json
   ```

3. Reload the environment:

   ```bash
   eval "$(mise activate bash)"
   ```

4. Run apply to re-encrypt state with the new passphrase:

   ```bash
   tofu apply -refresh-only
   ```

   Expected result: state is written with the new passphrase.

5. Commit both files:

   ```bash
   git add .env.sops.json terraform/routeros/terraform.tfstate
   git commit -m "chore(infra): rotate state encryption passphrase"
   ```

## Rollback

For all scenarios, the previous state is available in git:

```bash
git log --oneline -- terraform/routeros/terraform.tfstate
git checkout <commit-hash> -- terraform/routeros/terraform.tfstate
```

If you rotated the passphrase, you must also restore the old `.env.sops.json` to decrypt the old state.

## Escalation

- If the GPG key is permanently lost and no state backup exists, a full re-import is required.
  This is time-consuming but non-destructive — existing device configurations are not affected.
- For GPG key management, see [git-crypt onboarding](git-crypt-onboarding.md).
- For device access issues during re-import, see [Bootstrap MikroTik device](bootstrap-mikrotik-device.md).

## Post-incident notes

| Date | Notes |
| --- | --- |
