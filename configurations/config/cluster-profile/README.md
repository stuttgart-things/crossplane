# ClusterProfile

Crossplane composition that orchestrates a full cluster setup: IP reservation, cert-manager, Vault PKI, Cilium CNI (with LB + Gateway), and GitOps. Supports distribution-aware defaults via `clusterType` and automatic DNS/FQDN wiring from clusterbook.

## Pipeline Ordering

The composition deploys sub-compositions in a strict order with soft gates (KCL conditionals) and hard gates (Usage resources).

### Non-kind Clusters (k3s, rke2, k8s)

| Stage | Component | XR Kind | Gate | Status Field | What it does |
|-------|-----------|---------|------|--------------|-------------|
| 0 | Observe RemoteCluster | Object (Observe) | always | — | Reads apiEndpoint, clusterType, podCIDR |
| 1 | Cilium CNI install | `XCilium` (install only) | observeReady + deployCilium | `ciliumReady` | Helm install Cilium — **CNI must be first** so pods can start |
| 1 | IP Reservation + PDNS | `XIPReservation` | observeReady | `ipReservationReady` | Reserves LB IP + creates wildcard DNS via clusterbook |
| 2 | cert-manager | `XCertManager` | iprSatisfied | `certManagerReady` | Installs Helm chart (CRDs) + wildcard cert |
| 3 | Vault Base Setup | `VaultBaseSetup` | certManagerReady | `vaultBaseSetupReady` | Creates vault-pki ClusterIssuer via OpenTofu |
| 4 | Trust Manager | `XTrustManager` | certManagerReady | `trustManagerReady` | Deploys trust-manager + cluster trust Bundle (system CAs + vault CA) |
| 5 | Cilium LB | `XCilium` (updated) | iprSatisfied | `ciliumReady` | LoadBalancer pool + L2 announcement policy (reserved IP) |
| 5 | Cilium Gateway | `XCilium` (updated) | vbsReady + tmReady | `ciliumReady` | Gateway resource (vault-issued TLS cert + CA bundle) |
| 6 | GitOps (Flux) | `FluxInit` | ciliumInstallReady | `gitopsReady` | Flux operator + sources |

Cilium is deployed in **three phases**: the Helm install happens at stage 1 (CNI must be available before any other pods can start), LoadBalancer is enabled once an IP is reserved, and Gateway is enabled once VaultBaseSetup provides the TLS issuer. Each phase is independent. Flux only needs a working CNI, not the full Cilium feature set.

Set `deployCilium: false` in the EnvironmentConfig or `cilium.enabled: false` in the claim for clusters that already have a CNI.

<details>
<summary>kind Clusters (simplified pipeline)</summary>

| Stage | Component | XR Kind | Gate | Status Field | What it does |
|-------|-----------|---------|------|--------------|-------------|
| 0 | Observe RemoteCluster | Object (Observe) | always | — | Reads clusterType |
| 1 | cert-manager | `XCertManager` | observeReady | `certManagerReady` | Installs Helm + self-signed CA chain + wildcard cert |
| 2 | Cilium | `XCilium` | observeReady | `ciliumReady` | CNI only (no LB, no Gateway) |
| 3 | GitOps (Flux) | `FluxInit` | ciliumReady | `gitopsReady` | Flux operator + sources |

</details>

<details>
<summary>What gets skipped per distribution</summary>

| Feature | kind | k3s | rke2 | k8s |
|---------|------|-----|------|-----|
| IP Reservation (clusterbook) | skipped | auto | auto | auto |
| PDNS wildcard DNS | skipped | auto | auto | auto |
| VaultBaseSetup | skipped | auto (default CA) | auto (default CA) | auto (default CA) |
| TrustManager | skipped | auto (default CA) | auto (default CA) | auto (default CA) |
| Cilium LoadBalancer | skipped | auto (reserved IP) | auto | auto |
| Cilium Gateway | skipped | auto (FQDN domain) | auto | auto |
| Wildcard cert issuer | self-signed (cluster-ca) | vault-pki (default) | vault-pki (default) | vault-pki (default) |
| Wildcard cert secret | `wildcard-tls` | `wildcard-{clusterName}-tls` | `wildcard-{clusterName}-tls` | `wildcard-{clusterName}-tls` |

