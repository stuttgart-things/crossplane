# github-controller

Deploys the GitHub Actions Runner Controller (ARC) operator via Crossplane.

## Render

```bash
crossplane render examples/github-controller.yaml \
  compositions/github-controller.yaml \
  examples/functions.yaml \
  --include-function-results
```
