# MikroTik RouterOS infrastructure
#
# Architecture:
#   - locals.tf      — shared VLAN and firewall zone definitions
#   - device-*.tf    — per-device provider, module composition, and port maps
#   - modules/       — reusable modules by concern
#
# Two-phase lifecycle:
#   1. Bootstrap module provisions fresh devices via HTTP REST API
#   2. Device modules manage configuration via HTTPS (routeros provider)
#
# Certificates are issued by the intermediate CA (pki/intermediate-ca/)
# using the tls provider. CA keys are decrypted transparently by git-crypt.

