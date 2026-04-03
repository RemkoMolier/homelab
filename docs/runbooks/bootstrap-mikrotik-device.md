---
title: "Bootstrap a MikroTik device for Terraform management"
owner: Remko Molier
last-verified: 2026-04-03
severity: medium
related: []
---

# Bootstrap a MikroTik device for Terraform management

## Overview

Prepare a new or factory-reset MikroTik device so that OpenTofu can manage it.
The bootstrap module in `terraform/routeros/modules/bootstrap/` automates most of this process — it detects unreachable devices and provisions them via the default HTTP REST API.
After bootstrap, the routeros module issues a TLS certificate from the internal intermediate CA and deploys the full device configuration.

## Symptoms

- New device out of the box
- Device after factory reset (`/system reset-configuration`)
- Replacement for a broken device
- `tofu plan` fails with connection refused or authentication errors

## Prerequisites

- [ ] Physical access to connect the device to the management network
- [ ] The RB5009 has a DHCP static lease configured for the device's MAC address
- [ ] The device entry exists in `terraform.tfvars.sops` with a `bootstrap_ip`
- [ ] OpenTofu and SOPS are installed (`mise install`)

### Device inventory

| IP | Device | Identity |
| --- | --- | --- |
| .10 | RB5009UG+S+IN | rb5009ug+s+in |
| .11 | CRS309-1G-8S+IN | crs309-1g-8s+ |
| .12 | CRS326-24G-2S+RM | crs326-24g-2s+ |
| .13 | CRS226-24G-2S+RM | crs226-24g-2s+ |
| .15 | hAP AX2 (Music Room) | hap-ax2-musicroom |
| .16 | hAP AX2 (Kitchen) | hap-ax2-kitchen |

## Diagnosis

1. Check if the device is reachable on HTTPS — expected result: connection refused or timeout

   ```bash
   curl -sk --connect-timeout 3 https://172.16.1.<ip>/rest/system/identity
   ```

2. Check if the device is reachable on HTTP (factory default) — expected result: JSON response

   ```bash
   curl -s --connect-timeout 3 http://192.168.88.1/rest/system/identity
   ```

3. If neither works, check physical connectivity and DHCP lease assignment

## Resolution

### Step 1: Physical setup

1. Connect the device to the management network (VLAN 1 trunk port)
2. Power on the device
3. Wait for it to boot (~30-60 seconds)

If the device has a previous configuration, factory reset it first via the hardware reset button (hold 5+ seconds) or via console:

```routeros
/system reset-configuration no-defaults=yes skip-backup=yes
```

### Step 2: Configure the tfvars entry

Ensure the device is in `terraform.tfvars.sops` with a `bootstrap_ip`.
For devices that get their management IP via DHCP, use that IP.
For fresh devices on the default config, use `192.168.88.1`:

```json
{
  "crs309": {
    "hosturl": "https://172.16.1.11",
    "username": "terraform",
    "password": "<strong-password>",
    "insecure": true,
    "bootstrap_ip": "172.16.1.11"
  }
}
```

### Step 3: Run OpenTofu

```bash
cd terraform/routeros
export TF_VAR_state_passphrase=$(gpg -d ../../local/tofu-passphrase.gpg)
tofu init
tofu apply
```

The bootstrap module will:

1. Check if the device is reachable on HTTPS
2. If not, connect via HTTP to the `bootstrap_ip`
3. Create the `terraform` user group and user
4. Generate a temporary self-signed certificate for initial api-ssl
5. Enable `api-ssl` with the certificate
6. Disable plain HTTP (`www` service)

The routeros module then takes over and:

1. Issues a proper TLS certificate from the intermediate CA (`pki/intermediate-ca/`)
2. Deploys it to the device, replacing the temporary bootstrap certificate
3. Manages the full device configuration

### Step 4: Verify

```bash
curl -sk -u terraform:PASSWORD https://172.16.1.<ip>/rest/system/identity
```

Expected result: JSON response with the device identity.

## Rollback

If the bootstrap partially completes and the device is in a bad state:

1. Factory reset via hardware button (hold 5+ seconds)
2. Taint the bootstrap resource to force re-run:

   ```bash
   tofu taint 'module.bootstrap.terraform_data.bootstrap["<device-key>"]'
   ```

3. Re-run `tofu apply`

If you need manual access during debugging:

1. Connect via **console cable** (serial 115200 baud)
2. Or use **MAC-Winbox** if it hasn't been disabled yet

## Escalation

- If the device does not respond on HTTP after factory reset, check the physical cable and that the device is on a port that allows untagged traffic
- If the DHCP lease is not assigned, verify the static lease MAC address on the RB5009
- If `tofu apply` fails with TLS errors after bootstrap, the certificate may not have been signed — taint and re-run
- MikroTik documentation: [REST API](https://help.mikrotik.com/docs/spaces/ROS/pages/47579162/REST+API)

## Post-incident notes

| Date | Notes |
| --- | --- |
