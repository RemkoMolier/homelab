output "proxmox_nodes" {
  value     = yamlencode(local.proxmox_nodes)
  sensitive = false
}

output "proxmox_virtual_environment_datastores" {
  value     = yamlencode(data.proxmox_virtual_environment_datastores.datastores)
  sensitive = false
}

output "talos_nocloud_image_destinations" {
  value     = yamlencode(local.talos_nocloud_image_destinations)
  sensitive = false
}

output "proxmox_nodes_with_images" {
  value     = yamlencode(local.proxmox_nodes_with_images)
  sensitive = false
}

output "talosconfig" {
  value     = data.talos_client_configuration.cluster.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.cluster.kubeconfig_raw
  sensitive = true
}
