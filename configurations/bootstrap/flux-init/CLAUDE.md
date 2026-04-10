# CLAUDE.md — flux-init composition

## Goal

Build a complete Crossplane composition that:
1. Installs **flux-operator** via HelmRelease on the target cluster
2. Applies a **FluxInstance** CR pointing to an OCI registry as sync source
3. Applies an **OCIRepository** CR as the Flux source object

All three via Crossplane providers (helm + kubernetes) against a target cluster.

---

## Current State

Scaffolded files exist — fill them in, do not recreate:

```
apis/definition.yaml   ← XRD scaffold, spec fields missing, claimNames missing
apis/composition.yaml  ← Composition scaffold, pipeline commented out (go-templating stub — replace with KCL)
examples/claim.yaml    ← exists, likely empty
examples/functions.yaml ← exists, check function refs match below
```

Missing files to create:
```
examples/environmentconfig.yaml   ← flux-defaults EnvironmentConfig
examples/claim-minimal.yaml       ← minimal claim using all defaults
```

---

## API Details

### Crossplane v2 apiVersion split — important

| Resource | apiVersion |
|----------|-----------|
| `CompositeResourceDefinition` | `apiextensions.crossplane.io/v2` |
| `Composition` | `apiextensions.crossplane.io/v1` ← stays v1, does NOT change |

```yaml
# definition.yaml
apiVersion: apiextensions.crossplane.io/v2
kind: CompositeResourceDefinition
metadata:
  name: fluxinits.platform.stuttgart-things.com
spec:
  group: platform.stuttgart-things.com
  defaultCompositeDeletePolicy: Foreground
  scope: Namespaced
  names:
    kind: FluxInit
    plural: fluxinits
    singular: fluxinit
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      ...

# composition.yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: flux-init
  labels:
    crossplane.io/xrd: fluxinits.platform.stuttgart-things.com
spec:
  compositeTypeRef:
    apiVersion: platform.stuttgart-things.com/v1alpha1
    kind: FluxInit
  mode: Pipeline
  pipeline:
    ...
```

```yaml
group: platform.stuttgart-things.com
XRD kind:    FluxInit
plural:      fluxinits
Claim kind:  FluxInitClaim
plural:      fluxinitclaims
version:     v1alpha1
scope:       Namespaced
```

---

## XRD Spec Fields to Add

Fill in the `openAPIV3Schema` in `definition.yaml`:

```yaml
spec:
  type: object
  required: [providerConfigRef]
  properties:
    providerConfigRef:
      type: string
      description: Name of the kubernetes+helm ProviderConfig for the target cluster
    namespace:
      type: string
      default: flux-system
    operatorChart:
      type: object
      properties:
        version:
          type: string
        repoURL:
          type: string
    instance:
      type: object
      properties:
        distribution:
          type: string
        components:
          type: array
          items:
            type: string
        storage:
          type: object
          properties:
            class:
              type: string
            size:
              type: string
        sync:
          type: object
          description: Optional — if omitted, Flux controllers are installed without a source
          properties:
            kind:
              type: string
              enum: [GitRepository, OCIRepository]
              default: OCIRepository
            url:
              type: string
              description: OCI or Git URL e.g. oci://ghcr.io/stuttgart-things/fleet-infra
            ref:
              type: string
              default: latest
            path:
              type: string
              default: clusters/default
            pullSecret:
              type: string
              description: Secret name in flux-system namespace for private registries
status:
  type: object
  properties:
    operatorReady:
      type: boolean
    instanceReady:
      type: boolean
    sourceReady:
      type: boolean
    ready:
      type: boolean
    syncUrl:
      type: string
    syncRef:
      type: string
    providerConfigRef:
      type: string
```

Also add `claimNames` to the XRD:
```yaml
spec:
  claimNames:
    kind: FluxInitClaim
    plural: fluxinitclaims
```

---

## Composition Pipeline

Replace the commented-out go-templating stub in `apis/composition.yaml` with a **2-step KCL pipeline**.

Add EnvironmentConfig reference:
```yaml
spec:
  environment:
    environmentConfigs:
      - type: Reference
        ref:
          name: flux-defaults
  mode: Pipeline
  pipeline:
    - step: render
      functionRef:
        name: function-kcl
      ...
    - step: patch-status
      functionRef:
        name: function-kcl
      ...
```