</details>

<details>
<summary>Usage (hard ordering) Resources</summary>

| Usage | Ensures |
|-------|---------|
| VaultBaseSetup depends on XCertManager | CRDs exist before creating ClusterIssuer |
| XTrustManager depends on XCertManager | cert-manager namespace + CRDs exist |
| XCilium depends on XIPReservation | IP reserved before LB pool created |
| XCilium depends on VaultBaseSetup | Vault ClusterIssuer exists before Gateway cert |
| FluxInit depends on XCilium | Flux kustomizations may reference Cilium CRDs (e.g. Gateway routes) — prevents stuck finalizers on teardown |

</details>

## API

- **Group:** `platform.stuttgart-things.com`
- **Version:** `v1alpha1`
- **XR Kind:** `XClusterProfile`
- **Scope:** `Namespaced` (no claim — v2 XRD)

<details>
<summary>Spec Fields</summary>

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `clusterName` | string | no | | RemoteCluster name — auto-derives provider configs, apiEndpoint, clusterType |
| `helmProviderConfigRef` | string | no | `{clusterName}-helm` | Helm ClusterProviderConfig name |
| `kubernetesProviderConfigRef` | string | no | `{clusterName}-kubernetes` | Kubernetes ClusterProviderConfig name |
| `clusterType` | string | no | observed | Kubernetes distribution (`kind`, `k3s`, `rke2`, `k8s`) |
| `cilium` | object | no | | Cilium CNI configuration (see below) |
| `certManager` | object | no | | cert-manager configuration |
| `ipReservation` | object | no | | IP reservation from clusterbook (auto-enabled for non-kind) |
| `vaultBaseSetup` | object | no | | Vault PKI integration (auto-enabled for non-kind clusters with built-in CA) |
| `gitops.engine` | string | no | `flux` | GitOps engine (`flux`, `argocd`, or `none`) |
| `flux` | object | no | | Flux-specific overrides passed to XFluxInit |

</details>

<details>
<summary>Status Fields</summary>

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

</details>

## Cluster Type Defaults

When `clusterType` is set (or auto-detected via RemoteCluster), distribution-specific defaults are applied. Any field you set explicitly **always overrides** the defaults.

<details>
<summary>Cilium Helm values per distribution</summary>

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

</details>

<details>
<summary>Feature auto-enablement per distribution</summary>

| Feature | kind | k3s | rke2 | k8s |
|---------|------|-----|------|-----|
| Cilium CNI | deployed | deployed | deployed | deployed |
| IP Reservation | skipped | auto | auto | auto |
| VaultBaseSetup | skipped | auto | auto | auto |
| TrustManager | skipped | auto | auto | auto |
| Cilium LB | skipped | auto | auto | auto |
| Cilium Gateway | skipped | auto | auto | auto |
| Wildcard cert issuer | cluster-ca | vault-pki | vault-pki | vault-pki |

</details>

## Examples

### Step 1: Create a RemoteCluster (provider-kubeconfig)

Before creating a ClusterProfile, the target cluster must be registered as a `RemoteCluster`. This decrypts a SOPS-encrypted kubeconfig from Git and creates downstream `ClusterProviderConfigs` for Helm and Kubernetes providers.

```yaml
apiVersion: kubeconfig.stuttgart-things.com/v1alpha1
kind: RemoteCluster
metadata:
  name: k3s-2
spec:
  forProvider:
    secretNamespace: crossplane-system
    source:
      path: secrets/kubeconfigs/k3s-2.yaml
      key: kubeconfig
      type: git
    providerConfigs:
      - name: k3s-2-kubernetes
        type: provider-kubernetes
        apiVersions:
          - v2-cluster
      - name: k3s-2-helm
        type: provider-helm
        apiVersions:
          - v2-cluster
  providerConfigRef:
    kind: ClusterProviderConfig
    name: stuttgart-things   # Git repo + SOPS age key
```

Once ready, this creates `k3s-2-helm` and `k3s-2-kubernetes` ClusterProviderConfigs automatically.

### Step 2: Create a ClusterProfile

<details>
<summary>k3s Cluster (minimal — full pipeline)</summary>

Only `clusterName` and feature toggles are needed. Everything else is auto-derived from the RemoteCluster observation (clusterType, podCIDR, apiEndpoint) and distribution defaults.

