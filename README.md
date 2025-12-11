# cloud-platform-terraform-cilium

[![Releases](https://img.shields.io/github/v/release/ministryofjustice/cloud-platform-terraform-template.svg)](https://github.com/ministryofjustice/cloud-platform-terraform-template/releases)

This Terraform module will create a [Cilium](https://cilium.io/) installation for use on the Cloud Platform.


## Usage

```hcl
module "cilium" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-cilium?ref=version" # use the latest release

  # Configuration
  # ...
}
```

See the [examples/](examples/) folder for more information.

## Notes

- This module is the designated component for NetworkPolicy enforcement on Cloud Platform CP30. [Calico](https://github.com/ministryofjustice/cloud-platform-terraform-tigera-calico) is now considered legacy Cloud Platform and will not be supported on new Cloud Platform clusters.

- Installing into `cilium` namespace; the Helm operator will also create a `cilium-secrets` namespace. For this reason, plus permissions required, some Gatekeeper namespace exceptions are required.

- `cilium-cli` : by default the CLI looks in `kube-system` namespace. We need to specify `-n cilium` when using it.

## Enabling Hubble

To enable Hubble and UI on your test cluster:

```
cilium hubble enable --ui -n cilium
```

and verify:

```
❯ cilium status -n cilium
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    OK
 \__/¯¯\__/    Hubble Relay:       OK
    \__/       ClusterMesh:        disabled

DaemonSet              cilium                   Desired: 6, Ready: 6/6, Available: 6/6
DaemonSet              cilium-envoy             Desired: 6, Ready: 6/6, Available: 6/6
Deployment             cilium-operator          Desired: 2, Ready: 2/2, Available: 2/2
Deployment             hubble-relay             Desired: 1, Ready: 1/1, Available: 1/1
Deployment             hubble-ui                Desired: 1, Ready: 1/1, Available: 1/1
Containers:            cilium                   Running: 6
                       cilium-envoy             Running: 6
                       cilium-operator          Running: 2
                       clustermesh-apiserver
                       hubble-relay             Running: 1
                       hubble-ui                Running: 1
```

Port forward and launch browser with:

```
cilium hubble ui -n cilium 
```
## Observations...

- `ciliumendpoint` CRDs are created for each pod at scheduling time. To get all pods in line with cilium on a test cluster, you can rollout restart all deployments/statefulsets/daemonsets.

- If you don't do the above, then vanilla `NetworkPolicy` configuruations, for example, the default ones we use in env repo, will not function:

```
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-ingress-controllers
  namespace: blah
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          component: ingress-controllers
```

If cilium is deployed post cluster install, the above NWP won't work until all interacting pods have been restarted (so ingress controllers and namespace target pods).


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=4.0.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | 2.1.3 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >=2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 2.1.3 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >=2.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.cilium](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.cilium_clusterwide_policies](https://registry.terraform.io/providers/alekc/kubectl/2.1.3/docs/resources/manifest) | resource |
| [kubernetes_namespace.cilium](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubectl_path_documents.policies](https://registry.terraform.io/providers/alekc/kubectl/2.1.3/docs/data-sources/path_documents) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->

## Tags

Some of the inputs for this module are tags. All infrastructure resources must be tagged to meet the MOJ Technical Guidance on [Documenting owners of infrastructure](https://technical-guidance.service.justice.gov.uk/documentation/standards/documenting-infrastructure-owners.html).

You should use your namespace variables to populate these. See the [Usage](#usage) section for more information.

## Reading Material

<!-- Add links to useful documentation -->

- [Cloud Platform user guide](https://user-guide.cloud-platform.service.justice.gov.uk/#cloud-platform-user-guide)
