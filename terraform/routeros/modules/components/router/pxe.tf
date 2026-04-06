# PXE boot — netboot.xyz for network-booting servers on the management VLAN.
# Downloads boot files from netboot.xyz, uploads via SCP, and configures TFTP.

locals {
  pxe_files = {
    "netboot.xyz.kpxe"          = "https://boot.netboot.xyz/ipxe/netboot.xyz.kpxe"
    "netboot.xyz-undionly.kpxe" = "https://boot.netboot.xyz/ipxe/netboot.xyz-undionly.kpxe"
    "netboot.xyz.efi"           = "https://boot.netboot.xyz/ipxe/netboot.xyz.efi"
  }
}

# Re-uploads when filename or URL changes. For content updates at the
# same URL, taint the resource manually:
#   tofu taint 'module.rb5009.module.router.terraform_data.pxe_upload["netboot.xyz.efi"]'
resource "terraform_data" "pxe_upload" {
  for_each = local.pxe_files

  triggers_replace = [each.key, each.value]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      KEY_FILE=$(mktemp)
      BOOT_FILE=$(mktemp)
      trap 'rm -f "$KEY_FILE" "$BOOT_FILE"' EXIT
      printf '%s\n' "$SSH_PRIVATE_KEY" > "$KEY_FILE"
      chmod 600 "$KEY_FILE"
      curl -sfL -o "$BOOT_FILE" "$DOWNLOAD_URL"
      scp \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -i "$KEY_FILE" \
        "$BOOT_FILE" \
        "$SSH_USER@$SSH_HOST:$FILENAME"
    EOT
    environment = {
      SSH_PRIVATE_KEY = nonsensitive(var.ssh_private_key_pem)
      SSH_USER        = nonsensitive(var.ssh_user)
      SSH_HOST        = nonsensitive(var.ssh_host)
      DOWNLOAD_URL    = each.value
      FILENAME        = each.key
    }
  }

  depends_on = [routeros_ip_firewall_filter.input_ssh]
}

resource "routeros_ip_tftp" "pxe" {
  for_each = local.pxe_files

  req_filename  = each.key
  real_filename = each.key
  ip_addresses  = [var.management_subnet]

  depends_on = [terraform_data.pxe_upload]
}

resource "routeros_ip_dhcp_server_option" "pxe_bios" {
  name  = "pxe-bios-netboot.xyz"
  code  = 67
  value = "'netboot.xyz.kpxe'"
}

resource "routeros_ip_dhcp_server_option" "pxe_uefi" {
  name  = "pxe-uefi-netboot.xyz"
  code  = 67
  value = "'netboot.xyz.efi'"
}

resource "routeros_ip_dhcp_server_option_sets" "pxe_uefi" {
  name    = "pxe-uefi"
  options = routeros_ip_dhcp_server_option.pxe_uefi.name
}

resource "routeros_ip_dhcp_server_option_sets" "pxe_bios" {
  name    = "pxe-bios"
  options = routeros_ip_dhcp_server_option.pxe_bios.name
}

# UEFI PXE matcher — the routeros provider has no resource for
# /ip/dhcp-server/matcher, so manage it via SSH.
resource "terraform_data" "pxe_uefi_matcher" {
  triggers_replace = [
    var.management_dhcp_server,
    var.management_pool,
    routeros_ip_dhcp_server_option_sets.pxe_uefi.name,
  ]

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
      SSH_PRIVATE_KEY = nonsensitive(var.ssh_private_key_pem)
      SSH_USER        = nonsensitive(var.ssh_user)
      SSH_HOST        = nonsensitive(var.ssh_host)
      ROUTEROS_SCRIPT = join("; ", [
        ":local matcherName \"pxe-uefi-matcher\"",
        ":local existing [/ip/dhcp-server/matcher/find where name=$matcherName]",
        ":if ([:len $existing] > 0) do={ /ip/dhcp-server/matcher/set $existing server=${var.management_dhcp_server} address-pool=${var.management_pool} code=93 value=0x0007 option-set=${routeros_ip_dhcp_server_option_sets.pxe_uefi.name} } else={ /ip/dhcp-server/matcher/add name=$matcherName server=${var.management_dhcp_server} address-pool=${var.management_pool} code=93 value=0x0007 option-set=${routeros_ip_dhcp_server_option_sets.pxe_uefi.name} }",
      ])
    }
  }

  depends_on = [routeros_ip_firewall_filter.input_ssh]
}
