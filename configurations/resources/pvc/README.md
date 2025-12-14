# PersistentVolumeClaim Configuration

This Crossplane configuration enables declarative provisioning of Kubernetes PersistentVolumeClaims with support for Harvester integration.

## Overview

The PVC configuration provides:
- **Declarative API**: Create PVCs through Kubernetes custom resources
- **Harvester Integration**: Automatic image annotation and storage class mapping
- **Flexible Storage**: Support for different storage classes and volume modes
- **Multi-Namespace**: Deploy PVCs to any namespace

## Architecture

```
┌─────────────────────────────────┐
│  Claim (namespace-scoped)       │
│  apiVersion: .../v1alpha1       │
│  kind: Pvc                      │
│  spec:                          │
│    name, namespace, storage ... │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  CompositeResource (XPvc)       │
│  Reconciled by Composition      │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  KCL Function Pipeline          │
│  kcl://xplane-pvc:0.1.0         │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  PersistentVolumeClaim Resource │
│  apiVersion: v1                 │
│  kind: PersistentVolumeClaim    │
└─────────────────────────────────┘
```

## Installation

### Prerequisites
- Crossplane v1.14.0+
- `function-kcl` provider installed
- Kubernetes provider installed

### Deploy Configuration

```bash
# Install the configuration
kubectl apply -f crossplane.yaml

# Wait for it to be healthy
kubectl wait --for=condition=Healthy configuration/configuration-pvc

# Install XRD and Composition
kubectl apply -f apis/
```

## Usage

### Basic Example

```yaml
apiVersion: github.stuttgart-things.com/v1alpha1
kind: Pvc
metadata:
  name: database-storage
spec:
  name: database-storage-disk
  namespace: databases
  storage: 50Gi
  storageClass: longhorn
  imageId: default/ubuntu-22.04
```

### Harvester Integration

For Harvester clusters:

```yaml
apiVersion: github.stuttgart-things.com/v1alpha1
kind: Pvc
metadata:
  name: vm-disk
spec:
  name: fedora1-disk
  namespace: default
  storage: 100Gi
  storageClass: longhorn
  volumeMode: Block
  accessModes:
    - ReadWriteMany
  imageId: default/image-fedora43
  imageNamespace: default
```

## Configuration Reference

### Spec Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | string | ✓ | - | PVC name in Kubernetes |
| `namespace` | string | ✓ | - | Target namespace |
| `storage` | string | ✓ | - | Storage size (10Gi, 100Gi, etc.) |
| `storageClass` | string | ✗ | longhorn | Storage class for dynamic provisioning |
| `volumeMode` | string | ✗ | Block | Volume access mode (Block or Filesystem) |
| `accessModes` | array | ✗ | [ReadWriteMany] | Supported access modes |
| `imageId` | string | ✗ | default/image-default | Harvester image reference |
| `imageNamespace` | string | ✗ | default | Image namespace |

## Testing

### Local Validation

```bash
# Test rendering
crossplane render examples/claim.yaml \
                   apis/composition.yaml \
                   examples/functions.yaml

# With verbose output
crossplane render examples/claim.yaml \
                   apis/composition.yaml \
                   examples/functions.yaml \
                   --verbose
```

### Cluster Testing

```bash
# Deploy example claim
kubectl apply -f examples/claim.yaml

# Check status
kubectl get pvc

# Describe claim for details
kubectl describe pvc dev2-disk-0 -n default

# Monitor composition
kubectl get composition xplane-pvc -o wide
```

## Troubleshooting

### PVC not created

**Symptom**: Claim applied but no PVC appears

**Solutions**:
1. Check composition is active:
   ```bash
   kubectl get composition xplane-pvc
   kubectl describe composition xplane-pvc
   ```

2. Verify KCL function is available:
   ```bash
   kubectl get functions
   kubectl logs -n crossplane-system deployment/function-kcl
   ```

3. Check claim status:
   ```bash
   kubectl describe pvc dev2-disk-0
   ```

### Storage class not found

**Symptom**: PVC pending, storage class error

**Solutions**:
1. List available storage classes:
   ```bash
   kubectl get storageclass
   ```

2. Use correct storage class name in spec

3. Verify class supports volume mode:
   ```bash
   kubectl describe storageclass longhorn
   ```

### Harvester annotation missing

**Symptom**: PVC created but without `harvesterhci.io/imageId` annotation

**Solutions**:
1. Verify `imageId` is set in claim spec
2. Check KCL module correctly maps imageId parameter
3. Rebuild and republish KCL module if needed

## Contributing

To extend this configuration:

1. **Modify XRD**: Update `apis/definition.yaml` with new fields
2. **Update KCL Module**: Extend the OCI module at `xplane-pvc`
3. **Test Locally**: Use `crossplane render` to validate
4. **Document**: Update this README with new examples

## Support

- **Issues**: GitHub issues at https://github.com/stuttgart-things/crossplane
- **Discussions**: GitHub discussions for questions
- **Documentation**: See https://docs.crossplane.io

## License

Apache-2.0
