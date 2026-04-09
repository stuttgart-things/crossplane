# stuttgart-things/crossplane/proxmox-vm

Crossplane Configuration for provisioning Proxmox VMs using the OpenTofu provider.

## Prerequisites

### Create OpenTofu ClusterProviderConfig

```bash
kubectl apply -f examples/provider-config.yaml
```

### Create TFVars Secret

The OpenTofu provider requires Proxmox credentials stored as a Kubernetes secret.
The secret must exist in the **same namespace as the ProxmoxVM XR** (typically `default`):

```bash
kubectl create secret generic proxmox-tfvars \
  -n default \
  --from-literal=terraform.tfvars="$(cat <<EOF
pve_api_url = "<proxmox-api-url>"
pve_api_user = "<user>@<realm>"
pve_api_password = "<password>"
vm_ssh_user = "<ssh-user>"
vm_ssh_password = "<ssh-password>"
EOF
)"
```

If using SOPS-encrypted secrets:

```bash
kubectl create secret generic proxmox-tfvars \
  -n default \
  --from-literal=terraform.tfvars="$(sops --decrypt /path/to/pve-labul.tfvars.enc.json | \
    python3 -c 'import json,sys; [print(f"{k} = \"{v}\"") for k,v in json.load(sys.stdin).items() if k != "sops"]')"
```

### Grant RBAC for OpenTofu Provider

The OpenTofu provider service account needs permission to read secrets.
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

## Claim Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `vm.name` | string | yes | - | VM name |
| `vm.count` | string | no | `"1"` | Number of VMs to create |
| `vm.cpu` | string | no | `"4"` | Number of vCPUs |
| `vm.ram` | string | no | `"4096"` | Memory in MB |
| `vm.disk` | string | no | `"32G"` | Disk size |
| `vm.firmware` | string | no | `"seabios"` | Firmware type |
| `vm.template` | string | yes | - | VM template name |
| `vm.annotation` | string | no | `PROXMOX-VM BUILD...` | VM notes |
| `proxmox.node` | string | yes | - | Proxmox cluster node |
| `proxmox.datastore` | string | yes | - | Proxmox datastore |
| `proxmox.folderPath` | string | no | - | VM folder path |
| `proxmox.network` | string | yes | - | Proxmox network bridge |
| `tfvars.secretName` | string | yes | - | Name of tfvars secret |
| `tfvars.secretKey` | string | no | `terraform.tfvars` | Key in the secret |
| `connectionSecret.name` | string | yes | - | Output connection secret name |
| `providerRef.name` | string | yes | - | Provider config reference |
| `providerRef.kind` | string | no | `ClusterProviderConfig` | `ProviderConfig` or `ClusterProviderConfig` |

## Usage Example

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: ProxmoxVM
metadata:
  name: my-vm
  namespace: default
spec:
  providerRef:
    name: default
    kind: ClusterProviderConfig
  vm:
    name: my-vm
    cpu: "4"
    ram: "8192"
    disk: "64G"
    template: ubuntu24
  proxmox:
    node: sthings-pve1
    datastore: v3700
    folderPath: stuttgart-things
    network: vmbr101
  tfvars:
    secretName: proxmox-tfvars
    secretKey: terraform.tfvars
  connectionSecret:
    name: my-vm
```

## Development

### Render Composition Locally

```bash
crossplane render examples/proxmox-vm.yaml compositions/proxmox-vm.yaml examples/functions.yaml \
  --include-function-results
```

### Trace Resource

```bash
crossplane beta trace proxmoxvm my-vm -n default
```

## License

Apache-2.0
