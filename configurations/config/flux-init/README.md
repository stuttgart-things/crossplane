# FluxInit

Crossplane configuration that bootstraps [Flux](https://fluxcd.io/) on a target cluster via the [flux-operator](https://github.com/controlplaneio-fluxcd/flux-operator). It installs the operator Helm chart, creates a FluxInstance CR, and optionally provisions OCI/Git source repositories for GitOps sync.

## Resources Created

| # | Kind | Description | Condition |
|---|------|-------------|-----------|
| 1 | `helm.m.crossplane.io/v1beta1 Release` | flux-operator Helm chart | always |
| 2 | `kubernetes.m.crossplane.io/v1alpha1 Object` | FluxInstance CR | always |
| 3..N | `kubernetes.m.crossplane.io/v1alpha1 Object` | OCIRepository / GitRepository CRs | per entry in `sources` |

Resource ordering is enforced via `crossplane.io/uses`: operator -> instance -> sources.

## API Reference

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: FluxInitClaim
spec:
  helmProviderConfigRef: ""        # required - Helm ClusterProviderConfig name
  kubernetesProviderConfigRef: ""  # required - Kubernetes ClusterProviderConfig name
  namespace: flux-system           # optional, default: flux-system
  operatorChart:                   # optional, defaults from EnvironmentConfig
    version: "0.45.1"
    repoURL: "oci://ghcr.io/controlplaneio-fluxcd/charts"
  instance:                        # optional, defaults from EnvironmentConfig
    distribution: "2.x"
    components:                    # optional, default: source/kustomize/helm/notification-controller
      - source-controller
      - kustomize-controller
      - helm-controller
      - notification-controller
    sources:                       # optional - omit to install controllers only
      - name: ""                   # required - unique name for this source
        kind: OCIRepository        # optional, default: OCIRepository, enum: [OCIRepository, GitRepository]
        url: ""                    # required - OCI or Git URL
        ref: latest                # optional, default: latest
        path: "."                  # optional, default: "."
        pullSecret: ""             # optional - secret name for private registries
```

## Usage Examples

### Minimal - Controllers Only (No Sync Source)

Installs Flux controllers on the target cluster without configuring any GitOps source.

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: FluxInitClaim
metadata:
  name: lab-flux
  namespace: crossplane-system
spec:
  helmProviderConfigRef: lab-cluster-helm
  kubernetesProviderConfigRef: lab-cluster-kubernetes
```

### Single OCI Source

Installs Flux and syncs from a single OCI registry.

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: FluxInitClaim
metadata:
  name: staging-flux
  namespace: crossplane-system
spec:
  helmProviderConfigRef: staging-helm
  kubernetesProviderConfigRef: staging-kubernetes
  instance:
    sources:
      - name: fleet-infra
        url: oci://ghcr.io/stuttgart-things/fleet-infra
        ref: latest
        path: clusters/staging
```

### Multiple Sources with Private Registry

Installs Flux with multiple OCI sources and a pull secret for private access.

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: FluxInitClaim
metadata:
  name: prod-flux
  namespace: crossplane-system
spec:
  helmProviderConfigRef: prod-helm
  kubernetesProviderConfigRef: prod-kubernetes
  instance:
    sources:
      - name: flux-infra
        kind: OCIRepository
        url: oci://ghcr.io/stuttgart-things/flux-infra
        ref: v1.2.0
        path: clusters/prod
        pullSecret: ghcr-credentials
      - name: flux-apps
        kind: OCIRepository
        url: oci://ghcr.io/stuttgart-things/flux-apps
        ref: v1.2.0
        path: clusters/prod
        pullSecret: ghcr-credentials
```

### Custom Chart Version and Distribution

Override operator chart version and Flux distribution.

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: FluxInitClaim
metadata:
  name: custom-flux
  namespace: crossplane-system
spec:
  helmProviderConfigRef: custom-helm
  kubernetesProviderConfigRef: custom-kubernetes
  operatorChart:
    version: "0.45.1"
    repoURL: "oci://ghcr.io/controlplaneio-fluxcd/charts"
  instance:
    distribution: "2.4.0"
    components:
      - source-controller
      - kustomize-controller
      - helm-controller
```

### XR (Composite Resource) - Non-Claim Usage

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: FluxInit
metadata:
  name: dev-cluster-flux
spec:
  helmProviderConfigRef: dev-cluster-helm
  kubernetesProviderConfigRef: dev-cluster-kubernetes
  instance:
    sources:
      - name: flux-infra
        kind: OCIRepository
        url: oci://ghcr.io/stuttgart-things/flux-infra
        ref: latest
        path: "."
      - name: flux-apps
        kind: OCIRepository
        url: oci://ghcr.io/stuttgart-things/flux-apps
        ref: latest
        path: "."
```

## Status

The XR reports readiness per resource group:

| Field | Description |
|-------|-------------|
| `operatorReady` | flux-operator Helm release is ready |
| `instanceReady` | FluxInstance CR is ready |
| `sourcesReady` | All source objects are ready (true if no sources defined) |
| `ready` | All of the above are true |
| `sourceCount` | Number of source objects created |

## Prerequisites

- Crossplane v2.13.0+
- `provider-helm` and `provider-kubernetes` installed
- `ClusterProviderConfig` resources for the target cluster (Helm + Kubernetes)
- `EnvironmentConfig` named `flux-defaults` (see `examples/environmentconfig.yaml`)

## DEV

```bash
crossplane render examples/flux-init.yaml \
  compositions/flux-init.yaml \
  examples/functions.yaml \
  --include-function-results \
  --context-files='apiextensions.crossplane.io/environment=examples/environment.json' \
  --extra-resources=examples/environmentconfig.yaml
```
