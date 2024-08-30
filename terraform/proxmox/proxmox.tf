data "proxmox_virtual_environment_nodes" "available_nodes" {}

locals {

  proxmox_selected_nodes = length(var.proxmox_nodes) > 0 ? [
    # If there are any selected nodes defined in the variable config
    for name in var.proxmox_nodes : {
      name = name
    }
    ] : [
    # Otherwise just take the names from the online nodes
    for i, name in data.proxmox_virtual_environment_nodes.available_nodes.names : {
      name = name
    } if data.proxmox_virtual_environment_nodes.available_nodes.online[i] == true
  ]



}

data "proxmox_virtual_environment_datastores" "datastores" {
  count     = length(local.proxmox_selected_nodes)
  node_name = local.proxmox_selected_nodes[count.index].name
}

locals {
  proxmox_nodes = [
    for i, node in local.proxmox_selected_nodes : {
      name = node.name

      datastores = {

        iso = concat(
          # Unless it was provided as a single entry variable
          length(var.proxmox_node_iso_datastores) == 1 ? [{
            id     = var.proxmox_node_iso_datastores[0]
            shared = data.proxmox_virtual_environment_datastores.datastores[i].shared[index(data.proxmox_virtual_environment_datastores.datastores[i].datastore_ids, var.proxmox_node_iso_datastores[0])]
          }] : [],
          # Use the entry at the same position
          length(var.proxmox_node_iso_datastores) == length(data.proxmox_virtual_environment_datastores.datastores) ? [{
            id     = var.proxmox_node_iso_datastores[i]
            shared = data.proxmox_virtual_environment_datastores.datastores[i].shared[index(data.proxmox_virtual_environment_datastores.datastores[i].datastore_ids, var.proxmox_node_iso_datastores[i])]
          }] : [],
          # Prefer enabled, active, shared, todo - with the most space available
          [
            for ds, id in data.proxmox_virtual_environment_datastores.datastores[i].datastore_ids :
            {
              id     = id
              shared = true
            } if
            data.proxmox_virtual_environment_datastores.datastores[i].active[ds] &&
            data.proxmox_virtual_environment_datastores.datastores[i].enabled[ds] &&
            data.proxmox_virtual_environment_datastores.datastores[i].shared[ds] &&
            contains(data.proxmox_virtual_environment_datastores.datastores[i].content_types[ds], "iso")
          ],
          # Otherwise look at enabled, active, not shared, todo - with the most space available
          [
            for ds, id in data.proxmox_virtual_environment_datastores.datastores[i].datastore_ids :
            {
              id     = id
              shared = false
            } if
            data.proxmox_virtual_environment_datastores.datastores[i].active[ds] &&
            data.proxmox_virtual_environment_datastores.datastores[i].enabled[ds] &&
            data.proxmox_virtual_environment_datastores.datastores[i].shared[ds] == false &&
            contains(data.proxmox_virtual_environment_datastores.datastores[i].content_types[ds], "iso")
          ],
        )[0]

        images = concat(
          # Unless it was provided as a single entry variable
          length(var.proxmox_node_images_datastores) == 1 ? [{
            name   = var.proxmox_node_images_datastores[0]
            shared = data.proxmox_virtual_environment_datastores.datastores[i].shared[index(data.proxmox_virtual_environment_datastores.datastores[i].datastore_ids, var.proxmox_node_images_datastores[0])]
          }] : [],
          # Use the entry at the same position
          length(var.proxmox_node_images_datastores) == length(data.proxmox_virtual_environment_datastores.datastores) ? [{
            name   = var.proxmox_node_images_datastores[i]
            shared = data.proxmox_virtual_environment_datastores.datastores[i].shared[index(data.proxmox_virtual_environment_datastores.datastores[i].datastore_ids, var.proxmox_node_images_datastores[i])]
          }] : [],
          # Prefer enabled, active, shared, todo - with the most space available
          [
            for ds, id in data.proxmox_virtual_environment_datastores.datastores[i].datastore_ids :
            {
              id     = id
              shared = true
            } if
            data.proxmox_virtual_environment_datastores.datastores[i].active[ds] &&
            data.proxmox_virtual_environment_datastores.datastores[i].enabled[ds] &&
            data.proxmox_virtual_environment_datastores.datastores[i].shared[ds] &&
            contains(data.proxmox_virtual_environment_datastores.datastores[i].content_types[ds], "images")
          ],
          # Otherwise look at enabled, active, not shared, todo - with the most space available
          [
            for ds, id in data.proxmox_virtual_environment_datastores.datastores[i].datastore_ids :
            {
              id     = id
              shared = false
            } if
            data.proxmox_virtual_environment_datastores.datastores[i].active[ds] &&
            data.proxmox_virtual_environment_datastores.datastores[i].enabled[ds] &&
            data.proxmox_virtual_environment_datastores.datastores[i].shared[ds] == false &&
            contains(data.proxmox_virtual_environment_datastores.datastores[i].content_types[ds], "images")
          ],
        )[0]

      }


    }
  ]

}
