variable "devices" {
  description = "Map of MikroTik devices to bootstrap"
  type = map(object({
    hosturl        = string
    username       = string
    password       = string
    insecure       = optional(bool, false)
    bootstrap_ip   = optional(string)
    bootstrap_user = optional(string, "admin")
    bootstrap_pass = optional(string, "")
  }))
}