```yaml
apiVersion: platform.stuttgart-things.com/v1alpha1
kind: XClusterProfile
metadata:
  name: k3s-2
  namespace: crossplane-system
spec:
  clusterName: k3s-2
  cilium:
    enabled: true
  certManager:
    enabled: true
  gitops:
    engine: flux
```

This auto-configures the full k3s pipeline:
- Installs Cilium CNI (tunnel routing, kube-proxy replacement)
- Observes RemoteCluster for apiEndpoint, clusterType=k3s, podCIDR
- Reserves an IP from clusterbook (e.g. `10.31.102.14`)
- Creates Vault PKI ClusterIssuer (`vault-pki`) via OpenTofu (default CA bundle)
- Installs cert-manager + wildcard cert (initially cluster-ca, then vault-pki)
- Deploys trust-manager with system CAs + Vault CA bundle
- Enables Cilium LB (reserved IP) + Gateway (vault-issued cert)
- Deploys Flux with default OCI sources

VaultBaseSetup and TrustManager are **enabled by default** for non-kind clusters — the Vault CA bundle, address, and PKI role are loaded from the `cluster-profile-defaults` EnvironmentConfig. Override per-claim via `spec.vaultBaseSetup.*` if needed.

</details>

<details>
<summary>kind Cluster (minimal)</summary>

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

Kind clusters automatically apply different Cilium Helm values (native routing, `10.244.0.0/16` pod CIDR, `[eth0, net0]` devices) and skip IP reservation, VaultBaseSetup, TrustManager, LB, and Gateway.

</details>

<details>
<summary>Cluster with existing CNI (skip Cilium)</summary>

```yaml
apiVersion: platform.stuttgart-things.com/v1alpha1
kind: XClusterProfile
metadata:
  name: managed-cluster
  namespace: crossplane-system
spec:
  clusterName: my-cluster
  cilium:
    enabled: false          # skip Cilium — cluster already has a CNI
  certManager:
    enabled: true
  gitops:
    engine: flux
```

Or disable globally via EnvironmentConfig:

```yaml
apiVersion: apiextensions.crossplane.io/v1beta1
kind: EnvironmentConfig
metadata:
  name: cluster-profile-defaults
data:
  deployCilium: false       # all clusters skip Cilium by default
  vault:
    # ...
```

</details>

<details>
<summary>Nested Sub-Compositions</summary>

| Component | XR Kind | API Group | Gated on | Status |
|-----------|---------|-----------|----------|--------|
| IP Reservation | `XIPReservation` | `platform.stuttgart-things.com` | observe ready | integrated |
| cert-manager | `XCertManager` | `platform.stuttgart-things.com` | IP reservation | integrated |
| Vault Base Setup | `VaultBaseSetup` | `resources.stuttgart-things.com` | cert-manager ready | integrated |
| Trust Manager | `XTrustManager` | `platform.stuttgart-things.com` | cert-manager ready | integrated |
| Cilium | `XCilium` | `platform.stuttgart-things.com` | observe ready (install) / IPR + VBS (LB + GW) | integrated |
| Flux | `FluxInit` | `platform.stuttgart-things.com` | Cilium install ready | integrated |
| ArgoCD | `XArgoInit` | `platform.stuttgart-things.com` | Cilium install ready | planned |

</details>

## EnvironmentConfig

The composition loads defaults from a `cluster-profile-defaults` EnvironmentConfig. This externalizes environment-specific values so the composition stays generic.

```yaml
apiVersion: apiextensions.crossplane.io/v1beta1
kind: EnvironmentConfig
metadata:
  name: cluster-profile-defaults
data:
  deployCilium: true
  vault:
    addr: "https://vault.example.com"
    caBundle: "<base64-encoded Vault PKI root CA>"
    pkiRole: "my-pki-role"
    policyName: "pki-issue"
```

**Precedence:** `spec.*` (per-claim) > `EnvironmentConfig` > hardcoded fallback

<details>
<summary>EnvironmentConfig fields reference</summary>

