
##########
# Cilium #
##########

# The below CiliumClusterwideNetworkPolicy resource is a split yaml doc to create a pair of global policies to replicate
# the default behaviour of Calico in the Cloud Platform:
#
# - Deny all egress to the IMDS IP (169.254.169.254) from non-system namespaces.
# - Allow all other pod/namespace egress to the internet

data "kubectl_path_documents" "policies" {
  pattern = "${path.module}/manifests/*.yaml"
}

resource "kubectl_manifest" "cilium_clusterwide_policies" {
  count     = var.enable_clusterwide_policies ? 1 : 0
  for_each  = var.enable_clusterwide_policies ? data.kubectl_path_documents.policies.manifests : {}
  yaml_body = each.value

  depends_on = [
    helm_release.cilium
  ]
}

resource "kubernetes_namespace" "cilium" {
  metadata {
    name = "cilium"

    labels = {
      "component"                          = "cilium"
      "pod-security.kubernetes.io/enforce" = "privileged"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"                = "cilium"
      "cloud-platform.justice.gov.uk/business-unit"              = "Platforms"
      "cloud-platform.justice.gov.uk/owner"                      = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"                = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "cloud-platform.justice.gov.uk/can-tolerate-master-taints" = "true"
      "cloud-platform-out-of-hours-alert"                        = "true"
    }
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

resource "helm_release" "cilium" {
  name       = "cilium"
  chart      = "cilium"
  repository = "https://helm.cilium.io/"
  namespace  = "cilium"
  timeout    = 300
  version    = "1.17.5"
  skip_crds  = true

  set = [
    {
      name  = "cni.chainingMode"
      value = "aws-cni"
    },
    {
      name  = "cni.exclusive"
      value = "false"
    },
    {
      name  = "enableIPv4Masquerade"
      value = "false"
    },
    {
      name  = "routingMode"
      value = "native"
    },
    {
      name  = "nodeSelector.network"
      value = "cilium"
    },
    {
      name  = "envoy.nodeSelector.network"
      value = "cilium"
    },
    {
      name  = "operator.nodeSelector.network"
      value = "cilium"
    }
  ]

  depends_on = [
    kubernetes_namespace.cilium
  ]
}
