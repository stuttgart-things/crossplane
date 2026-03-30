# ClusterProfile

Crossplane composition that orchestrates a full cluster setup: IP reservation, cert-manager, Vault PKI, Cilium CNI (with LB + Gateway), and GitOps. Supports distribution-aware defaults via `clusterType` and automatic DNS/FQDN wiring from clusterbook.

## Pipeline Ordering

The composition deploys sub-compositions in a strict order with soft gates (KCL conditionals) and hard gates (Usage resources).

### Non-kind Clusters (k3s, rke2, k8s)

| Stage | Component | XR Kind | Gate | Status Field | What it does |
|-------|-----------|---------|------|--------------|-------------|
| 0 | Observe RemoteCluster | Object (Observe) | always | — | Reads apiEndpoint, clusterType, podCIDR |
| 1 | IP Reservation + PDNS | `XIPReservation` | observeReady | `ipReservationReady` | Reserves LB IP + creates wildcard DNS via clusterbook |
| 2 | cert-manager | `XCertManager` | iprSatisfied | `certManagerReady` | Installs Helm chart (CRDs) + wildcard cert (vault-pki issuer) |
| 3 | Vault Base Setup | `VaultBaseSetup` | certManagerReady | `vaultBaseSetupReady` | Creates vault-pki ClusterIssuer via OpenTofu |
| 4 | Trust Manager | `XTrustManager` | certManagerReady | `trustManagerReady` | Deploys trust-manager + cluster trust Bundle (system CAs + vault CA) |
| 5 | Cilium | `XCilium` | iprSatisfied + vbsReady | `ciliumReady` | CNI + LoadBalancer (reserved IP) + Gateway (vault-issued cert) |
| 6 | GitOps (Flux) | `FluxInit` | ciliumReady | `gitopsReady` | Flux operator + sources |

### kind Clusters

| Stage | Component | XR Kind | Gate | Status Field | What it does |
|-------|-----------|---------|------|--------------|-------------|
| 0 | Observe RemoteCluster | Object (Observe) | always | — | Reads clusterType |
| 1 | cert-manager | `XCertManager` | observeReady | `certManagerReady` | Installs Helm + self-signed CA chain + wildcard cert |
| 2 | Cilium | `XCilium` | observeReady | `ciliumReady` | CNI only (no LB, no Gateway) |
| 3 | GitOps (Flux) | `FluxInit` | ciliumReady | `gitopsReady` | Flux operator + sources |

### What gets skipped per distribution

| Feature | kind | k3s | rke2 | k8s |
|---------|------|-----|------|-----|
| IP Reservation (clusterbook) | skipped | auto | auto | auto |
| PDNS wildcard DNS | skipped | auto | auto | auto |
| VaultBaseSetup | skipped | auto (when vaultCaBundle set) | auto | auto |
| TrustManager | skipped | auto (when vaultCaBundle set) | auto | auto |
| Cilium LoadBalancer | skipped | auto (reserved IP) | auto | auto |
| Cilium Gateway | skipped | auto (FQDN domain) | auto | auto |
| Wildcard cert issuer | self-signed (cluster-ca) | vault-pki | vault-pki | vault-pki |
| Wildcard cert secret | `wildcard-tls` | `wildcard-{clusterName}-tls` | `wildcard-{clusterName}-tls` | `wildcard-{clusterName}-tls` |

### Usage (hard ordering) Resources

| Usage | Ensures |
|-------|---------|
| VaultBaseSetup depends on XCertManager | CRDs exist before creating ClusterIssuer |
| XTrustManager depends on XCertManager | cert-manager namespace + CRDs exist |
| XCilium depends on XIPReservation | IP reserved before LB pool created |
| XCilium depends on VaultBaseSetup | Vault ClusterIssuer exists before Gateway cert |

## API

