
// see https://www.talos.dev/v1.7/kubernetes-guides/network/deploying-cilium/#method-4-helm-manifests-inline-install
// see https://docs.cilium.io/en/stable/helm-reference/#helm-reference
// see https://github.com/cilium/cilium/releases
// see https://github.com/cilium/cilium/tree/v1.16.0/install/kubernetes/cilium
// see https://registry.terraform.io/providers/hashicorp/helm/latest/docs/data-sources/template
data "helm_template" "cilium" {
  namespace  = "kube-system"
  name       = "cilium"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  # renovate: datasource=helm depName=cilium registryUrl=https://helm.cilium.io
  version      = "1.16.0"
  kube_version = var.kubernetes_version
  api_versions = []
  values       = [file("../../kubernetes/infrastructure/kube-system/cilium/app/values.yaml")]
}