| Field | Composition variable | Fallback | Description |
|-------|---------------------|----------|-------------|
| `deployCilium` | `_deployCilium` | `true` | Set to `false` for clusters with an existing CNI |
| `vault.caBundle` | `_vaultCaBundle` | `""` (disables VaultBaseSetup) | Base64-encoded Vault PKI root CA |
| `vault.addr` | vault address | `https://vault.sthings-infra.sthings-vsphere.labul.sva.de` | Vault server URL |
| `vault.pkiRole` | PKI role name | `sthings-vsphere` | Vault PKI role |
| `vault.policyName` | Vault policy | `pki-issue` | Vault policy name |

</details>

Apply the EnvironmentConfig before creating any ClusterProfile:

```bash
kubectl apply -f examples/environment-config.yaml
```

<details>
<summary>Prerequisites</summary>

- Crossplane `>=2.13.0` on the management cluster
- `XIPReservation` XRD + composition (`configurations/config/ip-reservation/`)
- `XCertManager` XRD + composition (`configurations/infra/cert-manager/`)
- `VaultBaseSetup` XRD + composition (`configurations/terraform/vault-base-setup/`)
- `XTrustManager` XRD + composition (`configurations/infra/trust-manager/`)
- `XCilium` XRD + composition (`configurations/infra/cilium/`)
- `XFluxInit` XRD + composition (`configurations/config/flux-init/`)
- Providers: `provider-clusterbook`, `provider-kubeconfig`, `provider-helm`, `provider-kubernetes`, `provider-opentofu`
- Functions: `function-kcl` (v0.10.4), `function-auto-ready` (v0.6.0), `function-environment-configs` (v0.3.0), `function-go-templating` (v0.11.3)
- Vault token secret (`vault-token`) in `crossplane-system` namespace

</details>

## Install

```bash
export KUBECONFIG=~/.kube/dev

kubectl apply -f examples/environment-config.yaml
kubectl apply -f apis/definition.yaml
kubectl apply -f compositions/cluster-profile.yaml
```

## Test

```bash
kubectl apply -f examples/cluster-profile-k3s.yaml

# Watch status
kubectl get clusterprofiles.platform.stuttgart-things.com -A -o wide

# Full status
kubectl get clusterprofile k3s-2 -n crossplane-system \
  -o jsonpath='{.status}' | python3 -m json.tool
```

<details>
<summary>Expected status when fully ready (non-kind)</summary>

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
  "ipAddresses": ["10.31.102.14"],
  "fqdn": "*.k3s-2.sthings-vsphere.labul.sva.de",
  "zone": "sthings-vsphere.labul.sva.de",
  "providerConfigRef": "k3s-2-helm"
}
```

</details>

## Cleanup

```bash
kubectl delete -f examples/cluster-profile-k3s.yaml
kubectl delete -f compositions/cluster-profile.yaml
kubectl delete -f apis/definition.yaml
```

## DEV

Local render (no cluster required). The `--extra-resources` flag supplies the EnvironmentConfig that the `load-defaults` pipeline step expects.

### Render kind cluster example

```bash
crossplane render examples/cluster-profile.yaml \
  compositions/cluster-profile.yaml \
  examples/functions.yaml \
  --extra-resources=examples/environment-config.yaml \
  --include-function-results
```

### Render k3s cluster example

```bash
crossplane render examples/cluster-profile-k3s.yaml \
  compositions/cluster-profile.yaml \
  examples/functions.yaml \
  --extra-resources=examples/environment-config.yaml \
  --include-function-results
```

### Render and filter specific resources

```bash
# Show only XCilium spec
crossplane render examples/cluster-profile-k3s.yaml \
  compositions/cluster-profile.yaml \
  examples/functions.yaml \
  --extra-resources=examples/environment-config.yaml \
  --include-function-results | yq 'select(.kind == "XCilium")'

# Show only Usage resources (dependency chain)
crossplane render examples/cluster-profile-k3s.yaml \
  compositions/cluster-profile.yaml \
  examples/functions.yaml \
  --extra-resources=examples/environment-config.yaml \
  --include-function-results | yq 'select(.kind == "Usage")'

# Show composed XR status
crossplane render examples/cluster-profile-k3s.yaml \
  compositions/cluster-profile.yaml \
  examples/functions.yaml \
  --extra-resources=examples/environment-config.yaml \
  --include-function-results | yq 'select(.kind == "XClusterProfile") | .status'
```
