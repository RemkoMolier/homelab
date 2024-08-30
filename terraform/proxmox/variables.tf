
# see https://github.com/siderolabs/talos/releases
# see https://www.talos.dev/v1.7/introduction/support-matrix/
variable "talos_version" {
  type = string
  # renovate: datasource=github-releases depName=siderolabs/talos
  default = "1.7.6"
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.talos_version))
    error_message = "Must be a version number."
  }
}

# see https://github.com/siderolabs/kubelet/pkgs/container/kubelet
# see https://www.talos.dev/v1.7/introduction/support-matrix/
variable "kubernetes_version" {
  type = string
  # renovate: datasource=github-releases depName=siderolabs/kubelet
  default = "1.30.3"
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.kubernetes_version))
    error_message = "Must be a version number."
  }
}

variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
  default     = "homelab"
}

variable "cluster_vip" {
  description = "A VIP address for the Talos cluster"
  type        = string
  default     = "172.16.1.96"
}

variable "cluster_endpoint" {
  description = "The k8s api-server (VIP) endpoint"
  type        = string
  default     = "https://172.16.1.96:6443" # k8s api-server endpoint.
}

variable "cluster_controller_count" {
  type    = number
  default = 1
  validation {
    condition     = var.cluster_controller_count >= 1
    error_message = "Must be 1 or more."
  }
}

variable "cluster_controller_vmid_start" {
  type    = number
  default = 300
}

variable "cluster_controller_tags" {
  type    = list(string)
  default = []
}

variable "cluster_controller_cores" {
  description = "The number of CPU cores to assign to a controller node"
  type        = number
  default     = 4
}

variable "cluster_controller_memory" {
  description = "The amount of memory (in MB) to assign to a controller node"
  type        = number
  default     = 4096
}

variable "cluster_controller_network" {
  description = "The IP network for the controller nodes in the cluster"
  type        = string
  default     = "172.16.1.96/29"
}

variable "cluster_controller_gateway" {
  description = "Default gateway for the controller nodes in the cluster"
  type        = string
  default     = "172.16.1.1"
}

variable "cluster_worker_count" {
  type    = number
  default = 1
  validation {
    condition     = var.cluster_worker_count >= 1
    error_message = "Must be 1 or more."
  }
}

variable "cluster_worker_vmid_start" {
  type    = number
  default = 310
}

variable "cluster_worker_tags" {
  type    = list(string)
  default = []
}

variable "cluster_worker_cores" {
  description = "The number of CPU cores to assign to a worker node"
  type        = number
  default     = 8
}

variable "cluster_worker_memory" {
  description = "The amount of memory (in MB) to assign to a worker node"
  type        = number
  default     = 16384
}

variable "cluster_worker_network" {
  description = "The IP network for the controller nodes in the cluster"
  type        = string
  default     = "172.16.1.112/28"
}

variable "cluster_worker_gateway" {
  description = "Default gateway for the worker nodes in the cluster"
  type        = string
  default     = "172.16.1.1"
}

variable "proxmox_nodes" {
  description = "List of proxmox nodes where to deploy the cluster to"
  type        = list(string)
  default     = []
}

variable "proxmox_node_iso_datastores" {
  description = "List of iso datastore names, one for each node defined in proxmox nodes, or a single name, if the same for all nodes, where to deploy images to"
  type        = list(string)
  default     = []
}

variable "proxmox_node_images_datastores" {
  description = "List of disk datastore names, one for each node defined in proxmox nodes, or a single name, if the same for all nodes, where to deploy images to"
  type        = list(string)
  default     = []
}
