# Raw RouterOS resource — manages arbitrary RouterOS REST API paths.
# Used as an escape hatch for resources not yet covered by the
# terraform-provider-routeros (e.g., /interface/ethernet/switch/trunk).
#
# Uses the Mastercard/restapi provider with read_search to detect
# existing resources before creating.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    restapi = {
      source  = "Mastercard/restapi"
      version = "~> 2.0"
    }
  }
}

resource "restapi_object" "this" {
  path          = var.path
  create_method = "PUT"
  update_method = "PATCH"
  id_attribute  = ".id"

  data = jsonencode(var.data)

  read_search = {
    search_key   = var.search_key
    search_value = var.search_value
  }
}
