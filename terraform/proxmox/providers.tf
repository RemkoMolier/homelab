# see https://github.com/hashicorp/terraform
terraform {
  required_version = ">=1.9.4"
  required_providers {
    # see https://registry.terraform.io/providers/hashicorp/random
    # see https://github.com/hashicorp/terraform-provider-random
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
    # see https://registry.terraform.io/providers/hashicorp/cloudinit
    # see https://github.com/hashicorp/terraform-provider-cloudinit
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.4"
    }
    # see https://registry.terraform.io/providers/bpg/proxmox
    # see https://github.com/bpg/terraform-provider-proxmox
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.63.0"
    }
    # see https://registry.terraform.io/providers/siderolabs/talos
    # see https://github.com/siderolabs/terraform-provider-talos
    talos = {
      source  = "siderolabs/talos"
      version = "0.6.0-alpha.1"
    }
    # see https://registry.terraform.io/providers/hashicorp/helm
    # see https://github.com/hashicorp/terraform-provider-helm
    helm = {
      source  = "hashicorp/helm"
      version = "2.15.0"
    }
    # see https://registry.terraform.io/providers/hashicorp/external/
    # see https://github.com/hashicorp/terraform-provider-external
    external = {
      source  = "hashicorp/external"
      version = "2.3.3"
    }
  }
}
