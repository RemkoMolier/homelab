output "vlan_aware_ports" {
  description = "Set of all VLAN-aware ports (for drop-if-invalid enforcement)"
  value       = local.vlan_aware_ports
}
