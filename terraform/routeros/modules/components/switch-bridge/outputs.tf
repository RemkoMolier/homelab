output "bridge_name" {
  description = "Name of the bridge interface"
  value       = routeros_interface_bridge.this.name
}
