data "talos_image_factory_extensions_versions" "image" {
  # get the latest talos version
  talos_version = var.talos_version
  filters = {
    names = [
      "iscsi-tools",
      "qemu-guest-agent",
      "util-linux-tools"
    ]
  }
}

resource "talos_image_factory_schematic" "image" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.image.extensions_info.*.name
        }
      }
    }
  )
}

locals {
  talos_nocloud_image_destinations = [
    for i, node in local.proxmox_nodes :
    {
      node_name    = node.name
      datastore_id = node.datastores.iso.id
      } if node.datastores.iso.shared == false || length([
        for j, before in local.proxmox_nodes :
        true if i > j &&
        before.datastores.iso.id == node.datastores.iso.id
    ]) == 0
  ]
}


resource "proxmox_virtual_environment_download_file" "talos_nocloud_image" {
  count = length(local.talos_nocloud_image_destinations)

  content_type = "iso"
  datastore_id = local.talos_nocloud_image_destinations[count.index].datastore_id
  node_name    = local.talos_nocloud_image_destinations[count.index].node_name

  file_name               = "talos-${var.talos_version}-nocloud-amd64.img"
  url                     = "https://factory.talos.dev/image/${talos_image_factory_schematic.image.id}/${var.talos_version}/nocloud-amd64.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}

locals {
  proxmox_nodes_with_images = [
    for i, node in local.proxmox_nodes : {
      name       = node.name
      datastores = node.datastores
      file_id = [for resource in proxmox_virtual_environment_download_file.talos_nocloud_image :
      resource.id if resource.datastore_id == node.datastores.iso.id && (node.datastores.iso.shared == true || resource.node_name == node.name)][0]
    }
  ]
}
