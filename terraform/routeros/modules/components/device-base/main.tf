# Device base module — common configuration applied to every MikroTik device.
# Handles system identity, clock, NTP, service hardening, and access control.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "~> 1.99"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# --- System info ---

data "routeros_system_routerboard" "this" {}


# --- System ---

resource "routeros_system_identity" "this" {
  name = var.identity
}

resource "routeros_system_clock" "this" {
  time_zone_name = var.timezone
}

resource "routeros_system_ntp_client" "this" {
  enabled = true
  servers = var.ntp_servers
}

resource "routeros_ip_dns" "this" {
  count   = var.manage_dns_settings ? 1 : 0
  servers = var.dns_servers
}

# --- Services ---

resource "routeros_ip_service" "ssh" {
  numbers  = "ssh"
  port     = 22
  disabled = false
  address  = var.management_subnet
}

resource "routeros_ip_service" "winbox" {
  numbers  = "winbox"
  port     = 8291
  disabled = false
  address  = var.management_subnet
}

resource "routeros_ip_service" "api_ssl" {
  numbers     = "api-ssl"
  port        = 8729
  disabled    = false
  address     = var.terraform_host
  certificate = var.certificate_name

  depends_on = [
    routeros_system_certificate.signed_cert,
    routeros_system_certificate.ca,
  ]
}

resource "routeros_ip_service" "www_ssl" {
  numbers     = "www-ssl"
  port        = 443
  disabled    = false
  address     = var.management_subnet
  certificate = var.certificate_name

  depends_on = [
    routeros_system_certificate.signed_cert,
    routeros_system_certificate.ca,
  ]
}

resource "routeros_ip_service" "ftp" {
  numbers  = "ftp"
  port     = 21
  disabled = true
}

resource "routeros_ip_service" "telnet" {
  numbers  = "telnet"
  port     = 23
  disabled = true
}

resource "routeros_ip_service" "www" {
  numbers  = "www"
  port     = 80
  disabled = true
}

resource "routeros_ip_service" "api" {
  numbers  = "api"
  port     = 8728
  disabled = true
}

# --- User groups ---

locals {
  # "full" is a built-in RouterOS group — use it directly, don't create it
  builtin_groups = toset(["full", "read", "write"])
  custom_group_policies = {
    read-only = toset(["local", "ssh", "read", "winbox", "api", "rest-api"])
  }
  custom_groups = nonsensitive(toset([for u in var.users : u.group if !contains(local.builtin_groups, u.group)]))
}

resource "routeros_system_user_group" "groups" {
  for_each = local.custom_groups

  name   = each.value
  policy = lookup(local.custom_group_policies, each.value, toset([]))

  lifecycle {
    precondition {
      condition     = contains(keys(local.custom_group_policies), each.value)
      error_message = "Group \"${each.value}\" has no policy defined in custom_group_policies. Valid custom groups: ${join(", ", keys(local.custom_group_policies))}."
    }
  }
}

# --- User accounts ---

resource "routeros_system_user" "users" {
  for_each = nonsensitive(var.users)

  name     = each.key
  group    = each.value.group
  password = each.value.password
}

# --- Disable default admin account ---

resource "routeros_system_user" "admin" {
  name     = "admin"
  group    = "full"
  password = var.admin_password
  disabled = true

  depends_on = [
    routeros_system_user.users,
    routeros_system_user_group.terraform,
  ]
}

# --- Terraform SSH key ---

resource "tls_private_key" "terraform_ssh" {
  algorithm = "ED25519"
}

resource "routeros_system_user_sshkeys" "terraform" {
  user    = var.terraform_user_name
  key     = tls_private_key.terraform_ssh.public_key_openssh
  comment = "Terraform"
}

# Grant SSH access to the terraform group only after the key is in place.
# Bootstrap creates this group without the ssh policy so password-only
# SSH is never possible for the terraform user.
resource "routeros_system_user_group" "terraform" {
  name   = "terraform"
  policy = toset(["api", "ftp", "read", "write", "policy", "test", "sensitive", "web", "rest-api", "ssh"])

  depends_on = [routeros_system_user_sshkeys.terraform]
}

# --- Management VLAN interface ---
# Bootstrap creates this interface and places the management IP on it.
# Terraform imports and manages it from here.

