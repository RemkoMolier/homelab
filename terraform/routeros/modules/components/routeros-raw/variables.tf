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
  default     = null
}

variable "search_value" {
  description = "Attribute value to match when searching for an existing resource"
  type        = string
  default     = null
}

variable "create_method" {
  description = "HTTP method for creating the resource (PUT for new entries, PATCH for singletons)"
  type        = string
  default     = "PUT"
}

variable "create_path" {
  description = "Optional custom create path. Use this when writes go through a command endpoint such as /set."
  type        = string
  default     = null
}

variable "update_method" {
  description = "HTTP method for updating the resource"
  type        = string
  default     = "PATCH"
}

variable "read_path" {
  description = "Optional custom read path. Use this for collection-style APIs when read_search must operate on the collection path."
  type        = string
  default     = null
}

variable "update_path" {
  description = "Optional custom update path. Use this when writes go through a command endpoint such as /set."
  type        = string
  default     = null
}

variable "ignore_changes_to" {
  description = "Optional list of remote fields to ignore when the API returns extra/default attributes that should not cause drift."
  type        = list(string)
  default     = []
}

variable "ignore_all_server_changes" {
  description = "Ignore server-side fields when the API returns a noisier shape than the desired payload. Pair with postconditions for explicit verification of required fields."
  type        = bool
  default     = false
}

variable "unordered_csv_keys" {
  description = "Keys whose values should be verified as comma-separated sets rather than exact strings."
  type        = list(string)
  default     = []
}

variable "id_attribute" {
  description = "Field used as the resource identity in API responses."
  type        = string
  default     = ".id"
}

variable "object_id" {
  description = "Known resource ID. If set, the provider reads the resource first and adopts it into state instead of creating."
  type        = string
  default     = null
}
