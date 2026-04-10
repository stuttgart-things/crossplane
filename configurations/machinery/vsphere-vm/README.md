# stuttgart-things/crossplane/vsphere-vm

Crossplane Configuration for provisioning vSphere VMs using the Terraform provider.

## Overview

This configuration creates vSphere virtual machines through Crossplane using the Terraform provider. It provides a Kubernetes-native way to manage VM lifecycle in vSphere environments.

## Prerequisites

| Component | Version |
|-----------|---------|
| Crossplane | >= v1.14.1 |
| provider-helm | >= v0.19.0 |
| provider-kubernetes | >= v0.14.1 |
| provider-terraform | (required) |

## Installation

```bash
kubectl apply -f examples/provider.yaml
kubectl apply -f examples/functions.yaml
kubectl apply -f examples/cluster-provider-config.yaml
kubectl apply -f examples/configuration.yaml
```

## Prerequisites

### Create OpenTofu ClusterProviderConfig

```bash
kubectl apply -f - <<EOF
---
apiVersion: opentofu.m.upbound.io/v1beta1
kind: ClusterProviderConfig
metadata:
  name: default
spec:
  configuration: |
    terraform {
      backend "kubernetes" {
        secret_suffix    = "providerconfig-default" # pragma: allowlist secret
        namespace        = "crossplane-system"
        in_cluster_config = true
      }
    }
EOF
```

### Create TFVars Secret

The OpenTofu provider requires vSphere credentials stored as a Kubernetes secret.
The secret must exist in the **same namespace as the VsphereVM XR** (typically `default`):

```bash
kubectl create secret generic vsphere-tfvars \
  -n default \
  --from-literal=terraform.tfvars="$(cat <<EOF
vsphere_user = "<your-user>"
vsphere_password = "<your-password>"
vm_ssh_user = "<ssh-user>"
vm_ssh_password = "<ssh-password>"
vsphere_server = "<vcenter-server>"
EOF
)"
```

If using SOPS-encrypted secrets:

```bash
kubectl create secret generic vsphere-tfvars \
  -n default \
  --from-literal=terraform.tfvars="$(sops --decrypt /path/to/labul.tfvars.enc.json | \
    python3 -c 'import json,sys; [print(f"{k} = \"{v}\"") for k,v in json.load(sys.stdin).items() if k != "sops"]')"
```

### Grant RBAC for OpenTofu Provider

The OpenTofu provider service account needs permission to read secrets across namespaces.
Adjust the service account name to match your cluster's provider revision.

```bash
kubectl apply -f - <<EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: provider-opentofu-secrets
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: provider-opentofu-secrets
subjects:
- kind: ServiceAccount
  name: <provider-opentofu-service-account>
  namespace: crossplane-system
roleRef:
  kind: ClusterRole
  name: provider-opentofu-secrets
  apiGroup: rbac.authorization.k8s.io
EOF
```

To find the correct service account name:

```bash
kubectl get sa -n crossplane-system | grep opentofu
```

### DeploymentRuntimeConfig (optional)

Configure the OpenTofu provider poll interval and reconcile rate:

```bash
kubectl apply -f examples/deployment-runtime-config.yaml
```

Then link it to the provider:

```bash
kubectl patch providers.pkg.crossplane.io upbound-provider-opentofu \
  --type=merge -p '{"spec":{"runtimeConfigRef":{"name":"opentofu"}}}'
```

## Claim Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `vm.name` | string | yes | - | VM name |
| `vm.count` | string | no | `"1"` | Number of VMs to create |
| `vm.cpu` | string | yes | `"4"` | Number of vCPUs |
| `vm.ram` | string | yes | `"4096"` | Memory in MB |
| `vm.disk` | string | yes | `"64"` | Disk size in GB |
| `vm.firmware` | string | no | `"bios"` | Firmware type (`bios` or `efi`) |
| `vm.folderPath` | string | yes | - | vSphere folder path |
| `vm.datacenter` | string | yes | - | vSphere datacenter |
| `vm.datastore` | string | yes | - | vSphere datastore |
| `vm.resourcePool` | string | yes | - | vSphere resource pool |
| `vm.network` | string | yes | - | vSphere network |
| `vm.template` | string | yes | - | VM template name |
| `vm.bootstrap` | string | no | `'["echo STUTTGART-THINGS"]'` | Bootstrap commands (JSON array) |
| `vm.annotation` | string | no | `VSPHERE-VM BUILD...` | VM annotation |
| `vm.unverifiedSsl` | string | no | `"true"` | Skip SSL verification |
| `tfvars.secretName` | string | yes | - | Name of tfvars secret |
| `tfvars.secretKey` | string | no | `terraform.tfvars` | Key in the secret |
| `connectionSecret.name` | string | yes | - | Output connection secret name |
| `providerRef.name` | string | yes | - | Provider config reference |
| `providerRef.kind` | string | no | `ClusterProviderConfig` | `ProviderConfig` or `ClusterProviderConfig` |

## Usage Example

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: VsphereVM
metadata:
  name: my-vm
spec:
  providerRef:
    name: default
    kind: ClusterProviderConfig
  vm:
    name: my-vm
    count: "1"
    cpu: "4"
    ram: "4096"
    disk: "64"
    firmware: bios
    folderPath: stuttgart-things/testing
    datacenter: /LabUL
    datastore: /LabUL/datastore/UL-ESX-SAS-01
    resourcePool: /LabUL/host/Cluster-V6.5/Resources
    network: /LabUL/network/LAB-10.31.103
    template: sthings-u24
  tfvars:
    secretName: vsphere-tfvars
    secretKey: terraform.tfvars
  connectionSecret:
    name: my-vm-connection
```

## Development

### Render Composition Locally

```bash
crossplane render examples/vsphere-vm.yaml compositions/vsphere-vm.yaml examples/functions.yaml \
  --include-function-results
```

### Trace Resource

```bash
crossplane beta trace vspherevm my-vm -n default
```

## License

Apache-2.0
