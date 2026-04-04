---
title: "git-crypt onboarding and recovery"
owner: Remko Molier
last-verified: 2026-04-03
severity: medium
related: ["pki-operations"]
---

# git-crypt onboarding and recovery

## Overview

Procedures for unlocking the repository on a new machine, adding collaborators, and recovering from a locked state.
git-crypt encrypts CA private keys (`pki/**/*.key`) transparently using GPG.

## Symptoms

- Cloned the repo and `.key` files contain binary gibberish
- `git-crypt status` shows files as "not decrypted"
- OpenTofu fails reading CA keys with encoding errors
- New machine or reinstalled OS needs access to encrypted files

## Prerequisites

- [ ] git-crypt installed (`dnf install git-crypt` on Fedora)
- [ ] GPG private key available on the machine (the key listed in `.git-crypt/keys/`)

## Diagnosis

1. Check if git-crypt is locked or unlocked:

   ```bash
   git-crypt status
   ```

   Expected result: files show as `encrypted` (locked) or `not encrypted` (unlocked)

2. Check which GPG keys have access:

   ```bash
   ls .git-crypt/keys/default/0/
   ```

   Each `.gpg` file corresponds to a GPG key fingerprint.

3. Verify your GPG key is available:

   ```bash
   gpg --list-secret-keys
   ```

## Resolution

### Unlock on a new machine

After cloning the repository:

```bash
git-crypt unlock
```

`git-crypt unlock` uses your GPG private key to decrypt CA private keys.
Secrets from `.env.sops.json` are loaded automatically by mise (no extra step needed).

If you get a GPG error, ensure your private key is imported:

```bash
gpg --import /path/to/your-private-key.asc
```

### Add a collaborator

To grant another person access to the encrypted files:

```bash
git-crypt add-gpg-user THEIR_GPG_FINGERPRINT
```

This encrypts the symmetric key to their GPG public key and creates a commit.
They can then `git-crypt unlock` after pulling.

**Note:** git-crypt has no `remove-gpg-user`.
If someone's access needs to be revoked, you must rotate the actual secrets (CA keys) and re-initialize git-crypt.

### Re-initialize git-crypt (key rotation)

If the symmetric key is compromised or access needs to be revoked:

1. Decrypt all files: `git-crypt unlock`
2. Copy the decrypted `.key` files to a temporary location
3. Remove git-crypt state: `rm -rf .git-crypt`
4. Remove the `.gitattributes` filter rules temporarily
5. Commit the removal
6. Re-initialize: `git-crypt init`
7. Add authorized GPG keys: `git-crypt add-gpg-user FINGERPRINT`
8. Restore `.gitattributes` filter rules
9. Copy the `.key` files back and commit (they will be re-encrypted with the new key)
10. **Rotate the actual CA keys** — the old keys were encrypted with the old symmetric key and remain in git history

### Recover from a corrupted state

If git-crypt gets confused (smudge filter errors, partially encrypted files):

1. Save any unencrypted work
2. Lock the repo: `git-crypt lock`
3. Unlock again: `git-crypt unlock`
4. If that fails, re-clone the repo and `git-crypt unlock`

## Rollback

git-crypt operations are generally safe:

- `unlock` is idempotent — running it when already unlocked is a no-op
- `lock` re-encrypts files in the working directory but does not affect the repo

## Escalation

- If the GPG private key is lost and no other collaborator has access, the encrypted files are unrecoverable from git — rebuild the PKI from scratch
- Always keep a backup of your GPG private key in a secure location
- [git-crypt documentation](https://github.com/AGWA/git-crypt/blob/master/README.md)

## Post-incident notes

| Date | Notes |
| --- | --- |
