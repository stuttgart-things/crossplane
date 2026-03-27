# ClusterProfile

Crossplane composition that nests GitOps (Flux/Argo), DNS, and Vault sub-compositions into a single claim. Currently integrates `XFluxInit` with conditional engine selection (`flux` or `argocd`).

## API

- **Group:** `platform.sthings.de`
- **Version:** `v1alpha1`
- **XR Kind:** `XClusterProfile`
- **Claim Kind:** `ClusterProfileClaim`

### Spec Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `helmProviderConfigRef` | string | yes | | Helm ClusterProviderConfig name |
| `kubernetesProviderConfigRef` | string | yes | | Kubernetes ClusterProviderConfig name |
| `gitops.engine` | string | no | `flux` | GitOps engine (`flux` or `argocd`) |
| `flux` | object | no | | Flux-specific overrides passed to XFluxInit |
| `flux.namespace` | string | no | | Override flux namespace |
| `flux.operatorChart.version` | string | no | | Override operator chart version |
| `flux.operatorChart.repoURL` | string | no | | Override operator chart repo |
| `flux.instance.distribution` | string | no | | Override flux distribution |
| `flux.instance.components` | []string | no | | Override flux components |
| `flux.instance.sources` | []object | no | | OCI/Git sources for flux |

### Status Fields

| Field | Type | Description |
|-------|------|-------------|
| `ready` | boolean | True when all sub-compositions are Ready |
| `gitopsEngine` | string | Active engine (`flux` or `argocd`) |
| `gitopsReady` | boolean | True when gitops sub-composition is Ready |
| `providerConfigRef` | string | Helm provider config ref for downstream |

## Nested Sub-Compositions

| Engine | Emitted XR | Status |
|--------|-----------|--------|
| `flux` | `XFluxInit` | integrated |
| `argocd` | `XArgoInit` | planned |

## DEV

```bash
crossplane render examples/cluster-profile.yaml \
  compositions/cluster-profile.yaml \
  examples/functions.yaml \
  --include-function-results
```
