# ClusterProfile

Crossplane composition that nests CNI (Cilium), GitOps (Flux/Argo), and cert-manager sub-compositions into a single claim. Supports distribution-aware defaults via `clusterType`.

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
| `clusterType` | string | no | | Kubernetes distribution (`kind`, `k3s`, `rke2`, `k8s`). Sets Cilium defaults per distribution |
| `cilium.clusterName` | string | no | | Kind cluster name. For kind, derives `k8sServiceHost` as `{clusterName}-control-plane` |
| `gitops.engine` | string | no | `flux` | GitOps engine (`flux`, `argocd`, or `none` to skip) |
| `flux` | object | no | | Flux-specific overrides passed to XFluxInit |
| `cilium` | object | no | | Cilium CNI configuration (see below) |
| `certManager` | object | no | | cert-manager configuration passed to XCertManager |

### Status Fields

| Field | Type | Description |
|-------|------|-------------|
| `ready` | boolean | True when all sub-compositions are Ready |
| `ciliumReady` | boolean | True when Cilium sub-composition is Ready |
| `gitopsEngine` | string | Active engine (`flux` or `argocd`) |
| `gitopsReady` | boolean | True when gitops sub-composition is Ready |
| `certManagerReady` | boolean | True when cert-manager sub-composition is Ready |
| `providerConfigRef` | string | Helm provider config ref for downstream |

## Cluster Type Defaults

When `clusterType` is set, distribution-specific Cilium defaults are applied automatically. You only need to provide cluster-specific values like `k8sServiceHost`. Any field you set explicitly in the claim **always overrides** the defaults.

### Default Values per Distribution

| Field | `kind` | `k3s` | `rke2` | `k8s` |
|-------|--------|-------|--------|-------|
| `routingMode` | `native` | `native` | `native` | `tunnel` |
| `ipv4NativeRoutingCIDR` | `10.244.0.0/16` | `10.42.0.0/16` | `10.42.0.0/16` | `10.244.0.0/16` |
| `autoDirectNodeRoutes` | `true` | `true` | `true` | `false` |
| `devices` | `[eth0, net0]` | `[eth0]` | `[eth0]` | `[eth0]` |
| `kubeProxyReplacement` | `true` | `true` | `true` | `true` |
| `operator.replicas` | `1` | `1` | `2` | `2` |
| `gatewayAPI.enabled` | `false` | `true` | `true` | `true` |
| `l2Announcements.enabled` | `true` | `false` | `false` | `false` |
| `externalIPs.enabled` | `true` | `true` | `true` | `true` |

If `clusterType` is omitted, the composition falls back to hardcoded defaults (backwards compatible).

## Examples

### Minimal kind Cluster (with clusterType defaults)

```yaml
apiVersion: platform.stuttgart-things.com/v1alpha1
kind: XClusterProfile
metadata:
  name: dev-profile
  namespace: crossplane-system
spec:
  helmProviderConfigRef: dev-helm
  kubernetesProviderConfigRef: dev-kubernetes
  clusterType: kind
  cilium:
    enabled: true
    clusterName: dev
  gitops:
    engine: flux
  flux:
    instance:
      sources:
        - name: flux-infra
          kind: OCIRepository
          url: oci://ghcr.io/stuttgart-things/flux-infra
          ref: latest
```

All Cilium values (`routingMode`, `devices`, `l2Announcements`, `k8sServiceHost`, etc.) are auto-derived from `clusterType: kind`. The `clusterName` is used to derive `k8sServiceHost` as `{clusterName}-control-plane`.

### RKE2 Cluster with LoadBalancer

```yaml
apiVersion: platform.stuttgart-things.com/v1alpha1
kind: XClusterProfile
metadata:
  name: prod-profile
  namespace: crossplane-system
spec:
  helmProviderConfigRef: prod-helm
  kubernetesProviderConfigRef: prod-kubernetes
  clusterType: rke2
  cilium:
    enabled: true
    k8sServiceHost: 10.31.102.10
    k8sServicePort: 6443
    loadBalancer:
      enabled: true
      ipMode: static
      ipRange:
        start: "10.31.102.100"
        end: "10.31.102.110"
  gitops:
    engine: flux
  flux:
    instance:
      sources:
        - name: flux-infra
          kind: OCIRepository
          url: oci://ghcr.io/stuttgart-things/flux-infra
          ref: latest
  certManager:
    enabled: true
    selfSigned:
      enabled: true
      wildcard:
        domain: sthings.io
```

Defaults from `clusterType: rke2` apply (`ipv4NativeRoutingCIDR: 10.42.0.0/16`, `operator.replicas: 2`, etc.). Only cluster-specific values need to be set.

### Overriding Defaults

Any default can be overridden by setting it explicitly in the claim. For example, to use tunnel routing on a kind cluster:

```yaml
spec:
  clusterType: kind
  cilium:
    enabled: true
    clusterName: dev
    routingMode: tunnel          # overrides kind default "native"
    autoDirectNodeRoutes: false  # overrides kind default "true"
    devices:                     # overrides kind default ["eth0", "net0"]
      - eth0
```

### Without clusterType (fully explicit)

If `clusterType` is omitted, you must specify all Cilium values yourself:

```yaml
spec:
  cilium:
    enabled: true
    k8sServiceHost: my-cluster-cp
    k8sServicePort: 6443
    routingMode: native
    ipv4NativeRoutingCIDR: "10.244.0.0/16"
    autoDirectNodeRoutes: true
    devices:
      - eth0
      - net0
    operator:
      replicas: 2
    l2Announcements:
      enabled: true
```

## Nested Sub-Compositions

| Component | Emitted XR | Gated on | Status |
|-----------|-----------|----------|--------|
| Cilium | `XCilium` | — | integrated |
| Flux | `XFluxInit` | Cilium ready | integrated |
| ArgoCD | `XArgoInit` | Cilium ready | planned |
| cert-manager | `XCertManager` | Cilium ready | integrated |

## Prerequisites

- Crossplane `>=2.13.0` on the management cluster
- `XCilium` XRD and composition installed (from `configurations/infra/cilium/`)
- `XFluxInit` XRD and composition installed (from `configurations/config/flux-init/`)
- `XCertManager` XRD and composition installed (from `configurations/infra/cert-manager/`)
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

# Nested Cilium
kubectl get xciliums.platform.stuttgart-things.com -A

# Nested FluxInit
kubectl get fluxinits.platform.stuttgart-things.com -A

# Nested cert-manager
kubectl get xcertmanagers.platform.stuttgart-things.com -A

# Helm releases
kubectl get releases.helm.m.crossplane.io -A
```

Verify on the target cluster:

```bash
export KUBECONFIG=~/.kube/xplane-test

# Cilium running
kubectl get pods -n kube-system -l app.kubernetes.io/name=cilium

# Flux controllers running
kubectl get pods -n flux-system

# cert-manager running
kubectl get pods -n cert-manager
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
  "ciliumReady": true,
  "gitopsEngine": "flux",
  "gitopsReady": true,
  "certManagerReady": true,
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
