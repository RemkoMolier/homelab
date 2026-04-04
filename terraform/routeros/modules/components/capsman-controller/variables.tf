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
  default     = "default"
}
