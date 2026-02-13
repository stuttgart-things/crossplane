# github-runner

Deploys GitHub Actions Runner Scale Sets via Crossplane.

## Render

```bash
crossplane render examples/github-runner.yaml \
  compositions/github-runner.yaml \
  examples/functions.yaml \
  --include-function-results
```
