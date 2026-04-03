# vSphere VM

Crossplane composition that provisions vSphere virtual machines using the [xplane-provider-vspherevm](https://github.com/stuttgart-things/xplane-provider-vspherevm). Environment-specific defaults (vSphere IDs, T-shirt sizes) are externalized via `EnvironmentConfig`, keeping the composition fully portable across environments.

## API

- **Group:** `infrastructure.stuttgart-things.com`
- **Version:** `v1alpha1`
- **XR Kind:** `XVsphereVM`
- **Scope:** `Namespaced`

### Spec Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | required | Name of the virtual machine |
| `size` | string | `m` | T-shirt size (`s`/`m`/`l`) for CPU, memory, and disk |
| `numCpus` | integer | — | Number of virtual CPUs (overrides `size`) |
| `memory` | integer | — | Memory size in MB (overrides `size`) |
| `diskSize` | integer | — | Primary disk size in GB (overrides `size`) |
| `thinProvisioned` | boolean | `true` | Use thin provisioning for the disk |
| `guestId` | string | `ubuntu64Guest` | Guest OS identifier |
| `firmware` | string | `bios` | Firmware type (`bios` or `efi`) |
| `folder` | string | env default | VM folder path |
| `annotation` | string | `VSPHERE-VM BUILD w/ CROSSPLANE` | VM annotation |
| `os` | string | env default | OS template alias (e.g. `sthings-u24`), resolved from EnvironmentConfig |
| `templateUuid` | string | — | Template UUID for cloning (overrides `os` alias) |
| `resourcePool` | string | env default | Resource pool alias (e.g. `Cluster-V6.7`), resolved from EnvironmentConfig |
| `resourcePoolId` | string | — | vSphere resource pool ID (overrides `resourcePool` alias) |
| `datastore` | string | env default | Datastore alias (e.g. `UL-ESX-SAS-02`), resolved from EnvironmentConfig |
| `datastoreId` | string | — | vSphere datastore ID (overrides `datastore` alias) |
| `network` | string | env default | Network alias (e.g. `LAB-10.31.103`), resolved from EnvironmentConfig |
| `networkId` | string | — | vSphere network ID (overrides `network` alias) |
| `providerConfigName` | string | `default` | ProviderConfig to use |

### T-Shirt Sizes

Sizes are defined in the `EnvironmentConfig` and can vary per environment. Default values:

| Size | CPUs | Memory (MB) | Disk (GB) |
|------|------|-------------|-----------|
| `s` | 2 | 2048 | 32 |
| `m` | 4 | 4096 | 64 |
| `l` | 8 | 8192 | 128 |

Precedence: explicit `numCpus`/`memory`/`diskSize` > T-shirt `size` > hardcoded fallback.

### Resource Aliases

Templates, resource pools, and datastores can be referenced by human-readable aliases instead of vSphere IDs. Aliases are defined in the `EnvironmentConfig` and resolved at composition time.

| Resource | Alias field | Explicit ID field | EnvironmentConfig key |
|----------|------------|-------------------|-----------------------|
| OS Template | `os` | `templateUuid` | `templates` / `defaultOs` |
| Resource Pool | `resourcePool` | `resourcePoolId` | `resourcePools` / `defaultResourcePool` |
| Datastore | `datastore` | `datastoreId` | `datastores` / `defaultDatastore` |
| Network | `network` | `networkId` | `networks` / `defaultNetwork` |

Precedence (highest to lowest):

1. **Explicit ID** (`templateUuid`, `resourcePoolId`, `datastoreId`, `networkId`) — raw vSphere ID, always wins
2. **Alias field** (`os`, `resourcePool`, `datastore`, `network`) — looked up in the EnvironmentConfig map
3. **Default alias** (`defaultOs`, `defaultResourcePool`, `defaultDatastore`, `defaultNetwork`) — fallback from EnvironmentConfig when no alias is specified

### Status Fields

| Field | Type | Description |
|-------|------|-------------|
| `ready` | boolean | True when the VM is Ready |
| `ipAddress` | string | Primary IP address of the VM |
| `guestIpAddresses` | []string | All IP addresses reported by VMware Tools |
| `powerState` | string | Power state (`poweredOn`, `poweredOff`, `suspended`) |
| `vmwareToolsStatus` | string | VMware Tools status |
| `uuid` | string | UUID of the virtual machine |
| `moid` | string | vSphere managed object reference ID |
| `vmName` | string | Name of the VM as reported by vSphere |

### Composed Resources

| Resource | Kind | Description |
|----------|------|-------------|
| VM | `VirtualMachine` | vSphere virtual machine (xplane-provider-vspherevm) |

## EnvironmentConfig

The composition loads a `vsphere-vm-defaults` EnvironmentConfig to resolve environment-specific values. Deploy it before creating VMs:

```yaml
apiVersion: apiextensions.crossplane.io/v1beta1
kind: EnvironmentConfig
metadata:
  name: vsphere-vm-defaults
data:
  vsphere:
    defaultOs: sthings-u24
    templates:
      sthings-u24: "423483d0-5dd4-def9-5c87-94c0f513bab4"
      sthings-u22: "<uuid>"
      sthings-rh9: "<uuid>"
    defaultResourcePool: Cluster-V6.7
    resourcePools:
      Cluster-V6.7: "resgroup-481"
    defaultDatastore: UL-ESX-SAS-02
    datastores:
      UL-ESX-SAS-02: "datastore-255"
    defaultNetwork: LAB-10.31.103
    networks:
      LAB-10.31.103: "network-263"
    folder: "stuttgart-things/testing"
    sizes:
      s:
        numCpus: 2
        memory: 2048
        diskSize: 32
      m:
        numCpus: 4
        memory: 4096
        diskSize: 64
      l:
        numCpus: 8
        memory: 8192
        diskSize: 128
```

## Install

```bash
kubectl apply -f examples/functions.yaml
kubectl apply -f examples/environment-config.yaml
kubectl apply -f apis/definition.yaml
kubectl apply -f compositions/vsphere-vm.yaml
```

## Example

Minimal - uses T-shirt size and all defaults from EnvironmentConfig:

```yaml
apiVersion: infrastructure.stuttgart-things.com/v1alpha1
kind: XVsphereVM
metadata:
  name: movie-scripts5
  namespace: crossplane2
spec:
  name: movie-scripts5
  size: l
```

With explicit resources and OS alias:

```yaml
apiVersion: infrastructure.stuttgart-things.com/v1alpha1
kind: XVsphereVM
metadata:
  name: custom-vm
  namespace: crossplane2
spec:
  name: custom-vm
  numCpus: 4
  memory: 8192
  diskSize: 200
  os: sthings-u24
  firmware: efi
  annotation: "Custom VM with larger disk"
```

With explicit vSphere IDs (overrides aliases):

```yaml
apiVersion: infrastructure.stuttgart-things.com/v1alpha1
kind: XVsphereVM
metadata:
  name: custom-vm2
  namespace: crossplane2
spec:
  name: custom-vm2
  size: m
  templateUuid: "423483d0-5dd4-def9-5c87-94c0f513bab4"
  resourcePoolId: "resgroup-481"
  datastoreId: "datastore-255"
```

## Check Status

```bash
kubectl get xvspherevm movie-scripts5 -n crossplane2 -o jsonpath='{.status.ipAddress}'
kubectl get xvspherevm movie-scripts5 -n crossplane2 -o yaml
```
