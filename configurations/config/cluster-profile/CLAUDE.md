# CLAUDE.md — Crossplane Compositions (stuttgart-things)

## Project Context

Platform engineering compositions for the `sthings.lab` homelab and SVA customer environments.
Goal: atomic, testable XRDs that nest into a larger `ClusterProfile` claim covering GitOps, DNS, Auth, and Infra software deployment.

---

## Conventions

### API Group & Versioning
- Group: `platform.sthings.de`
- Version: `v1alpha1` (all compositions currently)
- XRD kind prefix: `X` (e.g. `XFluxInit`, `XClusterProfile`, `XInfraStack`)
- Claim kind: no prefix (e.g. `FluxInitClaim`, `ClusterProfileClaim`)

### Naming Patterns
- Composed resource names: `{xr.metadata.name}-{component}` (e.g. `dev-cluster-flux-operator`)
- EnvironmentConfig names: `{feature}-defaults` (e.g. `flux-defaults`, `cilium-defaults`)
- Composition names: `{feature}-kcl` (e.g. `fluxinit-kcl`)
- File layout per feature:
  ```
  compositions/
    flux-init/
      xrd.yaml
      environmentconfig.yaml
      composition.yaml
      claim-example.yaml
  ```

### Provider Versions
```yaml
# Helm provider
helm.crossplane.io/v1beta1 - Release

# Kubernetes provider
kubernetes.crossplane.io/v1alpha2 - Object

# KCL function
functionRef:
  name: function-kcl   # krm.kcl.dev/v1alpha1 KCLInput

# Patch and transform (only if KCL not sufficient)
functionRef:
  name: function-patch-and-transform
```

---

## Composition Pipeline Pattern

Every composition uses a **2-step KCL pipeline** — never mix KCL with patch-and-transform unless unavoidable.

```yaml
spec:
  environment:
    environmentConfigs:
      - type: Reference
        ref:
          name: <feature>-defaults
  mode: Pipeline
  pipeline:
    - step: render
      functionRef:
        name: function-kcl
      input:
        apiVersion: krm.kcl.dev/v1alpha1
        kind: KCLInput
        spec:
          source: |
            # Step 1: generate managed resources

    - step: patch-status
      functionRef:
        name: function-kcl
      input:
        apiVersion: krm.kcl.dev/v1alpha1
        kind: KCLInput
        spec:
          source: |
            # Step 2: read ocds back, patch XR status
```

---

## KCL Patterns

### Standard imports / params
```python
oxr  = option("params").oxr          # composite resource (spec + metadata)
ocds = option("params").ocds         # observed composed resource states (live MR status)
env  = option("params").environment  # EnvironmentConfig data (merged defaults)
```

### Defaults fallback pattern
Always prefer spec value, fall back to EnvironmentConfig:
```python
_version   = oxr.spec.operatorChart?.version or env.operatorChart.version
_namespace = oxr.spec?.namespace or env.namespace
_components = oxr.spec.instance?.components or env.instance.components
```

### Nested Composition via KCL (Decision: use KCL, not patch-and-transform)

For nesting sub-compositions (e.g. FluxInit, ArgoInit inside ClusterProfile), always use KCL.
Patch-and-transform nesting (as in harvester-vm) requires 20+ explicit field patches per XR
and cannot do conditional branching. KCL spreads the spec in a few lines and supports `if` guards.

#### Emitting a nested XR
```python
_name = oxr.metadata.name

_fluxInit = {
    apiVersion = "resources.stuttgart-things.com/v1alpha1"
    kind = "FluxInit"
    metadata.name = "{}-flux-init".format(_name)
    metadata.namespace = oxr.metadata.namespace
    metadata.annotations = {
        "crossplane.io/composition-resource-name" = "{}-flux-init".format(_name)
    }
    spec = {
        helmProviderConfigRef = oxr.spec.helmProviderConfigRef
        kubernetesProviderConfigRef = oxr.spec.kubernetesProviderConfigRef
        **(oxr.spec.flux or {})  # pass through any feature-specific overrides
    }
}
```

#### Conditional nesting (flux OR argocd)
Suppress unchosen path entirely — never emit partial resources:
```python
_engine = oxr.spec.gitops?.engine or "flux"

_resources = []

if _engine == "flux":
    _resources += [_fluxInit]

if _engine == "argocd":
    _resources += [_argoInit]

items = _resources
```

#### Reading nested XR status back via ocds
```python
_engine = oxr.spec.gitops?.engine or "flux"

_gitopsReady = False
if _engine == "flux":
    _gitopsReady = _isReady("{}-flux-init".format(_name))
if _engine == "argocd":
    _gitopsReady = _isReady("{}-argo-init".format(_name))

_oxr = oxr | {
    status: {
        gitopsEngine: _engine
        gitopsReady: _gitopsReady
        ready: _gitopsReady  # AND other sub-composition gates
    }
}
items = [_oxr]
```

