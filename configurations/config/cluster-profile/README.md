# ClusterProfile

Crossplane composition that nests GitOps (Flux/Argo), DNS, and Vault sub-compositions into a single claim. Currently integrates `XFluxInit` with conditional engine selection (`flux` or `argocd`).

## API

- **Group:** `platform.stuttgart-things.com`
- **Version:** `v1alpha1`
- **XR Kind:** `XClusterProfile`
- **Scope:** `Namespaced` (no claim — v2 XRD)

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

## Prerequisites

- Crossplane `>=2.13.0` on the management cluster
- `XFluxInit` XRD and composition installed (from `configurations/config/flux-init/`)
- `flux-defaults` EnvironmentConfig applied
- Functions: `function-kcl` (v0.10.4), `function-auto-ready` (v0.6.0)
- A `ClusterProviderConfig` for both Helm and Kubernetes pointing at the target cluster kubeconfig secret

Example provider configs (pointing at a secret `kubeconfig-xplane-test` in `crossplane-system`):

```bash
kubectl apply -f examples/provider-config.yaml
```

## Install

Apply the XRD and composition on the management cluster:

```bash
export KUBECONFIG=~/.kube/dev

kubectl apply -f apis/definition.yaml
kubectl apply -f compositions/cluster-profile.yaml
```

## Test

Create the example XR targeting the remote cluster:

```bash
kubectl apply -f examples/cluster-profile.yaml
```

Watch reconciliation:

```bash
# XClusterProfile status
kubectl get clusterprofiles.platform.stuttgart-things.com -A

# Nested FluxInit
kubectl get fluxinits.platform.stuttgart-things.com -A

# Helm releases created by FluxInit
kubectl get releases.helm.m.crossplane.io -A

# Kubernetes objects (FluxInstance, OCIRepositories)
kubectl get objects.kubernetes.m.crossplane.io -A
```

Verify on the target cluster:

```bash
export KUBECONFIG=~/.kube/xplane-test

# Flux controllers running
kubectl get pods -n flux-system

# FluxInstance reconciled
kubectl get fluxinstance -n flux-system

# OCI sources ready
kubectl get ocirepositories -A
```

Check XClusterProfile status fields:

```bash
export KUBECONFIG=~/.kube/dev
kubectl get clusterprofiles.platform.stuttgart-things.com test-cluster-profile \
  -n crossplane-system -o jsonpath='{.status}' | python3 -m json.tool
```

Expected status when fully ready:

```json
{
  "ready": true,
  "gitopsEngine": "flux",
  "gitopsReady": true,
  "providerConfigRef": "xplane-test-helm"
}
```

## Cleanup

```bash
export KUBECONFIG=~/.kube/dev
kubectl delete -f examples/cluster-profile.yaml
kubectl delete -f compositions/cluster-profile.yaml
kubectl delete -f apis/definition.yaml
```

## DEV

Local render (no cluster required):

```bash
crossplane render examples/cluster-profile.yaml \
  compositions/cluster-profile.yaml \
  examples/functions.yaml \
  --include-function-results
```
