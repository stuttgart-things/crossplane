# MyClaim

This Crossplane Configuration provisions a `NetworkIntegration` Composite Resource Definition (XRD) along with a Composition and an example Claim.

## DEV

```bash
crossplane render examples/claim-kind.yaml \
compositions/cilium.yaml \
examples/functions.yaml \
--include-function-results
```
