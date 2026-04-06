output "device_reachable" {
  description = "Whether each device is reachable on HTTPS"
  value = {
    for k, v in data.external.device_status : k => v.result.reachable == "true"
  }
}

output "bootstrap_files" {
  description = "Paths to the generated bootstrap .rsc files"
  value = {
    for k, v in local_sensitive_file.bootstrap : k => v.filename
  }
}

output "admin_passwords" {
  description = "Random admin passwords per device (for device-base to enforce)"
  value = {
    for k, v in random_password.admin : k => v.result
  }
  sensitive = true
}
