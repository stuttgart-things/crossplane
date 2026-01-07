# Volume Claim - Crossplane Configuration

A DRY (Don't Repeat Yourself) Crossplane configuration for managing PersistentVolumeClaims across any storage backend.

## Overview

This configuration provides a universal PersistentVolumeClaim abstraction that works seamlessly with any Kubernetes storage provider including Harvester, Longhorn, Rook-Ceph, and standard storage classes.

## Features

- **Universal Storage Support**: Works with Harvester, Longhorn, Rook-Ceph, and any Kubernetes storage provider
- **Custom Annotations**: Support for storage-specific annotations (e.g., `harvesterhci.io/imageId`)
- **Flexible Configuration**: Optional labels, selectors, volume modes, and data sources for advanced use cases
- **Simple Interface**: Clean API that abstracts the complexity of PVC management

## Usage

### Simple Example

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: VolumeClaim
metadata:
  name: simple-storage
  namespace: default
spec:
  providerConfigRef: in-cluster
  pvcName: app-data
  namespace: default
  storageClassName: standard
  storage: "1Gi"
```

### Harvester VM Disk Example

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: VolumeClaim
metadata:
  name: ubuntu-vm-disk
spec:
  providerConfigRef: kubernetes-provider
  pvcName: ubuntu-vm-root
  namespace: vms
  storageClassName: longhorn-ubuntu-22.04
  storage: "100Gi"
  volumeMode: Block
  annotations:
    harvesterhci.io/imageId: "harvester-public/ubuntu-22.04"
    description: "Ubuntu 22.04 VM root disk"
  labels:
    app: web-server
    environment: production
```

## Development

### Render the Composition

Test the template rendering without applying to the cluster:

```bash
crossplane render examples/claim.yaml \
  apis/composition.yaml \
  examples/functions.yaml \
  --include-function-results
```

### Trace Resource Status

Monitor the composition status and track created resources:

```bash
crossplane beta trace volumeclaim simple-storage
```

## Files

- `apis/composition.yaml` - Crossplane Composition definition
- `examples/claim.yaml` - Example VolumeClaim resource
- `examples/functions.yaml` - Function definitions (if applicable)

## Requirements

- Crossplane >= v1.14.1
- Provider Kubernetes >= v1.2.0
- Function Go Templating >= v0.11.3
- Function Auto Ready >= v0.6.0
