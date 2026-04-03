---
status: accepted
date: 2026-04-03
decision-makers: Remko Molier
---

# Use an internal PKI with an offline root CA

## Context and Problem Statement

The homelab needs TLS certificates for device APIs (MikroTik, TrueNAS), internal web services, and future Kubernetes ingress.
Using self-signed certificates per device provides no trust chain and requires trusting each certificate individually.
How should certificates be managed across the homelab?

## Decision Drivers

- All internal services should share a single trust root — install the root CA once, trust all issued certificates
- The root CA private key must be protected but accessible for signing
- Certificate issuance should be automated where possible (Terraform manages devices)
- The solution must work without running an online CA service initially
- Private keys must be safe to store in git

## Considered Options

- Internal PKI with offline root CA + Terraform intermediate
- MikroTik built-in CA per device
- step-ca online CA service
- Self-signed certificates per device

## Decision Outcome

Chosen option: "Internal PKI with offline root CA + Terraform intermediate", because it provides a single trust chain, automates certificate issuance via OpenTofu, and keeps the root CA offline for security.

The architecture is:

- **Root CA** (20-year validity) — offline, stored in git, private key encrypted by git-crypt
- **Intermediate CA** (10-year validity) — signed by root CA, private key in git-crypt, used by OpenTofu's `tls` provider to issue device certificates on `tofu apply`
- **Device certificates** (2-year validity) — issued automatically by Terraform, deployed to devices via the routeros provider

Private keys are encrypted by git-crypt (transparent file-level encryption using GPG).
Certificates are public and committed in plaintext.

### Consequences

- Good, because a single root CA certificate trusts all homelab services
- Good, because device certificates are issued automatically on `tofu apply` — no manual cert management
- Good, because the root CA key is offline and rarely needed (only to sign new intermediates)
- Good, because git-crypt provides transparent encryption — no manual decrypt step in the workflow
- Good, because the intermediate CA can later be replaced by step-ca for ACME auto-renewal without changing the trust chain
- Bad, because git-crypt has no key rotation mechanism — revoking access requires rotating the actual CA keys
- Bad, because certificate renewal requires running `tofu apply` before certificates expire
- Neutral, because two encryption tools in the repo (git-crypt for binary keys, SOPS for structured data) adds some complexity but each is used where it fits

### Confirmation

`git-crypt status pki/` shows `.key` files as encrypted and `.crt` files as not encrypted.
`tofu plan` reads the intermediate CA key and generates device certificates.
MikroTik devices accept the issued certificates for api-ssl.

## Pros and Cons of the Options

### Internal PKI with offline root CA + Terraform intermediate

Root CA in git-crypt, intermediate CA used by OpenTofu's `tls` provider.

- Good, because automated certificate issuance integrated into the IaC workflow
- Good, because single trust root for all services
- Good, because root CA stays offline — compromise of the intermediate is recoverable
- Good, because path to online CA (step-ca) is straightforward — sign an intermediate and run it
- Bad, because certificate renewal is manual (run `tofu apply` before expiry)
- Bad, because git-crypt lacks key rotation

### MikroTik built-in CA per device

Each MikroTik device generates its own CA and certificates.

- Good, because zero external tooling — built into RouterOS
- Bad, because no shared trust chain — each device has its own CA
- Bad, because slow key generation on low-power devices (mipsbe)
- Bad, because no automation for non-MikroTik services

### step-ca online CA service

Run Smallstep's step-ca as an ACME-compatible CA.

- Good, because full ACME support — services auto-renew certificates
- Good, because supports short-lived certificates (hours/days)
- Bad, because requires running and maintaining a service
- Bad, because MikroTik and TrueNAS don't support ACME natively — still need manual import
- Neutral, because can be added later as an intermediate CA under the same root

### Self-signed certificates per device

Each device gets a standalone self-signed certificate.

- Good, because simplest possible setup
- Bad, because no trust chain — every certificate must be trusted individually
- Bad, because no automation — manual creation and import
- Bad, because adding a new service means trusting yet another certificate everywhere

## More Information

- [git-crypt](https://github.com/AGWA/git-crypt) — transparent file encryption in git (v0.8.0)
- [OpenTofu tls provider](https://registry.terraform.io/providers/hashicorp/tls/latest/docs) — local certificate generation
- [MikroTik certificate import](https://help.mikrotik.com/docs/spaces/ROS/pages/2555969/Certificates) — PEM import support
- [step-ca](https://smallstep.com/docs/step-ca/) — online CA for future intermediate
- [Building a selfhosted CA for homelab](https://kainem.com/posts/building-a-selfhosted-ca-for-my-homelab/)
