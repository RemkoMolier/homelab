variable "device_name" {
  description = "Device name for the certificate CN"
  type        = string
}

variable "device_ip" {
  description = "Device IP address for the certificate SAN"
  type        = string
}

variable "domain" {
  description = "Domain suffix for the certificate CN"
  type        = string
  default     = "home.molier.net"
}

variable "intermediate_ca_key_pem" {
  description = "Intermediate CA private key in PEM format"
  type        = string
  sensitive   = true
}

variable "intermediate_ca_cert_pem" {
  description = "Intermediate CA certificate in PEM format"
  type        = string
}

variable "root_ca_cert_pem" {
  description = "Root CA certificate in PEM format"
  type        = string
}

variable "validity_hours" {
  description = "Certificate validity in hours"
  type        = number
  default     = 17520 # 2 years
}
