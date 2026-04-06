---
title: "Rotate age key for SOPS"
owner: "Remko Molier"
last-verified: "2026-04-06"
severity: "high"
related: ["truenas-ansible-bootstrap"]
---

# Rotate age key for SOPS

## Overview

Rotate the age key used by SOPS to encrypt secrets in this repository.
Use this runbook when the age private key is compromised, accidentally exposed, or needs periodic rotation.

## Symptoms

- Age private key was committed to git in plaintext
- Age private key was leaked or exposed in CI logs
- Periodic rotation policy requires a new key

## Prerequisites

- [ ] `age` is installed (`mise install` installs it via `mise.toml`)
- [ ] `sops` is installed (`mise install`)
- [ ] GPG private key is available (needed to decrypt current files before re-encrypting)
- [ ] Working directory is clean (`git status` shows no uncommitted changes)

## Diagnosis

1. Verify current age public key in `.sops.yaml` — expected result: shows the age public key

   ```bash
   grep 'age:' .sops.yaml
   ```

2. Verify decryption works with current keys — expected result: no errors

   ```bash
   sops -d .env.sops.json > /dev/null
   ```

## Resolution

### 1. Generate a new age key

```bash
age-keygen -o /tmp/ci-age-key-new.txt
```

Note the public key from the output (starts with `age1...`).

### 2. Replace the key file in the repository

```bash
cp /tmp/ci-age-key-new.txt secrets/ci-age-key.txt
```

The file is encrypted by git-crypt so it is safe to commit.

### 3. Update `.sops.yaml` with the new public key

Replace the old `age:` value in both creation rules with the new public key:

```bash
sed -i "s|age: age1.*|age: <NEW_PUBLIC_KEY>|g" .sops.yaml
```

Verify the change:

```bash
cat .sops.yaml
```

### 4. Re-encrypt all SOPS files

```bash
sops updatekeys -y .env.sops.json
sops updatekeys -y terraform/routeros/terraform.tfvars.sops.json
```

For each file, `sops updatekeys` will show the key changes (old removed, new added).
Confirm each prompt.

If Ansible secrets exist and are already encrypted:

```bash
sops updatekeys -y ansible/inventory/host_vars/truenas.home.molier.net/secrets.sops.yaml
```

### 5. Verify decryption with the new key

```bash
sops -d .env.sops.json > /dev/null && echo "OK"
sops -d terraform/routeros/terraform.tfvars.sops.json > /dev/null && echo "OK"
```

### 6. Clean up

```bash
rm /tmp/ci-age-key-new.txt
```

### 7. Commit and push

```bash
git add .sops.yaml secrets/ci-age-key.txt .env.sops.json terraform/routeros/terraform.tfvars.sops.json
git commit -m "chore(config): rotate age key for SOPS"
git push
```

### 8. Update CI secrets

If the age key is stored as a GitHub Actions secret or in any other CI system, update it there with the new private key from `secrets/ci-age-key.txt`.

## Rollback

If the new key doesn't work, the GPG key can still decrypt all files (SOPS encrypts to both recipients).
Revert the commit and try again:

```bash
git revert HEAD
```

## Escalation

- If GPG decryption also fails, the secrets cannot be recovered from the repository — restore from a backup or re-create the secrets manually
- If the old age key was compromised, treat all secrets encrypted with it as potentially exposed and rotate them (passwords, API tokens, cloud credentials)

## Post-incident notes

| Date | Notes |
| ------ | ------- |
| 2026-04-06 | Initial rotation: old key accidentally committed in plaintext before git-crypt was configured for `secrets/` |
