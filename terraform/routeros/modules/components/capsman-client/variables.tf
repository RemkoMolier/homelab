variable "bridge_name" {
  description = "Bridge interface for WiFi datapath"
  type        = string
  default     = "bridge1"
}

variable "discovery_interface" {
  description = "Interface for CAPsMAN controller discovery"
  type        = string
  default     = "default"
}