---

## Step 1 — render (KCL)

Generates **2 or 3 managed resources**. The OCIRepository Object is only emitted when `sync.url` is provided.

### Params + defaults fallback

```python
oxr = option("params").oxr
env = option("params").environment

_name         = oxr.metadata.name
_pcr          = oxr.spec.providerConfigRef
_ns           = oxr.spec?.namespace or env.namespace
_version      = oxr.spec.operatorChart?.version or env.operatorChart.version
_repoURL      = oxr.spec.operatorChart?.repoURL or env.operatorChart.repoURL
_distribution = oxr.spec.instance?.distribution or env.instance.distribution
_components   = oxr.spec.instance?.components or env.instance.components
_storageClass = oxr.spec.instance?.storage?.class or env.instance.storage.class
_storageSize  = oxr.spec.instance?.storage?.size or env.instance.storage.size
_syncKind     = oxr.spec.instance?.sync?.kind or env.instance.sync.kind
_syncUrl      = oxr.spec.instance?.sync?.url or ""
_syncRef      = oxr.spec.instance?.sync?.ref or env.instance.sync.ref
_syncPath     = oxr.spec.instance?.sync?.path or env.instance.sync.path
_syncSecret   = oxr.spec.instance?.sync?.pullSecret or ""
```

### Resource 1 — HelmRelease (flux-operator)

```python
_helmRelease = {
    apiVersion: "helm.crossplane.io/v1beta1"
    kind: "Release"
    metadata: {
        name: "{}-flux-operator".format(_name)
        annotations: {
            "crossplane.io/external-name": "flux-operator"
        }
    }
    spec: {
        providerConfigRef.name: _pcr
        forProvider: {
            chart: {
                name: "flux-operator"
                repository: _repoURL
                version: _version
            }
            namespace: _ns
            values: {
                installCRDs: True
            }
        }
        rollbackLimit: 3
    }
}
```

### Resource 2 — Object (FluxInstance CR)

```python
# Build sync block only if url provided
_syncBlock = {}
if _syncUrl:
    _syncBlock = {
        kind: _syncKind
        url: _syncUrl
        ref: _syncRef
        path: _syncPath
    }
    if _syncSecret:
        _syncBlock.pullSecret = _syncSecret

_fluxInstance = {
    apiVersion: "kubernetes.crossplane.io/v1alpha2"
    kind: "Object"
    metadata: {
        name: "{}-flux-instance".format(_name)
    }
    spec: {
        providerConfigRef.name: _pcr
        forProvider: {
            manifest: {
                apiVersion: "fluxcd.controlplane.io/v1"
                kind: "FluxInstance"
                metadata: {
                    name: "flux"
                    namespace: _ns
                    annotations: {
                        "fluxcd.controlplane.io/reconcileEvery": env.reconcileEvery
                        "fluxcd.controlplane.io/reconcileTimeout": env.reconcileTimeout
                    }
                }
                spec: {
                    distribution: {
                        version: _distribution
                        registry: "ghcr.io/fluxcd"
                    }
                    components: _components
                    storage: {
                        class: _storageClass
                        size: _storageSize
                    }
                    **({ sync: _syncBlock } if _syncBlock else {})
                }
            }
        }
        readiness: {
            policy: "DeriveFromObject"
        }
    }
}
```

### Resource 3 — Object (OCIRepository CR) — only when sync.url provided

```python
_resources = [_helmRelease, _fluxInstance]

if _syncUrl and _syncKind == "OCIRepository":
    _ociRepo = {
        apiVersion: "kubernetes.crossplane.io/v1alpha2"
        kind: "Object"
        metadata: {
            name: "{}-oci-source".format(_name)
        }
        spec: {
            providerConfigRef.name: _pcr
            forProvider: {
                manifest: {
                    apiVersion: "source.toolkit.fluxcd.io/v1beta2"
                    kind: "OCIRepository"
                    metadata: {
                        name: "flux-system"
                        namespace: _ns
                    }
                    spec: {
                        interval: env.reconcileEvery
                        url: _syncUrl
                        ref: {
                            tag: _syncRef
                        }
                        **({ secretRef: { name: _syncSecret } } if _syncSecret else {})
                    }
                }
            }
            readiness: {
                policy: "DeriveFromObject"
            }
        }
    }
    _resources += [_ociRepo]

items = _resources
```

