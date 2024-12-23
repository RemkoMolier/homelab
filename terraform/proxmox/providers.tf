# see https://github.com/hashicorp/terraform
terraform {
  required_version = ">=1.9.4"
  required_providers {
    # see https://registry.terraform.io/providers/hashicorp/random
    # see https://github.com/hashicorp/terraform-provider-random
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
    # see https://registry.terraform.io/providers/hashicorp/cloudinit
    # see https://github.com/hashicorp/terraform-provider-cloudinit
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.5"
    }
    # see https://registry.terraform.io/providers/bpg/proxmox
    # see https://github.com/bpg/terraform-provider-proxmox
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.3"
    }
    # see https://registry.terraform.io/providers/siderolabs/talos
    # see https://github.com/siderolabs/terraform-provider-talos
    talos = {
      source  = "siderolabs/talos"
      version = "0.6.1"
    }
    # see https://registry.terraform.io/providers/hashicorp/helm
    # see https://github.com/hashicorp/terraform-provider-helm
    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }
    # see https://registry.terraform.io/providers/hashicorp/external/
    # see https://github.com/hashicorp/terraform-provider-external
    external = {
      source  = "hashicorp/external"
      version = "2.3.4"
    }
    # see https://registry.terraform.io/providers/terraform-routeros/routeros
    # see https://github.com/terraform-routeros/terraform-provider-routeros
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.66.0"
    }
  }
}
