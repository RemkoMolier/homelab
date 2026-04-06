---
title: "TrueNAS Ansible bootstrap"
owner: "Remko Molier"
last-verified: "2026-04-06"
severity: "medium"
related: []
---

# TrueNAS Ansible bootstrap

## Overview

One-time setup to enable Ansible management of TrueNAS SCALE.
The `arensb.truenas` collection connects via SSH and runs `midclt` on the host, so SSH key authentication must be configured before the playbook can run.

## Symptoms

- `ansible-playbook` fails with `Permission denied (publickey,password)`
- First-time TrueNAS setup — Ansible has never managed this host

## Prerequisites

- [ ] TrueNAS SCALE is installed and accessible on `172.16.1.2`
- [ ] SSH service is enabled in TrueNAS (System > Services > SSH)
- [ ] The `truenas_admin` user exists (created during TrueNAS installation)
- [ ] You have an SSH key pair on your workstation (`~/.ssh/id_ed25519` or similar)
- [ ] `mise install` has been run to install `ansible-core`
- [ ] Ansible collections are installed: `ansible-galaxy collection install -r ansible/requirements.yaml`

## Diagnosis

1. Test SSH connectivity — expected result: password prompt (not "connection refused")

   ```bash
   ssh truenas_admin@172.16.1.2
   ```

2. Verify Ansible can reach the host — expected result: pong (after password prompt)

   ```bash
   ansible truenas -i ansible/inventory/hosts.yaml -m ping --ask-pass
   ```

## Resolution

### 1. Copy SSH public key to TrueNAS

```bash
ssh-copy-id truenas_admin@172.16.1.2
```

Enter the `truenas_admin` password when prompted.

### 2. Verify key-based authentication

```bash
ssh truenas_admin@172.16.1.2 'echo "SSH key auth works"'
```

Expected result: prints the message without asking for a password.

### 3. Verify sudo/become access

```bash
ssh truenas_admin@172.16.1.2 'sudo -n midclt call system.info'
```

Expected result: JSON with system info (hostname, version, uptime).
If it fails with "sudo: a password is required", passwordless sudo is not configured.
Either configure passwordless sudo for `truenas_admin`, or provide the become password interactively when running Ansible (`ansible-playbook --ask-become-pass ...`).

### 4. Install Ansible collections

```bash
ansible-galaxy collection install -r ansible/requirements.yaml
```

### 5. Encrypt the secrets file

Edit `ansible/inventory/host_vars/truenas.home.molier.net/secrets.sops.yaml` with real credentials, then encrypt:

```bash
sops -e -i ansible/inventory/host_vars/truenas.home.molier.net/secrets.sops.yaml
```

### 6. Test the playbook in check mode

```bash
# From the repo root
ansible-playbook ansible/playbooks/truenas.yaml -i ansible/inventory/hosts.yaml --check --diff
```

Expected result: tasks show what would change, no errors.

### 7. Run the playbook

```bash
ansible-playbook ansible/playbooks/truenas.yaml -i ansible/inventory/hosts.yaml
```

Run specific sections with tags:

```bash
ansible-playbook ansible/playbooks/truenas.yaml -i ansible/inventory/hosts.yaml --tags users
ansible-playbook ansible/playbooks/truenas.yaml -i ansible/inventory/hosts.yaml --tags shares
```

## Rollback

SSH key auth is additive — it does not disable password auth.
To remove the SSH key:

1. SSH to TrueNAS with password: `ssh truenas_admin@172.16.1.2`
2. Edit authorized keys: `nano ~/.ssh/authorized_keys`
3. Remove the relevant key line

## Escalation

- If SSH is unreachable, check the TrueNAS web UI at `https://172.16.1.2` to verify the SSH service is running and bound to `enp6s0`
- If `midclt` commands fail, check TrueNAS version compatibility with the `arensb.truenas` collection version
- Console access via IPMI or physical keyboard is the last resort if SSH and web UI are both unreachable

## Post-incident notes

| Date | Notes |
| ------ | ------- |
