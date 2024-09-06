resource "routeros_routing_bgp_template" "cluster" {
  name             = var.cluster_name
  as               = 64512
  address_families = "ip"
  comment          = "Managed by Terraform"
  keepalive_time   = 30
  routing_table    = "main"
}

locals {
  bgp_nodes = concat([
    for controller in local.controller_nodes :
    controller
    ], [
    for worker in local.worker_nodes :
    worker
  ])
}

resource "routeros_routing_bgp_connection" "cluster" {
  count = length(local.bgp_nodes)

  name = local.bgp_nodes[count.index].name
  as   = 64512

  depends_on = [routeros_routing_bgp_template.cluster]

  templates = [
    var.cluster_name
  ]

  comment = "Managed by Terraform"
  connect = false
  local {
    role    = "ibgp"
    address = "172.16.1.10"
    port    = 179
  }
  remote {
    address = local.bgp_nodes[count.index].address
    as      = 64512
  }

}
