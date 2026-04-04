---
title: "Switch-chip VLAN operations"
owner: "Remko Molier"
last-verified: "2026-04-04"
severity: "medium"
related: ["bootstrap-mikrotik-device"]
---

# Switch-chip VLAN operations

## Overview

Procedures for managing switch-chip VLANs on the CRS226 (and other CRS1xx/2xx devices).
These devices use legacy switch-chip resources instead of bridge VLAN filtering, and the RouterOS Terraform provider has known quirks that require specific workarounds.

## Symptoms

- `tofu plan` shows perpetual drift on `pcp_propagation` (`"false"` vs `"no"`) or `sa_learning` (`"true"` vs `"yes"`)
- `tofu plan` shows port reordering on `routeros_interface_ethernet_switch_crs_vlan` resources (same ports, different order)
- `tofu apply` fails with `invalid value of pcp-propagation, must be either yes or no`
- `tofu apply` fails with `Switch-chip VLAN membership drift detected. The live RouterOS port set does not match the desired VLAN membership.`
- VLAN port membership changes trigger targeted VLAN resource replacement

## Prerequisites

- [ ] Access to the OpenTofu workspace (`terraform/routeros/`)
- [ ] mise environment active (provides `TF_VAR_state_passphrase` and device credentials)
- [ ] Network connectivity to the target device

## Diagnosis

1. Run `tofu plan` and check for changes on switch-chip resources:

   ```bash
   cd terraform/routeros
   tofu plan
   ```

   Expected result: no changes if lifecycle blocks are working correctly.

2. If drift appears on `pcp_propagation` or `sa_learning`, confirm it is the known provider bug (boolean string mismatch):

   ```bash
   tofu state show 'module.crs226.module.switch.routeros_interface_ethernet_switch_crs_ingress_vlan_translation.default'
   ```

   Expected result: `pcp_propagation = "false"` and `sa_learning = "true"` in state (the provider reads `true`/`false` from the API but the API requires `yes`/`no` on writes).

3. If drift appears on VLAN `ports` ordering, confirm it is cosmetic (same ports, different order):

   ```bash
   tofu plan -target='module.crs226.module.switch.routeros_interface_ethernet_switch_crs_vlan.vlans'
   ```

   Expected result: only `ports` attribute changes, with identical port names in a different order.

4. If `tofu apply` fails with the switch-chip VLAN membership drift postcondition, identify the affected VLAN row:

   ```bash
   tofu plan
   ```

   Expected result: the failure points at a specific `routeros_interface_ethernet_switch_crs_vlan.vlans["<vlan-key>"]` instance.
   This indicates real live drift on the device, not cosmetic port reordering.

## Resolution

### Changing VLAN port membership

The `ports` attribute on `routeros_interface_ethernet_switch_crs_vlan` uses `lifecycle { ignore_changes }` to prevent perpetual drift from RouterOS reordering ports.
A `terraform_data` replacement trigger detects actual port membership changes automatically.
A normalized postcondition compares the live RouterOS port set against the desired port set and fails if membership has drifted out of band.

1. Update the port map in the device file (e.g., `device-crs226.tf`).

2. Apply normally:

   ```bash
   tofu apply
   ```

   Expected result: only the VLANs whose port membership actually changed are destroyed and recreated.
   The `terraform_data.vlan_replacement` trigger compares the normalized desired port set against the previous value, so unchanged VLANs are left alone.

3. Verify the new configuration:

   ```bash
   tofu plan
   ```

   Expected result: no changes.

### Recovering from live VLAN membership drift

If the switch-chip VLAN postcondition fails, Terraform has detected that the live RouterOS VLAN row no longer has the same member ports as the desired config.
This is real drift and must be corrected by replacing the affected VLAN resource.

1. Re-run `tofu plan` and note the failing VLAN key from the error message.

2. Replace only the affected VLAN row:

   ```bash
   tofu apply -replace='module.crs226.module.switch.routeros_interface_ethernet_switch_crs_vlan.vlans["<vlan-key>"]'
   ```

   Expected result: OpenTofu destroys and recreates only that VLAN row using the desired normalized port membership.

3. Verify convergence:

   ```bash
   tofu plan
   ```

   Expected result: no changes.

### Provider quirks reference

The switch-chip module (`modules/components/switch-chip/main.tf`) includes these workarounds:

| Resource | Attribute | Workaround | Reason |
| --- | --- | --- | --- |
| `crs_ingress_vlan_translation` | `pcp_propagation` | `ignore_changes` | API requires `yes`/`no`, provider reads back `true`/`false` |
| `crs_ingress_vlan_translation` | `sa_learning` | `ignore_changes` | Same boolean mismatch |
| `crs_vlan` | `ports` | `ignore_changes` + `terraform_data` trigger + normalized `postcondition` | RouterOS reorders the port list on read; trigger detects desired membership changes and the postcondition catches real live drift |

## Rollback

If VLAN recreation causes issues (e.g., brief connectivity loss):

1. The previous VLAN configuration is in the git-committed state file.
   Restore it:

   ```bash
   git checkout HEAD -- terraform/routeros/terraform.tfstate
   tofu apply
   ```

2. If the device is unreachable, use serial console or the bootstrap runbook to recover.

## Escalation

- If the provider bug is fixed upstream, remove the `lifecycle` blocks and test with a `tofu plan`
- Check the [terraform-routeros provider issues](https://github.com/terraform-routeros/terraform-routeros/issues) for updates on CRS resource handling
- For device-level recovery, see [Bootstrap MikroTik device](bootstrap-mikrotik-device.md)

## Post-incident notes

| Date | Notes |
| --- | --- |
