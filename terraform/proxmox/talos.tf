locals {

  common_machine_config = {
    machine = {
      # NB the install section changes are only applied after a talos upgrade
      #    (which we do not do). instead, its preferred to create a custom
      #    talos image, which is created in the installed state.
      #install = {}
      features = {
        # see https://www.talos.dev/v1.7/kubernetes-guides/configuration/kubeprism/
        # see talosctl -n $c0 read /etc/kubernetes/kubeconfig-kubelet | yq .clusters[].cluster.server
        # NB if you use a non-default CNI, you must configure it to use the
        #    https://localhost:7445 kube-apiserver endpoint.
        kubePrism = {
          enabled = true
          port    = 7445
        }
      }
    }
    cluster = {
      # see https://www.talos.dev/v1.7/talos-guides/discovery/
      # see https://www.talos.dev/v1.7/reference/configuration/#clusterdiscoveryconfig
      discovery = {
        enabled = true
        registries = {
          kubernetes = {
            disabled = false
          }
          service = {
            disabled = true
          }
        }
      }
      network = {
        cni = {
          name = "none"
        }
      }
      proxy = {
        disabled = true
      }
    }
  }
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/resources/machine_secrets
resource "talos_machine_secrets" "cluster" {
  talos_version = "v${var.talos_version}"
}

data "talos_client_configuration" "cluster" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.cluster.client_configuration
  endpoints            = [for node in local.controller_nodes : node.address]
}



// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/resources/machine_bootstrap
resource "talos_machine_bootstrap" "cluster" {
  client_configuration = talos_machine_secrets.cluster.client_configuration
  endpoint             = local.controller_nodes[0].address
  node                 = local.controller_nodes[0].address
  depends_on = [
    talos_machine_configuration_apply.controller,
  ]
}

data "talos_cluster_health" "health" {
  depends_on           = [talos_machine_configuration_apply.controller, talos_machine_configuration_apply.worker]
  client_configuration = talos_machine_secrets.cluster.client_configuration
  control_plane_nodes  = [for controller in local.controller_nodes : controller.address]
  worker_nodes         = [for worker in local.worker_nodes : worker.address]
  endpoints            = data.talos_client_configuration.cluster.endpoints
}


// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/data-sources/cluster_kubeconfig
resource "talos_cluster_kubeconfig" "cluster" {
  client_configuration = talos_machine_secrets.cluster.client_configuration
  endpoint             = local.controller_nodes[0].address
  node                 = local.controller_nodes[0].address
  depends_on = [
    talos_machine_bootstrap.cluster,
  ]
}
