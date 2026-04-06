# Homelab

Infrastructure-as-code repository for Remko's homelab.

## Setup

### Prerequisites

- [mise](https://mise.jdx.dev/) — manages tool versions, environment variables, and tasks
- [git-crypt](https://github.com/AGWA/git-crypt) — encrypts CA private keys transparently in git

### Getting started

1. Install mise:

   ```sh
   curl https://mise.run | sh
   ```

2. Activate mise in your shell rc (after oh-my-zsh `source` if applicable):

   ```sh
   # ~/.bashrc
   eval "$(mise activate bash)"

   # ~/.zshrc
   eval "$(mise activate zsh)"
   ```

3. Install project tools:

   ```sh
   mise install
   ```

4. Unlock git-crypt (requires a trusted GPG key):

   ```sh
   git-crypt unlock
   ```

Steps 1–3 can also be done with `./setup.sh`.
Secrets from `.env.sops.json` are decrypted and loaded automatically by mise when you enter the project directory.

### Editing secrets

```sh
sops .env.sops.json
```

## Infrastructure

The repository manages homelab infrastructure with two tools — see [ADR-0008](docs/decisions/0008-split-tooling-opentofu-and-ansible.md):

- **OpenTofu** (`terraform/`) — MikroTik network device configuration and GitHub repo settings
- **Ansible** (`ansible/`) — TrueNAS SCALE configuration

### Secrets management

- **SOPS** encrypts secrets in `*.sops.json` / `*.sops.yaml` / `.env.sops.json` files — see [ADR-0009](docs/decisions/0009-use-sops-for-secrets-management.md)
- Only keys named `secrets` are encrypted (`encrypted_regex: "^secrets$"` in `.sops.yaml`)
- Non-secret config (IPs, hostnames) stays plaintext alongside encrypted credentials
- **git-crypt** encrypts CA private keys (`pki/**/*.key`) transparently
- OpenTofu state is encrypted with PBKDF2+AES-GCM and committed to git

### PKI

An internal CA issues TLS certificates for all homelab services — see [ADR-0010](docs/decisions/0010-internal-pki-with-offline-root-ca.md).

- **Root CA** (`pki/root-ca/`) — offline, 20-year validity, used only to sign the intermediate
- **Intermediate CA** (`pki/intermediate-ca/`) — used by OpenTofu's `tls` provider to issue device certificates on `tofu apply`
- To bootstrap PKI: `pki/scripts/init-root-ca.sh` then `pki/scripts/init-intermediate-ca.sh` (one-time)

### OpenTofu structure

```text
terraform/routeros/
  device-*.tf                        Per-device: provider + module call + port map
  locals.tf                          Shared VLANs, firewall zones, domain
  secrets.tf                         SOPS decryption + credential merging
  terraform.tfvars.sops.json         Device config (plaintext) + secrets (encrypted)
  modules/
    components/                      Building blocks
      bootstrap/                       HTTP bootstrap for fresh devices
      capsman-client/                  WiFi radios + controller discovery
      capsman-controller/              SSIDs, security, provisioning rules
      certificates/                    TLS cert from intermediate CA
      device-base/                     Identity, IP, NTP, services, hardening
      router/                          Firewall, NAT, DNS, DHCP, VRRP, PXE
      routeros-raw/                    REST API escape hatch (restapi provider)
      switch-bridge/                   Bridge VLAN filtering from port maps
      switch-chip/                     Legacy CRS2xx switch-chip VLANs
    devices/                         Compositions
      ap/                              cert + base + switch-bridge + capsman-client
      router/                          cert + base + router + capsman-controller
      switch/                          cert + base + switch-bridge
      switch-chip/                     cert + base + switch-chip
```

## Development

### Linting

```sh
mise run lint              # all linters
mise run lint:markdown     # markdown only
mise run lint:terraform    # terraform only (fmt, validate, tflint, trivy)
```

A pre-commit hook runs `mise run lint` automatically via [lefthook](https://github.com/evilmartians/lefthook).
The hook is installed automatically when you enter the project directory (mise `enter` hook).
To skip the hook in exceptional cases: `git commit --no-verify`.

### Conventions

- Prefer declarative configuration over imperative scripts
- Use semantic line breaks in markdown (one sentence per line) — see [ADR-0004](docs/decisions/0004-markdown-quality-standard.md)
- Make atomic commits with conventional commit labels — see [ADR-0005](docs/decisions/0005-atomic-commits-with-conventional-labels.md)

## Documentation

| Type | Location | Purpose |
| --- | --- | --- |
| [Decisions](docs/decisions/) | `docs/decisions/` | MADRs capturing the *why* behind significant choices |
| [Standards](docs/standards/) | `docs/standards/` | Enforceable rules capturing the *what* |
| [Runbooks](docs/runbooks/) | `docs/runbooks/` | SRE-style operational procedures capturing the *how* |

The chain is: **Decision** (why) → **Standard** (what) → **Runbook** (how to operate it)
