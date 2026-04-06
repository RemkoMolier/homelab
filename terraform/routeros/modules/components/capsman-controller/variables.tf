variable "ssids" {
  description = "Map of WiFi SSID configurations"
  type = map(object({
    ssid                 = string
    vlan_id              = number
    authentication_types = optional(list(string), ["wpa2-psk", "wpa3-psk"])
    hide_ssid            = optional(bool, false)
    disabled             = optional(bool, false)
    client_isolation     = optional(bool, false)
    bands                = optional(list(string), ["2ghz-ax", "5ghz-ax"])
  }))
}

variable "master_ssid" {
  description = "Key from ssids map used as master configuration for provisioning"
  type        = string
}

variable "wifi_passwords" {
  description = "Map of WiFi PSK passwords by security profile name"
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "country" {
  description = "WiFi regulatory country"
  type        = string
  default     = "Germany"
}

variable "discovery_interface" {
  description = "Interface for CAPsMAN AP discovery"
  type        = string
  default     = "mgmt"
}
