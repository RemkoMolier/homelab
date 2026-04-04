variable "path" {
  description = "RouterOS REST API path (e.g., /rest/interface/ethernet/switch/trunk)"
  type        = string
}

variable "data" {
  description = "Map of attributes to set on the resource"
  type        = map(string)
}

variable "search_key" {
  description = "Attribute name to search for an existing resource (e.g., 'name')"
  type        = string
}

variable "search_value" {
  description = "Attribute value to match when searching for an existing resource"
  type        = string
}
