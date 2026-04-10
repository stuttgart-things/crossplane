# VirtualMachine

A high-level abstraction on top of `VMProvision` that lets you create a VM
with just 3 required fields. Provider topology and VM sizing are managed
via inline KCL environment maps inside the composition.

## Architecture

```
XVirtualMachine (3-5 fields)
  -> Composition (crossplane-contrib-function-kcl)
       |-- KCL environment map  <- datacenter / datastore / network / secrets
       |     keyed by: environment + provider
       +-- KCL size map         <- cpu / ram / disk
            -> emits VMProvision (full spec)
                 |-- VsphereVM or ProxmoxVM (OpenTofu workspace)
                 +-- AnsibleRun (optional, baseos setup via Tekton)
```

## T-shirt Sizes

| size   | cpu | ram    | disk   |
|--------|-----|--------|--------|
| small  | 2   | 2 GB   | 32 GB  |
| medium | 4   | 4 GB   | 64 GB  |
| large  | 8   | 8 GB   | 128 GB |
| xlarge | 16  | 16 GB  | 256 GB |

## Spec Fields

| field        | required | default               | description                              |
|--------------|----------|-----------------------|------------------------------------------|
| size         | yes      | -                     | small / medium / large / xlarge          |
| provider     | yes      | -                     | vsphere / proxmox                        |
| environment  | yes      | -                     | labul / labda                            |
| os           |          | ubuntu24              | ubuntu24 / ubuntu22                      |
| count        |          | 1                     | Number of VMs to create                  |
| ansible      |          | true                  | Run sthings.baseos.setup after creation  |
| providerRef  |          | default/ClusterProviderConfig | Override the ProviderConfig reference |

## Example

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: XVirtualMachine
metadata:
  name: my-dev-vm
  namespace: default
spec:
  size: medium
  provider: vsphere
  environment: labul
```

## Adding a New Environment

1. Add the environment data to the `_envs` map in `compositions/virtual-machine.yaml`
2. Add the environment name to the XRD enum in `apis/definition.yaml`

## Render

```bash
crossplane render examples/virtual-machine.yaml \
  compositions/virtual-machine.yaml \
  examples/functions.yaml \
  --include-function-results
```
