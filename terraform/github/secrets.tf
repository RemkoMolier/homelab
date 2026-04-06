data "sops_file" "config" {
  source_file = "${path.root}/terraform.tfvars.sops.json"
}

locals {
  secrets = jsondecode(data.sops_file.config.raw)["secrets"]
}