- **Group:** `platform.stuttgart-things.com`
- **Version:** `v1alpha1`
- **XR Kind:** `XClusterProfile`
- **Scope:** `Namespaced` (no claim — v2 XRD)

### Spec Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `clusterName` | string | no | | RemoteCluster name — auto-derives provider configs, apiEndpoint, clusterType |
| `helmProviderConfigRef` | string | no | `{clusterName}-helm` | Helm ClusterProviderConfig name |
| `kubernetesProviderConfigRef` | string | no | `{clusterName}-kubernetes` | Kubernetes ClusterProviderConfig name |
| `clusterType` | string | no | observed | Kubernetes distribution (`kind`, `k3s`, `rke2`, `k8s`) |
| `cilium` | object | no | | Cilium CNI configuration (see below) |
| `certManager` | object | no | | cert-manager configuration |
| `ipReservation` | object | no | | IP reservation from clusterbook (auto-enabled for non-kind) |
| `vaultBaseSetup` | object | no | | Vault PKI integration (auto-enabled when `vaultCaBundle` is set + non-kind) |
| `gitops.engine` | string | no | `flux` | GitOps engine (`flux`, `argocd`, or `none`) |
| `flux` | object | no | | Flux-specific overrides passed to XFluxInit |

### Status Fields

| Field | Type | Description |
|-------|------|-------------|
| `ready` | boolean | True when **all** sub-compositions are Ready |
| `ipReservationReady` | boolean | IP reservation from clusterbook |
| `certManagerReady` | boolean | cert-manager Helm + wildcard cert |
| `vaultBaseSetupReady` | boolean | Vault PKI ClusterIssuer |
| `trustManagerReady` | boolean | trust-manager + cluster trust Bundle |
| `ciliumReady` | boolean | Cilium CNI + LB + Gateway |
| `gitopsReady` | boolean | Flux/ArgoCD |
| `gitopsEngine` | string | Active engine (`flux` or `argocd`) |
| `ipAddresses` | []string | Reserved IPs from clusterbook |
| `fqdn` | string | Wildcard DNS name (e.g. `*.mycluster.example.com`) |
| `zone` | string | DNS zone (e.g. `example.com`) |
| `providerConfigRef` | string | Helm provider config ref for downstream |

## Cluster Type Defaults

When `clusterType` is set (or auto-detected via RemoteCluster), distribution-specific Cilium defaults are applied. Any field you set explicitly **always overrides** the defaults.

| Field | `kind` | `k3s` | `rke2` | `k8s` |
|-------|--------|-------|--------|-------|
| `routingMode` | `native` | `tunnel` | `native` | `tunnel` |
| `ipv4NativeRoutingCIDR` | `10.244.0.0/16` | `10.42.0.0/16` | `10.42.0.0/16` | `10.244.0.0/16` |
| `autoDirectNodeRoutes` | `true` | `false` | `true` | `false` |
| `devices` | `[eth0, net0]` | — | `[eth0]` | `[eth0]` |
| `kubeProxyReplacement` | `true` | `true` | `true` | `true` |
| `operator.replicas` | `1` | `1` | `2` | `2` |
| `gatewayAPI.enabled` | `false` | `true` | `true` | `true` |
| `l2Announcements.enabled` | `true` | `true` | `false` | `false` |
| `externalIPs.enabled` | `true` | `true` | `true` | `true` |

## Examples

### k3s Cluster (full pipeline)

```yaml
apiVersion: platform.stuttgart-things.com/v1alpha1
kind: XClusterProfile
metadata:
  name: k3s-target-labul
  namespace: crossplane-system
spec:
  clusterName: k3s-target-labul
  cilium:
    enabled: true
  certManager:
    enabled: true
  vaultBaseSetup:
    vaultCaBundle: "LS0tLS1CRUdJTi..."   # base64-encoded Vault CA
  gitops:
    engine: flux
```