---

## Step 2 — patch-status (KCL)

```python
oxr  = option("params").oxr
ocds = option("params").ocds

_name    = oxr.metadata.name
_syncUrl = oxr.spec.instance?.sync?.url or ""

def _isReady(resourceName):
    if resourceName not in ocds:
        return False
    _conds = ocds[resourceName].Resource?.status?.conditions or []
    return any(c for c in _conds if c.type == "Ready" and c.status == "True")

_operatorReady = _isReady("{}-flux-operator".format(_name))
_instanceReady = _isReady("{}-flux-instance".format(_name))
# sourceReady is True by default when no sync URL — operator+instance alone are sufficient
_sourceReady   = _isReady("{}-oci-source".format(_name)) if _syncUrl else True

_oxr = {
    **oxr
    status: {
        operatorReady: _operatorReady
        instanceReady: _instanceReady
        sourceReady: _sourceReady
        ready: _operatorReady and _instanceReady and _sourceReady
        syncUrl: _syncUrl
        syncRef: oxr.spec.instance?.sync?.ref or ""
        providerConfigRef: oxr.spec.providerConfigRef
    }
}

items = [_oxr]
```

---

## EnvironmentConfig to Create

File: `examples/environmentconfig.yaml`

```yaml
apiVersion: apiextensions.crossplane.io/v1alpha1
kind: EnvironmentConfig
metadata:
  name: flux-defaults
data:
  operatorChart:
    version: "0.45.1"
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
    sync:
      kind: OCIRepository
      ref: latest
      path: clusters/default
  namespace: "flux-system"
  reconcileEvery: "1h"
  reconcileTimeout: "5m"
```

---

## functions.yaml Must Reference

```yaml
- apiVersion: pkg.crossplane.io/v1beta1
  kind: Function
  metadata:
    name: function-kcl
  spec:
    package: xpkg.upbound.io/crossplane-contrib/function-kcl:v0.10.4
```

---

## Example Claims

**examples/claim.yaml** — with OCI source:
```yaml
apiVersion: platform.stuttgart-things.com/v1alpha1
kind: FluxInitClaim
metadata:
  name: dev-cluster-flux
  namespace: crossplane-system
spec:
  providerConfigRef: dev-cluster
  instance:
    sync:
      kind: OCIRepository
      url: oci://ghcr.io/stuttgart-things/fleet-infra
      ref: latest
      path: clusters/dev
```

**examples/claim-minimal.yaml** — controllers only, no sync source:
```yaml
apiVersion: platform.stuttgart-things.com/v1alpha1
kind: FluxInitClaim
metadata:
  name: lab-flux
  namespace: crossplane-system
spec:
  providerConfigRef: lab-cluster
```

---

## Managed Resource Summary

| # | Crossplane Kind | Renders | Condition |
|---|----------------|---------|-----------|
| 1 | `helm.crossplane.io/v1beta1 Release` | flux-operator HelmRelease | always |
| 2 | `kubernetes.crossplane.io/v1alpha2 Object` | FluxInstance CR | always |
| 3 | `kubernetes.crossplane.io/v1alpha2 Object` | OCIRepository CR | only when `sync.url` set |

---

## Validation Checklist

After generating, verify:
- [ ] XRD has `claimNames` block (`FluxInitClaim` / `fluxinitclaims`)
- [ ] XRD `openAPIV3Schema` has both `spec` and `status` fields
- [ ] `sync` block in spec is fully optional — no `required` on it
- [ ] XRD `apiVersion` is `apiextensions.crossplane.io/v2`
- [ ] Composition `apiVersion` is `apiextensions.crossplane.io/v1` (not v2)
- [ ] Composition references `environment.environmentConfigs: flux-defaults`
- [ ] Pipeline has exactly 2 KCL steps: `render` and `patch-status`
- [ ] No go-templating or patch-and-transform remains
- [ ] OCIRepository Object only emitted when `sync.url` is set
- [ ] `sourceReady` defaults to `True` when no sync URL provided
- [ ] `examples/environmentconfig.yaml` created with chart version `0.45.1`
- [ ] `examples/claim-minimal.yaml` created (no sync block)
- [ ] `examples/functions.yaml` references `function-kcl`
