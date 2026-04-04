output "model" {
  description = "Device model from RouterOS system routerboard"
  value       = data.routeros_system_routerboard.this.model
}