This auto-configures the full pipeline:
- Observes RemoteCluster for apiEndpoint, clusterType, podCIDR
- Reserves an IP from clusterbook + creates PDNS wildcard DNS
- Installs cert-manager + wildcard cert using `vault-pki` issuer
- Runs vault-base-setup to create the `vault-pki` ClusterIssuer
- Deploys Cilium with LB (reserved IP) + Gateway (auto-derived FQDN, vault cert)
- Deploys Flux with default sources

### kind Cluster (minimal)

```yaml
apiVersion: platform.stuttgart-things.com/v1alpha1
kind: XClusterProfile
metadata:
  name: dev-profile
  namespace: crossplane-system
spec:
  clusterName: xplane-test
  cilium:
    enabled: true
    clusterName: crossplane-test
  certManager:
    enabled: true
  gitops:
    engine: flux
```

Kind clusters skip IP reservation, VaultBaseSetup, LB, and Gateway automatically.

## Nested Sub-Compositions

| Component | XR Kind | API Group | Gated on | Status |
|-----------|---------|-----------|----------|--------|
| IP Reservation | `XIPReservation` | `platform.stuttgart-things.com` | observe ready | integrated |
| cert-manager | `XCertManager` | `platform.stuttgart-things.com` | IP reservation | integrated |
| Vault Base Setup | `VaultBaseSetup` | `resources.stuttgart-things.com` | cert-manager ready | integrated |
| Trust Manager | `XTrustManager` | `platform.stuttgart-things.com` | cert-manager ready | integrated |
| Cilium | `XCilium` | `platform.stuttgart-things.com` | IPR + VBS ready | integrated |
| Flux | `FluxInit` | `platform.stuttgart-things.com` | Cilium ready | integrated |
| ArgoCD | `XArgoInit` | `platform.stuttgart-things.com` | Cilium ready | planned |

## Prerequisites

- Crossplane `>=2.13.0` on the management cluster
- `XIPReservation` XRD + composition (`configurations/config/ip-reservation/`)
- `XCertManager` XRD + composition (`configurations/infra/cert-manager/`)
- `VaultBaseSetup` XRD + composition (`configurations/terraform/vault-base-setup/`)
- `XTrustManager` XRD + composition (`configurations/infra/trust-manager/`)
- `XCilium` XRD + composition (`configurations/infra/cilium/`)
- `XFluxInit` XRD + composition (`configurations/config/flux-init/`)
- Providers: `provider-clusterbook`, `provider-kubeconfig`, `provider-helm`, `provider-kubernetes`, `provider-opentofu`
- Functions: `function-kcl` (v0.10.4), `function-auto-ready` (v0.6.0), `function-go-templating` (v0.11.3)
- Vault token secret (`vault-token`) in `crossplane-system` namespace

## Install

```bash
export KUBECONFIG=~/.kube/dev

kubectl apply -f apis/definition.yaml
kubectl apply -f compositions/cluster-profile.yaml
```

## Test

```bash
kubectl apply -f examples/cluster-profile-k3s.yaml

# Watch status
kubectl get clusterprofiles.platform.stuttgart-things.com -A -o wide

# Full status
kubectl get clusterprofile k3s-target-labul -n crossplane-system \
  -o jsonpath='{.status}' | python3 -m json.tool
```

Expected status when fully ready (non-kind):

```json
{
  "ready": true,
  "ipReservationReady": true,
  "certManagerReady": true,
  "vaultBaseSetupReady": true,
  "trustManagerReady": true,
  "ciliumReady": true,
  "gitopsReady": true,
  "gitopsEngine": "flux",
  "ipAddresses": ["10.31.104.5"],
  "fqdn": "*.k3s-target-labul.sthings-vsphere.labul.sva.de",
  "zone": "sthings-vsphere.labul.sva.de",
  "providerConfigRef": "k3s-target-labul-helm"
}
```

## Cleanup

```bash
kubectl delete -f examples/cluster-profile-k3s.yaml
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