resource "routeros_interface_vlan" "management" {
  name      = "mgmt"
  vlan_id   = var.management_vlan_id
  interface = var.management_interface
  comment   = "Management VLAN"
}

# --- CA-signed certificate ---
# Import the CA-signed certificate directly into the RouterOS certificate
# store, replacing the bootstrap self-signed cert for api-ssl and www-ssl.

resource "routeros_system_certificate" "signed_cert" {
  count       = var.import_signed_certificate ? 1 : 0
  name        = var.certificate_name
  common_name = "${var.identity}.${var.domain}"
  import {
    cert_file_content = var.cert_pem
    key_file_content  = var.key_pem
  }

  depends_on = [routeros_system_certificate.ca]
}

resource "routeros_system_certificate" "ca" {
  count       = var.import_ca_certificate ? 1 : 0
  name        = "intermediate-ca"
  common_name = "Homelab Intermediate CA"
  import {
    cert_file_content = var.ca_cert_pem
  }

  depends_on = [routeros_system_certificate.root_ca]
}

resource "routeros_system_certificate" "root_ca" {
  count       = var.import_root_certificate ? 1 : 0
  name        = "root-ca"
  common_name = "Homelab Root CA"
  import {
    cert_file_content = var.root_ca_cert_pem
  }
}

# --- SSH hardening ---

resource "routeros_ip_ssh_server" "this" {
  strong_crypto               = true
  always_allow_password_login = false
}

# --- Discovery and MAC server ---

resource "routeros_interface_list" "management" {
  name = "mgmt-list"
}

resource "routeros_interface_list_member" "management_default" {
  interface = routeros_interface_vlan.management.name
  list      = routeros_interface_list.management.name
}

resource "routeros_tool_mac_server" "this" {
  allowed_interface_list = routeros_interface_list.management.name
}

resource "routeros_tool_mac_server_winbox" "this" {
  allowed_interface_list = routeros_interface_list.management.name
}

resource "routeros_ip_neighbor_discovery_settings" "this" {
  discover_interface_list = routeros_interface_list.management.name
}

# --- WAN interfaces ---

resource "routeros_ip_dhcp_client" "wan" {
  for_each = { for k, v in var.wan_interfaces : k => v if v.dhcp_client }

  interface         = each.key
  add_default_route = "yes"
  comment           = "WAN DHCP"
}

# --- Default route ---
# Manages the bootstrap static default route.
# If default_route is set, update it to the desired gateway.
# If null, remove the bootstrap route (e.g., when WAN DHCP provides one).

resource "terraform_data" "default_route" {
  count = var.device_ip != null ? 1 : 0

  triggers_replace = [var.default_route]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      KEY_FILE=$(mktemp)
      trap 'rm -f "$KEY_FILE"' EXIT
      printf '%s\n' "$SSH_PRIVATE_KEY" > "$KEY_FILE"
      chmod 600 "$KEY_FILE"
      ssh \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -i "$KEY_FILE" \
        "$SSH_USER@$SSH_HOST" \
        "$ROUTEROS_SCRIPT"
    EOT
    environment = {
      SSH_PRIVATE_KEY = nonsensitive(tls_private_key.terraform_ssh.private_key_pem)
      SSH_USER        = nonsensitive(var.terraform_user_name)
      SSH_HOST        = nonsensitive(var.device_ip)
      ROUTEROS_SCRIPT = var.default_route != null ? join("; ", [
        ":local ids [/ip/route/find where dst-address=\"0.0.0.0/0\" comment=\"Default gateway\"]",
        ":if ([:len $ids] > 0) do={ /ip/route/set $ids gateway=${var.default_route} } else={ /ip/route/add dst-address=0.0.0.0/0 gateway=${var.default_route} comment=\"Default gateway\" }",
        ]) : join("; ", [
        ":local ids [/ip/route/find where dst-address=\"0.0.0.0/0\" comment=\"Default gateway\"]",
        ":if ([:len $ids] > 0) do={ /ip/route/remove $ids }",
      ])
    }
  }

  depends_on = [routeros_system_user_group.terraform]
}

resource "routeros_ip_firewall_nat" "masquerade" {
  for_each = { for k, v in var.wan_interfaces : k => v if v.masquerade }

  chain         = "srcnat"
  action        = "masquerade"
  out_interface = each.key
  comment       = "Masquerade outbound traffic (${each.key})"
}
