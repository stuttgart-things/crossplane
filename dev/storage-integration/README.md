# MyClaim

This Crossplane Configuration provisions a `StorageIntegration` Composite Resource Definition (XRD) along with a Composition and an example Claim.

## DEV

```bash
crossplane render examples/claim.yaml \
apis/composition.yaml \
examples/functions.yaml \
--include-function-results
```
