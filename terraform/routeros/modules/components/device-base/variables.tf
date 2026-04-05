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

variable "dns_servers" {
  description = "List of DNS servers used by the device"
  type        = list(string)
  default     = ["172.16.1.1"]
}

variable "manage_dns_settings" {
  description = "Whether the shared device base should manage /ip dns on this device"
  type        = bool
  default     = true
}

variable "management_interface" {
  description = "Bridge interface for the management VLAN"
  type        = string
  default     = "bridge1"
}

variable "management_vlan_id" {
  description = "VLAN ID for management access"
  type        = number
  default     = 1
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

variable "terraform_user_name" {
  description = "Bootstrap Terraform user that should receive an SSH public key"
  type        = string
  default     = "terraform"
}

variable "certificate_name" {
  description = "Name of the TLS certificate for api-ssl and www-ssl"
  type        = string
}

variable "domain" {
  description = "Domain suffix for certificate common name"
  type        = string
  default     = "home.molier.net"
}

variable "cert_pem" {
  description = "CA-signed device certificate in PEM format"
  type        = string
  default     = null
}

variable "import_signed_certificate" {
  description = "Whether to import the device certificate into RouterOS"
  type        = bool
  default     = false
}

variable "key_pem" {
  description = "Device private key in PEM format"
  type        = string
  sensitive   = true
  default     = null
}

variable "ca_cert_pem" {
  description = "Intermediate CA certificate in PEM format"
  type        = string
  default     = null
}

variable "import_ca_certificate" {
  description = "Whether to import the intermediate CA certificate into RouterOS"
  type        = bool
  default     = false
}

variable "root_ca_cert_pem" {
  description = "Root CA certificate in PEM format"
  type        = string
  default     = null
}

variable "import_root_certificate" {
  description = "Whether to import the root CA certificate into RouterOS"
  type        = bool
  default     = false
}


variable "wan_interfaces" {
  description = "Map of WAN interfaces with DHCP client and/or masquerade"
  type = map(object({
    dhcp_client = optional(bool, true)
    masquerade  = optional(bool, true)
  }))
  default = {}
}

variable "device_ip" {
  description = "Device management IP (for SSH access during provisioning)"
  type        = string
  default     = null
}

variable "default_route" {
  description = "Default route gateway. Set to a gateway IP to manage a static default route, or null to remove the bootstrap route."
  type        = string
  default     = null
}

variable "users" {
  description = "Map of user accounts to create on the device"
  type = map(object({
    password = string
    group    = string
  }))
  default = {}
}
