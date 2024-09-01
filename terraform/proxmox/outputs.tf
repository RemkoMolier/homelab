output "proxmox_nodes_with_images" {
  value     = yamlencode(local.proxmox_nodes_with_images)
  sensitive = false
}

output "cilium_manifest_adapted" {
  value     = data.external.cilium_manifest.result
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
