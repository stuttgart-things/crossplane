# ArgoInit

Crossplane composition that installs ArgoCD on a target cluster via Helm and optionally creates repository connections.

## API

```yaml
apiVersion: platform.stuttgart-things.com/v1alpha1
kind: ArgoInit
```

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `clusterName` | string | no | - | Derives provider refs as `{clusterName}-helm` / `{clusterName}-kubernetes` |
| `helmProviderConfigRef` | string | no | `{clusterName}-helm` | Helm ClusterProviderConfig name |
| `kubernetesProviderConfigRef` | string | no | `{clusterName}-kubernetes` | Kubernetes ClusterProviderConfig name |
| `namespace` | string | no | `argocd` | Target namespace for ArgoCD |
| `chart.version` | string | no | `9.4.17` | argo-cd Helm chart version |
| `chart.repoURL` | string | no | `https://argoproj.github.io/argo-helm` | Helm repository URL |
| `chart.values` | object | no | see EnvironmentConfig | Helm values override |
| `repositories[]` | array | no | `[]` | ArgoCD repository connections |
| `repositories[].name` | string | yes | - | Unique repository name |
| `repositories[].url` | string | yes | - | Repository URL (Git or Helm) |
| `repositories[].type` | string | no | `git` | `git` or `helm` |
| `repositories[].secretName` | string | no | - | Secret for private repo credentials |

## Status

| Field | Type | Description |
|-------|------|-------------|
| `chartReady` | boolean | ArgoCD Helm release is ready |
| `repositoriesReady` | boolean | All repository secrets are created |
| `ready` | boolean | All resources ready |
| `repositoryCount` | integer | Number of configured repositories |

## Resources Created

| # | Kind | Resource | Condition |
|---|------|----------|-----------|
| 1 | `helm.m.crossplane.io/v1beta1 Release` | argo-cd Helm chart | always |
| 2 | `kubernetes.m.crossplane.io/v1alpha1 Object` | Repository Secret | per `repositories[]` entry |
| 3 | `protection.crossplane.io/v1beta1 Usage` | Deletion ordering | per `repositories[]` entry |

## Dependency Chain

```
HelmRelease (argo-cd + CRDs)
    └── Repository Secrets (labeled for ArgoCD discovery)
```

## Defaults (EnvironmentConfig)

Dex and notifications are disabled by default. Override via `chart.values` if needed.

## Examples

Minimal (chart only):
```yaml
apiVersion: platform.stuttgart-things.com/v1alpha1
kind: ArgoInit
metadata:
  name: lab-argocd
  namespace: crossplane-system
spec:
  clusterName: lab-cluster
```

With repositories:
```yaml
apiVersion: platform.stuttgart-things.com/v1alpha1
kind: ArgoInit
metadata:
  name: test-argo-init
  namespace: crossplane-system
spec:
  clusterName: kind-dev-test1
  repositories:
    - name: crossplane
      url: https://github.com/stuttgart-things/crossplane.git
      type: git
    - name: argo-helm
      url: https://argoproj.github.io/argo-helm
      type: helm
```

## Render

```bash
crossplane render examples/argo-init.yaml \
  compositions/argo-init.yaml \
  examples/functions.yaml \
  --extra-resources examples/environmentconfig.yaml \
  --include-function-results
```
