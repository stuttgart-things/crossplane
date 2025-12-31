# MyClaim

This Crossplane Configuration provisions a `PipelineIntegration` Composite Resource Definition (XRD) along with a Composition and an example Claim.

## DEV

```bash
crossplane render examples/tekton-pipelines.yaml \
compositions/tekton-pipelines.yaml \
examples/functions.yaml \
--include-function-results
```
