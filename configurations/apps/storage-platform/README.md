# STORAGE-PLATFORM

## DEV

```bash
# RENDER NFS
crossplane render examples/nfs.yaml \
./compositions/storageplatform-openebs.yaml \
examples/functions.yaml \
--include-function-results
```

```bash
# RENDER OPENEBS
crossplane render examples/openebs.yaml \
./compositions/storageplatform-openebs.yaml \
examples/functions.yaml \
--include-function-results
```

```bash
crossplane beta trace
```
