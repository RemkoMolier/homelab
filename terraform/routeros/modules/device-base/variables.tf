variable "identity" {
  description = "System identity (hostname) for the device"
  type        = string
}

variable "timezone" {
  description = "Timezone for the device"
  type        = string
  default     = "Europe/Berlin"
}

variable "ntp_servers" {
  description = "List of NTP server addresses"
  type        = list(string)
  default = [
    "0.de.pool.ntp.org",
    "1.de.pool.ntp.org",
    "2.de.pool.ntp.org",
    "3.de.pool.ntp.org",
  ]
}

variable "management_subnet" {
  description = "Management subnet for restricting SSH and Winbox access"
  type        = string
  default     = "172.16.1.0/24"
}

variable "terraform_host" {
  description = "IP address of the Terraform workstation for api-ssl restriction"
  type        = string
  default     = "172.16.1.245/32"
}

variable "certificate_name" {
  description = "Name of the TLS certificate for api-ssl"
  type        = string
}
