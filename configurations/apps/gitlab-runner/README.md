# GitlabRunner

This Crossplane Configuration provisions a `GitlabRunner` Composite Resource Definition (XRD) along with a Composition and an example Claim.

## DEV

```bash
crossplane render examples/gitlab-runner.yaml \
compositions/gitlab-runner.yaml \
examples/functions.yaml \
--include-function-results
```

```bash
crossplane beta trace GitlabRunner test-gitlab-runner
```

```bash
kubectl get releases.helm.m.crossplane.io -A
```
