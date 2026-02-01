# STORAGE-PLATFORM

Unified storage platform configuration supporting multiple storage backends (OpenEBS, NFS).

## How It Works

The composition automatically selects the correct resources based on `spec.engine.type`:
- `openebs` - Deploys OpenEBS via Helm chart
- `nfs` - Deploys NFS CSI driver and StorageClass

No manual composition selection needed - just set the engine type in your claim.

## DEV

```bash
# RENDER NFS
crossplane render examples/nfs.yaml \
./compositions/storageplatform.yaml \
examples/functions.yaml \
--include-function-results
```

```bash
# RENDER OPENEBS
crossplane render examples/openebs.yaml \
./compositions/storageplatform.yaml \
examples/functions.yaml \
--include-function-results
```

```bash
crossplane beta trace
```
