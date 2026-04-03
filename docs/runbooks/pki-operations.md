---
title: "PKI operations"
owner: Remko Molier
last-verified: 2026-04-03
severity: high
related: ["bootstrap-mikrotik-device"]
---

# PKI operations

## Overview

Procedures for managing the internal PKI: renewing certificates, rotating CAs, and recovering from key compromise.
The PKI structure is: Root CA → Intermediate CA → Device certificates.
See [ADR-0010](../decisions/0010-internal-pki-with-offline-root-ca.md) for the architecture decision.

## Symptoms

- Certificate expiry warnings from devices or services
- `tofu plan` shows certificate resources need replacement
- TLS errors when connecting to device APIs
- Suspected key compromise

## Prerequisites

- [ ] git-crypt is unlocked (`git-crypt unlock`)
- [ ] OpenTofu and SOPS are installed (`mise install`)
- [ ] Access to the GPG key that decrypts git-crypt

## Diagnosis

Check certificate expiry dates:

```bash
# Root CA (20-year validity)
openssl x509 -in pki/root-ca/ca.crt -noout -dates

# Intermediate CA (10-year validity)
openssl x509 -in pki/intermediate-ca/ca.crt -noout -dates

# Verify chain
openssl verify -CAfile pki/root-ca/ca.crt pki/intermediate-ca/ca.crt
```

Check a device certificate from Terraform state:

```bash
cd terraform/routeros
tofu show -json | jq '.values.root_module.child_modules[].resources[] | select(.type == "tls_locally_signed_cert")'
```

## Resolution

### Renew device certificates

Device certificates are managed by Terraform and have 2-year validity.
To renew, taint the certificate resources and re-apply:

```bash
cd terraform/routeros
tofu taint 'module.routeros.tls_locally_signed_cert.device["rb5009"]'
tofu apply
```

To renew all device certificates at once:

```bash
for device in rb5009 crs309 crs326 crs226 hap-ax2a hap-ax2b; do
  tofu taint "module.routeros.tls_locally_signed_cert.device[\"${device}\"]"
done
tofu apply
```

### Renew the intermediate CA

The intermediate CA has 10-year validity.
To renew before expiry:

1. Generate a new intermediate CA key and CSR:

   ```bash
   cd pki/intermediate-ca
   openssl genrsa -out ca.key.new 4096
   openssl req -new -key ca.key.new -config openssl.cnf -out ca.csr
   ```

2. Sign with the root CA:

   ```bash
   openssl x509 -req -in ca.csr \
     -CA ../root-ca/ca.crt -CAkey ../root-ca/ca.key -CAcreateserial \
     -extfile openssl.cnf -extensions v3_intermediate_ca \
     -days 3650 -sha256 -out ca.crt.new
   ```

3. Swap in the new files:

   ```bash
   mv ca.key.new ca.key
   mv ca.crt.new ca.crt
   cat ca.crt ../root-ca/ca.crt > ca-chain.crt
   rm -f ca.csr
   ```

4. Re-issue all device certificates:

   ```bash
   cd ../../terraform/routeros
   tofu apply  # tls provider detects the CA change and re-issues certs
   ```

5. Commit the new intermediate CA files.

### Renew the root CA

The root CA has 20-year validity.
If it needs renewal (key compromise or approaching expiry):

1. Run `pki/scripts/init-root-ca.sh` after removing the old key
2. Re-sign the intermediate CA (see above)
3. Re-issue all device certificates
4. Distribute the new root CA certificate to all trust stores

This is a high-impact operation — all services need to trust the new root CA.

### Key compromise — intermediate CA

If the intermediate CA key is compromised:

1. Generate a new intermediate CA (see renewal steps above)
2. Re-issue all device certificates
3. The root CA is unaffected — no need to change trust stores

### Key compromise — root CA

If the root CA key is compromised:

1. Treat this as a full PKI rebuild
2. Remove `pki/root-ca/ca.key` and `pki/root-ca/ca.crt`
3. Run `pki/scripts/init-root-ca.sh` to create a new root CA
4. Run `pki/scripts/init-intermediate-ca.sh` to create a new intermediate CA
5. Run `tofu apply` to re-issue all device certificates
6. Distribute the new root CA certificate to all trust stores
7. Rotate git-crypt (see [git-crypt onboarding](git-crypt-onboarding.md) runbook)

## Rollback

Certificate operations are generally forward-only.
If a new certificate causes problems on a device:

1. The old certificate may still be valid on the device
2. Connect via SSH or console to switch back to the old certificate
3. Re-run `tofu apply` to push the correct certificate

## Escalation

- If the root CA key is lost and git-crypt cannot be unlocked, the PKI must be rebuilt from scratch
- If devices reject new certificates, check the full chain: device cert → intermediate → root
- OpenSSL reference: [x509 man page](https://www.openssl.org/docs/man3.0/man1/openssl-x509.html)

## Post-incident notes

| Date | Notes |
| --- | --- |
