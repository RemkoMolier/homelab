output "id" {
  description = "The RouterOS .id of the managed resource"
  value       = restapi_object.this.id
}

output "api_data" {
  description = "The full API response data"
  value       = restapi_object.this.api_data
}
