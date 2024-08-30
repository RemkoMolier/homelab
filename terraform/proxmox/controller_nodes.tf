locals {
  controller_nodes = [
    for i in range(var.cluster_controller_count) : {
      name    = format("%s-controller-%02d", var.cluster_name, i + 1)
      address = cidrhost(var.cluster_controller_network, i + 1)
    }
  ]
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/data-sources/machine_configuration
data "talos_machine_configuration" "controller" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = var.cluster_endpoint
  machine_secrets    = talos_machine_secrets.cluster.machine_secrets
  machine_type       = "controlplane"
  talos_version      = "v${var.talos_version}"
  kubernetes_version = var.kubernetes_version
  examples           = false
  docs               = false
  config_patches = [
    yamlencode(local.common_machine_config),
    yamlencode({
      machine = {
        network = {
          interfaces = [
            # see https://www.talos.dev/v1.7/talos-guides/network/vip/
            {
              interface = "eth0"
              vip = {
                ip = var.cluster_vip
              }
            }
          ]
        }
      }
    }),
    yamlencode({
      # see https://longhorn.io/docs/1.7.0/advanced-resources/os-distro-specific/talos-linux-support/
      machine = {
        kubelet = {
          extraMounts = [
            {
              destination = "/var/lib/longhorn"
              type        = "bind"
              source      = "/var/lib/longhorn"
              options = [
                "bind",
                "rshared",
                "rw"
              ]
            }
          ]
        }
      }
    }),
    yamlencode({
      cluster = {
        inlineManifests = [
          {
            name = "cilium"
            contents = join("---\n", [
              data.helm_template.cilium.manifest,
            ])
          }
        ],
      },
    }),
  ]
}

resource "talos_machine_configuration_apply" "controller" {
  count = length(local.controller_nodes)

  depends_on                  = [proxmox_virtual_environment_vm.controller]
  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controller.machine_configuration

  node = local.controller_nodes[count.index].address
}


resource "proxmox_virtual_environment_vm" "controller" {
  count = var.cluster_controller_count

  name        = local.controller_nodes[count.index].name
  description = "K8S controller node"
  tags        = setunion(["terraform", "talos", "kubernetes", "controller"], var.cluster_controller_tags)

  node_name = local.proxmox_nodes_with_images[count.index % length(local.proxmox_nodes)].name
  vm_id     = var.cluster_controller_vmid_start + count.index

  stop_on_destroy = true
  bios            = "ovmf"
  machine         = "q35"
  scsi_hardware   = "virtio-scsi-single"
  operating_system {
    type = "l26"
  }
  cpu {
    architecture = "x86_64"
    type         = "host"
    cores        = var.cluster_controller_cores
  }
  memory {
    dedicated = var.cluster_controller_memory
  }
  vga {
    type = "qxl"
  }
  network_device {
    bridge  = "vmbr0"
    vlan_id = 1
  }
  tpm_state {
    datastore_id = local.proxmox_nodes_with_images[count.index % length(local.proxmox_nodes)].datastores.images.id
    version      = "v2.0"
  }
  efi_disk {
    datastore_id = local.proxmox_nodes_with_images[count.index % length(local.proxmox_nodes)].datastores.images.id
    file_format  = "raw"
    type         = "4m"
  }
  disk {
    datastore_id = local.proxmox_nodes_with_images[count.index % length(local.proxmox_nodes)].datastores.images.id
    interface    = "scsi0"
    iothread     = true
    ssd          = true
    discard      = "on"
    size         = 20
    file_format  = "raw"
    file_id      = local.proxmox_nodes_with_images[count.index % length(local.proxmox_nodes)].file_id
  }
  agent {
    enabled = true
    trim    = true
  }
  initialization {
    datastore_id = local.proxmox_nodes_with_images[count.index % length(local.proxmox_nodes)].datastores.images.id
    ip_config {
      ipv4 {
        address = "${local.controller_nodes[count.index].address}/24"
        gateway = var.cluster_controller_gateway
      }
    }
  }
  startup {
    order      = count.index == 0 ? "10" : "30"
    up_delay   = 30
    down_delay = 30
  }
}
