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
  path                      = var.path
  create_method             = var.create_method
  create_path               = var.create_path
  update_method             = var.update_method
  id_attribute              = var.id_attribute
  object_id                 = var.object_id
  read_path                 = var.read_path
  update_path               = var.update_path
  ignore_changes_to         = var.ignore_changes_to
  ignore_all_server_changes = var.ignore_all_server_changes

  data = jsonencode(var.data)

  read_search = var.search_key != null && var.search_value != null ? {
    search_key   = var.search_key
    search_value = var.search_value
  } : null

  lifecycle {
    # The generic REST provider is intentionally an escape hatch.
    # Read back the object after create/update and fail if the live payload
    # does not contain the values we asked RouterOS to store.
    postcondition {
      condition = alltrue([
        for key, value in var.data :
        contains(keys(self.api_data), key) && (
          contains(var.unordered_csv_keys, key)
          ? sort(compact(split(",", replace(self.api_data[key], " ", "")))) == sort(compact(split(",", replace(value, " ", ""))))
          : self.api_data[key] == value
        )
      ])
      error_message = "RouterOS REST object did not read back the expected values after apply."
    }
  }
}
