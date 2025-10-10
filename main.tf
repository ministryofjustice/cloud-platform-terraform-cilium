
##########
# Cilium #
##########

# The below CiliumClusterwideNetworkPolicy resource is a split yaml doc to create a pair of global policies to replicate
# the default behaviour of Calico in the Cloud Platform:
#
# - Deny all egress to the IMDS IP (169.254. 169.254) from non-system namespaces.
# - Allow all other pod/namespace egress to the internet

resource "kubectl_manifest" "cilium_clusterwide_policies" {
  yaml_body = <<YAML
apiVersion: cilium.io/v2
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: deny-imds-non-system
spec:
  endpointSelector:
    matchExpressions:
      - key: "k8s:io.kubernetes.pod.namespace"
        operator: NotIn
        values:
          - cert-manager
          - ingress-controllers
          - kube-system
          - logging
          - monitoring
          - velero
  egressDeny:
    - toCIDR:
        - 169.254.169.254/32
      toPorts:
        - ports:
            - port: "80"
              protocol: TCP
            - port: "443"
              protocol: TCP
  enableDefaultDeny:
    egress: false
    ingress: false
---
apiVersion: cilium.io/v2
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: allow-all-egress-internet
spec:
  endpointSelector: {}
  egress:
    - toCIDR:
        - 0.0.0.0/0
  enableDefaultDeny:
    egress: false
    ingress: false
YAML

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
    }
  ]

  depends_on = [
    kubernetes_namespace.cilium
  ]
}