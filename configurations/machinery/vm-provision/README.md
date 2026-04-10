# stuttgart-things/crossplane/vm-provision

Unified VM provisioning with optional Ansible automation. Supports vSphere and Proxmox providers via a single API.

## Overview

This configuration combines `VsphereVM`, `ProxmoxVM`, and `AnsibleRun` into a single `VMProvision` XR. Select the infrastructure provider via `spec.provider` and optionally enable Ansible provisioning.

## Prerequisites

This configuration depends on the following sub-configurations being available on the cluster:

- `vsphere-vm` — XRD + Composition for vSphere VMs
- `proxmox-vm` — XRD + Composition for Proxmox VMs
- `ansible-run` — XRD + Composition for Ansible automation (if using ansible)

Additionally:

- OpenTofu `ClusterProviderConfig` for the VM provider
- tfvars secrets for vSphere and/or Proxmox credentials
- Ansible credentials secret (if using ansible)

See the individual configuration READMEs for setup details.

## Parameters

### Common

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `provider` | string | yes | - | `vsphere` or `proxmox` |
| `vm.name` | string | yes | - | VM name |
| `vm.count` | string | no | `"1"` | Number of VMs |
| `vm.cpu` | string | no | `"4"` | Number of vCPUs |
| `vm.ram` | string | no | `"4096"` | Memory in MB |
| `vm.disk` | string | no | `"64"` | Disk size |
| `vm.firmware` | string | no | `"bios"` | Firmware type |
| `vm.template` | string | yes | - | VM template |
| `tfvars.secretName` | string | yes | - | tfvars secret name |
| `connectionSecret.name` | string | yes | - | Connection secret name |
| `providerRef.name` | string | yes | `default` | Provider config name |
| `providerRef.kind` | string | no | `ClusterProviderConfig` | Provider config kind |

### vSphere-specific (`spec.vsphere`)

| Parameter | Required | Description |
|-----------|----------|-------------|
| `datacenter` | yes | vSphere datacenter path |
| `datastore` | yes | vSphere datastore path |
| `resourcePool` | yes | vSphere resource pool path |
| `network` | yes | vSphere network path |
| `folderPath` | yes | VM folder path |

### Proxmox-specific (`spec.proxmox`)

| Parameter | Required | Description |
|-----------|----------|-------------|
| `node` | yes | Proxmox cluster node |
| `datastore` | yes | Proxmox datastore |
| `network` | yes | Proxmox network bridge |
| `folderPath` | no | VM folder path |

### Ansible (`spec.ansible`)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable Ansible provisioning |
| `playbooks` | array | `["sthings.baseos.setup"]` | Playbooks to execute |
| `varsFile` | array | - | Ansible variables |
| `varsInventory` | array | auto (VM IP) | Inventory variables |
| `credentialsSecretName` | string | `ansible-credentials` | Ansible credentials secret |
| `pipelineNamespace` | string | `tekton-ci` | Tekton namespace |
| `crossplaneProviderConfig` | string | `dev` | K8s provider for PipelineRun |

## Usage Examples

### vSphere VM + Ansible

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: VMProvision
metadata:
  name: my-vm
  namespace: default
spec:
  provider: vsphere
  providerRef:
    name: default
    kind: ClusterProviderConfig
  vm:
    name: my-vm
    cpu: "4"
    ram: "4096"
    disk: "64"
    template: sthings-u24
  vsphere:
    folderPath: stuttgart-things/testing
    datacenter: /LabUL
    datastore: /LabUL/datastore/UL-ESX-SAS-02
    resourcePool: /LabUL/host/Cluster-V6.7/Resources
    network: /LabUL/network/LAB-10.31.103
  tfvars:
    secretName: vsphere-tfvars
  connectionSecret:
    name: my-vm
  ansible:
    enabled: true
    playbooks:
      - sthings.baseos.setup
    varsFile:
      - manage_filesystem+-true
      - update_packages+-true
      - ansible_become+-true
      - ansible_become_method+-sudo
```

### Proxmox VM (no Ansible)

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: VMProvision
metadata:
  name: my-pve-vm
  namespace: default
spec:
  provider: proxmox
  providerRef:
    name: default
    kind: ClusterProviderConfig
  vm:
    name: my-pve-vm
    cpu: "4"
    ram: "8192"
    disk: "64G"
    template: ubuntu24
  proxmox:
    node: ul-pve01
    datastore: V5010-01-1
    network: vmbr0
  tfvars:
    secretName: proxmox-tfvars
  connectionSecret:
    name: my-pve-vm
```

## Status

The XR status provides:
- `status.share.ip` — VM IP addresses
- `status.share.provider` — Which provider was used
- `status.vmReady` — Whether the VM is ready
- `status.ansibleReady` — Whether Ansible completed (true if ansible not enabled)

## Development

```bash
crossplane render examples/vm-provision.yaml \
  compositions/vm-provision.yaml \
  examples/functions.yaml \
  --include-function-results
```

## License

Apache-2.0
