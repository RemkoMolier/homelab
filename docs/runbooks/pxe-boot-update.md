---
title: "PXE boot file update"
owner: "Remko Molier"
last-verified: "2026-04-06"
severity: "low"
related: ["bootstrap-mikrotik-device"]
---

# PXE boot file update

## Overview

How to update netboot.xyz PXE boot files on the RB5009 router.
The PXE upload is managed by OpenTofu, but content changes at the same URL are not detected automatically.

## Symptoms

- PXE boot fails or loads an outdated netboot.xyz menu
- A new netboot.xyz release is available but the router still serves old binaries

## Prerequisites

- [ ] SSH access to the RB5009 from the Terraform workstation
- [ ] `mise install` has been run to install `opentofu`

## Resolution

### 1. Taint the PXE upload resources

OpenTofu tracks PXE files by filename and URL.
If the content changed at the same URL (e.g., a new netboot.xyz release), taint the resources to force re-download:

```bash
cd terraform/routeros
tofu taint 'module.rb5009.module.router.terraform_data.pxe_upload["netboot.xyz.kpxe"]'
tofu taint 'module.rb5009.module.router.terraform_data.pxe_upload["netboot.xyz-undionly.kpxe"]'
tofu taint 'module.rb5009.module.router.terraform_data.pxe_upload["netboot.xyz.efi"]'
```

### 2. Apply

```bash
tofu apply -target='module.rb5009'
```

Expected result: the three `pxe_upload` resources are recreated, downloading fresh binaries and uploading them via SCP.

### 3. Verify

PXE boot a test machine on the management VLAN and confirm the netboot.xyz menu loads.

## Rollback

The previous boot files are overwritten on the router.
To restore, taint and re-apply — this will re-download from the same URLs.
If netboot.xyz is down, manually SCP the files from a local backup.

## Escalation

- If SCP upload fails, check SSH connectivity to the RB5009
- If PXE boot fails after update, verify TFTP and DHCP option configuration in RouterOS

## Post-incident notes

| Date | Notes |
| ------ | ------- |
