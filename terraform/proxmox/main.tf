provider "proxmox" {
}

provider "talos" {
}

provider "helm" {
  experiments {
    manifest = true
  }
}
