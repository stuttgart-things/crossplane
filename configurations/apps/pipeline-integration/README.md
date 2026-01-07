# MyClaim

This Crossplane Configuration provisions a `PipelineIntegration` Composite Resource Definition (XRD) along with a Composition and an example Claim.

## DEV

```bash
crossplane render examples/tekton-pipelines.yaml \
compositions/tekton-pipelines.yaml \
examples/functions.yaml \
--include-function-results
```

kubectl get clusterproviderconfig.helm.m.crossplane.io -A
kubectl get providerconfig.helm.m.crossplane.io -A
kubectl get release.helm.m.crossplane.io
