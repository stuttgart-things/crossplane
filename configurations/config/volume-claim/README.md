# VOLUME CLAIM

## DEV

```bash
crossplane render examples/claim.yaml \
apis/composition.yaml \
examples/functions.yaml \
--include-function-results
```

```bash
crossplane beta trace volumeclaim simple-storage
```