### Status patching via ocds
```python
oxr  = option("params").oxr
ocds = option("params").ocds

_name = oxr.metadata.name

# Check Ready condition on a composed MR
def _isReady(resourceName):
    if resourceName not in ocds:
        return False
    _conds = ocds[resourceName].Resource?.status?.conditions or []
    return any(c for c in _conds if c.type == "Ready" and c.status == "True")

_operatorReady = _isReady("{}-flux-operator".format(_name))
_instanceReady = _isReady("{}-flux-instance".format(_name))

# Patch XR — always spread existing oxr, only overwrite status
_oxr = {
    **oxr
    status: {
        operatorReady: _operatorReady
        instanceReady: _instanceReady
        ready: _operatorReady and _instanceReady
        providerConfigRef: oxr.spec.providerConfigRef
    }
}

items = [_oxr]
```

### status.ready is the inter-stage gate
```python
# In a consuming composition (e.g. XInfraStack), check XClusterProfile before emitting MRs
_profile = oxr.spec.clusterProfileRef.status
_upstreamReady = _profile?.ready or False
_gitopsEngine  = _profile?.gitopsEngine or "flux"   # carried through from XClusterProfile

_resources = []
if _upstreamReady:
    _resources += [_ciliumHelmRelease, _certManagerRelease]

items = _resources
```

---

## EnvironmentConfig Structure

```yaml
apiVersion: apiextensions.crossplane.io/v1alpha1
kind: EnvironmentConfig
metadata:
  name: flux-defaults
data:
  operatorChart:
    version: "0.14.0"
    repoURL: "oci://ghcr.io/controlplaneio-fluxcd/charts"
  instance:
    distribution: "2.x"
    components:
      - source-controller
      - kustomize-controller
      - helm-controller
      - notification-controller
    storage:
      class: "longhorn"
      size: "10Gi"
  namespace: "flux-system"
  reconcileEvery: "1h"
  reconcileTimeout: "5m"
```

---

## Status Schema Convention

Every XRD exposes a `status` block with at minimum:

```yaml
status:
  type: object
  properties:
    ready:
      type: boolean           # true only when ALL sub-resources are Ready
    providerConfigRef:
      type: string            # carried through for downstream consumption
    # feature-specific booleans e.g.:
    operatorReady:
      type: boolean
    instanceReady:
      type: boolean
```

`status.ready` is the **only field** other compositions depend on for gating.
Never gate on individual sub-resource fields from outside a composition.

---

## Dependency / Sequencing

- Use Crossplane `Usage` resources for hard ordering between XRs
- KCL `if _upstreamReady` guards for soft gating within a composition
- Never rely on implicit reconciliation convergence — always explicit gates

### Nesting diagram
```
Stage 1: ProviderConfig/Kubeconfig (xplane-kubeconfig-provider)
              │
              ▼
Stage 2: XClusterProfile / ClusterProfileClaim
              ├── XFluxInit  or  XArgoInit   → status.gitopsEngine, status.gitopsReady
              ├── XDnsRecord                  → status.dnsRecord,    status.dnsReady
              └── XVaultAuth                  → status.vaultBackend, status.vaultReady
              │
              ▼  (gated on XClusterProfile.status.ready)
Stage 3: XInfraStack / InfraStackClaim
              ├── Cilium      (via Flux HelmRelease or Argo Application)
              ├── cert-manager
              └── OpenEBS
              │
              ▼  (gated on XInfraStack.status.ready)
Stage 4: Applications
```

---

## Registry / Chart URLs

| Component | Chart / Image Registry |
|-----------|----------------------|
| flux-operator | `oci://ghcr.io/controlplaneio-fluxcd/charts` |
| FluxInstance CRs | `ghcr.io/fluxcd` |
| KCL modules | `ghcr.io/stuttgart-things` (OCI) |
| Cilium | `https://helm.cilium.io` |
| cert-manager | `https://charts.jetstack.io` |
| OpenEBS | `https://openebs.github.io/charts` |

---

## Current Build Order

1. `flux-init` — `XFluxInit` / `FluxInitClaim` ← **start here**
2. `dns-record` — `XDnsRecord` / `DnsRecordClaim`
3. `vault-auth` — `XVaultAuth` / `VaultAuthClaim` (kubernetes auth method, not AppRole)
4. `argo-init` — `XArgoInit` / `ArgoInitClaim`
5. `cluster-profile` — `XClusterProfile` / `ClusterProfileClaim` nesting 1–4
6. `infra-stack` — `XInfraStack` / `InfraStackClaim` gated on `XClusterProfile.status.ready`

### XClusterProfile status contract (consumed by XInfraStack)
```yaml
status:
  ready:          bool    # all sub-compositions ready
  gitopsEngine:   string  # "flux" or "argocd" — used by XInfraStack to pick delivery method
  gitopsReady:    bool
  dnsRecord:      string  # FQDN created
  dnsReady:       bool
  vaultReady:     bool
  vaultBackend:   string  # vault auth backend path
  providerConfigRef: string
```

---

## Do / Don't

| Do | Don't |
|----|-------|
| Use EnvironmentConfig for all defaults | Use plain ConfigMaps for composition defaults |
| KCL for both render + status steps | Mix KCL + patch-and-transform in same pipeline |
| KCL for nested XR emission (spread spec, `if` guards) | patch-and-transform for nesting (verbose, no branching) |
| Vault Kubernetes auth method | Vault AppRole (rotation burden) |
| Deliver Cilium via Flux/Argo | Deliver Cilium via Helm provider |
| `**oxr` spread when patching status | Reconstruct full XR object manually |
| Explicit `if` guards for option branching | Emit MRs conditionally via patch transforms |
