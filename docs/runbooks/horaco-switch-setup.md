---
title: "Horaco switch setup"
owner: "Remko Molier"
last-verified: "2026-04-05"
severity: "medium"
related: ["switch-chip-vlan-operations"]
---

# Horaco switch setup

## Overview

Procedures for configuring the two Horaco unmanaged-turned-web-managed switches in the homelab.
These switches use different firmware and web UIs despite both being Horaco-branded.

## Device inventory

| Switch | IP | Model | Chip | Firmware | Web UI |
| --- | --- | --- | --- | --- | --- |
| Horaco 10G (sw-10g) | 172.16.1.20 | ZX-SWTGW2C8F | Unknown | v1.1.1.29 | CGI-based (`cgi/get.cgi`, `cgi/set.cgi`), RSA-encrypted login |
| Horaco 2.5G (sw-2g5) | 172.16.1.21 | KP-9000-9XHML-X | RTL8373 | V100.9.9.1.7 (June 2025) | Classic HRUI (`login.cgi`), MD5 cookie auth |

## Symptoms

- Tagged VLAN traffic not passing through the Horaco switches
- Devices behind CRS226 or Horaco 2.5G unreachable on non-default VLANs
- New VLAN added to MikroTik but not working on Horaco-connected ports

## Prerequisites

- [ ] Web browser (the 10G switch UI uses frames and RSA-encrypted login JS)
- [ ] Credentials for both switches (username: `remko`)
- [ ] Network access to management VLAN (172.16.1.0/24)
- [ ] Knowledge of which VLANs need to pass through (see `terraform/routeros/locals.tf` for the VLAN table)

## Diagnosis

### Verify switch reachability

1. Ping the switch management IP — expected result: replies from 172.16.1.20 or .21

   ```bash
   ping -c 3 172.16.1.20
   ping -c 3 172.16.1.21
   ```

### Verify VLAN configuration (2.5G switch via curl)

1. Compute the auth cookie and log in:

   ```bash
   cookie=$(echo -n "<username><password>" | md5sum | cut -d' ' -f1)
   curl -s -b "admin=$cookie" \
     -d "username=<username>&Response=$cookie&language=EN" \
     http://172.16.1.21/login.cgi -o /dev/null
   ```

   Expected result: HTTP 200, HTML with `window.top.location.replace("/")`

2. Read VLAN configuration (requires `Referer` header):

   ```bash
   curl -s -b "admin=$cookie" \
     -H "Referer: http://172.16.1.21/" \
     http://172.16.1.21/vlan.cgi
   ```

   Expected result: HTML table showing configured VLANs with port membership

### Verify VLAN configuration (10G switch)

1. Open `http://172.16.1.20` in a browser
2. Navigate to VLAN settings in the sidebar — expected result: list of VLANs with port membership

## Resolution

### Initial setup (both switches)

Both switches ship with only VLAN 1 active.
All VLANs must be explicitly created and ports set to trunk mode for tagged traffic to pass.

Current VLANs to configure: **10** (Home), **30** (IoT), **40** (VoIP), **50** (CCTV), **100** (Guest).
Future VLANs to add when needed: **5** (Production), **6** (Staging), **20** (Homelab), **21** (Storage).

### Configure the 10G switch (.20) via web UI

1. Open `http://172.16.1.20` in a browser and log in — expected result: switch dashboard with port panel

2. Navigate to VLAN settings and create VLANs 10, 30, 40, 50, 100 — expected result: VLANs appear in the VLAN table

3. Set all ports (TE1–TE8) to trunk uplink mode with all VLANs tagged — expected result: each port shows as trunk with allowed VLANs 10, 30, 40, 50, 100

4. Set the uplink port TPID to `0x8100` (standard 802.1Q) — expected result: tagged traffic passes to CRS309 on sfp+8

   **Why:** The 10G switch defaults to a non-standard TPID.
   Without this, 802.1Q tagged frames are dropped at the uplink.

5. Save the configuration — expected result: config persists across reboot

### Configure the 2.5G switch (.21) via web UI

1. Open `http://172.16.1.21` in a browser and log in — expected result: switch dashboard with frameset UI

2. Navigate to VLAN settings and create VLANs 10, 30, 40, 50, 100 — expected result: VLANs appear in the VLAN list

3. Set all ports to trunk mode with all VLANs tagged — expected result: each port shows tagged membership for all VLANs

4. Save the configuration — expected result: config persists across reboot

   **Note:** The 2.5G switch does not need a TPID override — it uses standard 802.1Q by default.

### Adding a new VLAN to both switches

When a new VLAN is added to the MikroTik infrastructure:

1. Add the VLAN to the 10G switch (.20) via web UI and tag it on all ports — expected result: VLAN appears in the VLAN table

2. Add the VLAN to the 2.5G switch (.21) via web UI and tag it on all ports — expected result: VLAN appears in the VLAN table

3. Save configuration on both switches — expected result: tagged traffic for the new VLAN passes through

### Backup and restore

#### Export running config (10G switch)

The 10G switch supports a text-based running config export via the web UI.
The exported file uses a CLI-like syntax (see `work/horaco/running-config.cfg`).

#### Export config (2.5G switch)

The 2.5G switch exports a proprietary binary format (`switch_cfg.bin`).
This file is not human-readable but can be restored via the web UI.

Store backups in `work/horaco/` for reference.

## Terraform automation status

The repository includes a skeleton at `terraform/horaco/` using the `brennoo/hrui` provider (`~> 0.1`).

**Current status: not functional.** The provider targets HRUI-firmware switches (`login.cgi` + HTML scraping), which partially matches the 2.5G switch but fails because:

- The 2.5G switch firmware requires a `Referer` header on all CGI requests; without it, endpoints return HTTP 404
- The 10G switch uses a completely different web framework (`cgi/get.cgi`, `cgi/set.cgi` with RSA-encrypted login) and is incompatible with the HRUI provider entirely

**Next steps for automation:**

- File a PR or issue on `brennoo/terraform-provider-hrui` to add `Referer` header support (fixes 2.5G switch)
- The 10G switch will likely need a separate provider or direct API automation

## Rollback

### Factory reset (2.5G switch)

1. Use the web UI reset option, or hold the physical reset button for 10 seconds — expected result: switch reboots with default IP `192.168.0.1`

2. Reconfigure the management IP to `172.16.1.21/24` with gateway `172.16.1.1` — expected result: switch reachable on management VLAN

### Factory reset (10G switch)

1. Use the web UI reset option or hold the physical reset button — expected result: switch reboots with factory defaults

2. Reconfigure the management IP to `172.16.1.20/24` with gateway `172.16.1.1` — expected result: switch reachable on management VLAN

**Note:** After factory reset, all VLANs must be recreated.
The 2.5G switch once had a bad config that blocked even VLAN 1; factory reset resolved it.

## Escalation

- If VLAN traffic still doesn't pass after configuration, check the upstream MikroTik trunk port VLAN membership (CRS309 sfp+8 for the 10G switch)
- If the 10G switch drops tagged frames, verify the TPID is set to `0x8100` on the uplink
- If the web UI is unreachable, connect directly to the switch with a laptop on 172.16.1.0/24 (or the factory default subnet)
- See [Switch-chip VLAN operations](switch-chip-vlan-operations.md) for the CRS226 which connects downstream of the Horaco 10G

## Post-incident notes

| Date | Notes |
| ------ | ------- |
| 2026-04-05 | Initial setup documented. HRUI provider tested — blocked by missing Referer header on 2.5G and incompatible firmware on 10G. |
