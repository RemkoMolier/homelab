# Homelab

Infrastructure-as-code repository for Remko's homelab.

## Status

This project is in the **discovery phase**.
Run `/research` to continue the structured research and implementation-planning process.

## Setup

Tool versions are managed with [mise](https://mise.jdx.dev/) — see [ADR-0006](docs/decisions/0006-use-mise-for-tool-version-management.md).

- Install mise: `curl https://mise.run | sh`
- Activate mise in your shell rc: `eval "$(mise activate bash)"` or `eval "$(mise activate zsh)"`
- Install project tools: `mise install`
- Or run `./setup.sh` to do both (used automatically on Claude web)
- Secrets from `.env.sops.json` are decrypted and loaded automatically by mise (`sops.rops = false` for GPG support)
- Edit secrets: `sops .env.sops.json`
- Tool versions are pinned in `mise.toml`; [Renovate](https://github.com/marketplace/renovate) creates update PRs weekly — see [ADR-0015](docs/decisions/0015-use-renovate-for-dependency-updates.md)

## Infrastructure

The repository manages homelab infrastructure with two tools — see [ADR-0008](docs/decisions/0008-split-tooling-opentofu-and-ansible.md):

- **OpenTofu** (`terraform/routeros/`) — network device configuration (MikroTik, Horaco switches)
- **OpenTofu** (`terraform/github/`) — GitHub repository settings ([ADR-0014](docs/decisions/0014-manage-github-repo-settings-with-opentofu.md))
- **Ansible** (`ansible/`) — TrueNAS SCALE configuration

### Secrets

- **SOPS** encrypts secrets in `*.sops.json` / `*.sops.yaml` / `.env.sops.json` files — see [ADR-0009](docs/decisions/0009-use-sops-for-secrets-management.md)
- Infrastructure config uses `encrypted_regex: "^secrets$"` — only keys named `secrets` are encrypted
- Environment secrets (`.env.sops.json`) encrypt all keys and are loaded by mise natively
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

### Per-device apply

Each `device-*.tf` file contains a `terraform_data.<device>_apply` anchor that depends on the full device chain (bootstrap, hardware trunks, device module, enforcement).
To apply a single device without affecting others:

```bash
cd terraform/routeros
tofu apply -target='terraform_data.crs226_apply'
```

Available targets: `crs226_apply`, `crs309_apply`, `crs326_apply`, `hap_ax2_kitchen_apply`, `hap_ax2_musicroom_apply`, `rb5009_apply`.

## Conventions

- Prefer declarative configuration over imperative scripts
- Use semantic line breaks in markdown (one sentence per line) — see [ADR-0004](docs/decisions/0004-markdown-quality-standard.md)
- Run `mise run lint` to check all quality (markdown + terraform)
- Run `mise run lint:markdown` for markdown only
- Run `mise run lint:terraform` for terraform only (fmt, validate, tflint, trivy)
- Pre-commit hook runs `mise run lint` automatically via [lefthook](https://github.com/evilmartians/lefthook)
- Secret scanning: `gitleaks protect --staged` runs in pre-commit + CI — see [ADR-0013](docs/decisions/0013-use-gitleaks-for-secret-scanning.md)
- SOPS validation: `scripts/check-sops-encryption.sh` verifies all `secrets` values are encrypted

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
