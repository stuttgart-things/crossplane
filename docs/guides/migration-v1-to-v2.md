# Migrating Crossplane Helm Configurations from v1 to v2

This guide walks through converting an existing v1 Helm-based Crossplane configuration to the v2 format using `function-go-templating`.

## Overview of changes

| Area | v1 | v2 |
|---|---|---|
| XRD apiVersion | `apiextensions.crossplane.io/v1` | `apiextensions.crossplane.io/v2` |
| Composition location | `apis/composition.yaml` | `compositions/<name>.yaml` |
| Composition engine | `function-patch-and-transform` | `function-go-templating` (inline) |
| Helm API group | `helm.crossplane.io/v1beta1` | `helm.m.crossplane.io/v1beta1` |
| Crossplane version | `>=v1.19.0-0` | `>=2.13.0` |
| Provider targeting | `providerConfigRef.name` only | `targetCluster` with scope (Namespaced/Cluster) |
| Ready detection | implicit | explicit `function-auto-ready` pipeline step |

## Step 1 — Update the XRD (`apis/definition.yaml`)

### Change apiVersion

```yaml
# Before
apiVersion: apiextensions.crossplane.io/v1

# After
apiVersion: apiextensions.crossplane.io/v2
```

### Add v2 spec fields

Add `defaultCompositeDeletePolicy`, `scope`, and `singular` name directly under `spec`:

```yaml
spec:
  group: resources.stuttgart-things.com
  defaultCompositeDeletePolicy: Foreground
  scope: Namespaced
  names:
    kind: XMyApp
    plural: xmyapps
    singular: xmyapp    # new
  claimNames:
    kind: MyApp
    plural: myapps
```

### Remove connectionSecretKeys

If your v1 XRD has `connectionSecretKeys` and you're not actually exporting secrets, remove it:

```yaml
# Remove this block
spec:
  connectionSecretKeys:
    - kubeconfig
```

### Add targetCluster to the schema

Replace the old `clusterName`/`clusterConfig` field with the `targetCluster` pattern:

```yaml
properties:
  spec:
    type: object
    properties:
      targetCluster:
        type: object
        required:
          - name
        properties:
          name:
            type: string
            default: in-cluster
            description: Name of the ProviderConfig / ClusterProviderConfig
          scope:
            type: string
            enum:
              - Namespaced
              - Cluster
            default: Namespaced
            description: |
              Whether to use ProviderConfig (Namespaced)
              or ClusterProviderConfig (Cluster)
```

### Add status schema

Add a `status` block so the composition can report back:

```yaml
properties:
  # ... spec ...
  status:
    type: object
    properties:
      installed:
        type: boolean
        description: Whether the app is installed
```

## Step 2 — Convert the Composition

### Move the file

```bash
mkdir -p compositions/
# Create new file, delete old one
mv apis/composition.yaml compositions/<name>.yaml  # or create fresh
```

### Convert from patch-and-transform to go-templating

The v1 composition uses `function-patch-and-transform` with a base resource and patches array. In v2, you write an inline Go template that renders the desired resources directly.

**v1 (patch-and-transform):**

```yaml
pipeline:
  - functionRef:
      name: function-patch-and-transform
    input:
      apiVersion: pt.fn.crossplane.io/v1beta1
      kind: Resources
      resources:
        - base:
            apiVersion: helm.crossplane.io/v1beta1
            kind: Release
            spec:
              forProvider:
                chart:
                  version: 0.12.0
              providerConfigRef:
                name: in-cluster
          patches:
            - fromFieldPath: spec.clusterName
              toFieldPath: spec.providerConfigRef.name
            - fromFieldPath: spec.version
              toFieldPath: spec.forProvider.chart.version
    step: patch-and-transform
```

**v2 (go-templating):**

```yaml
pipeline:
  - step: deploy-my-app
    functionRef:
      name: function-go-templating
    input:
      apiVersion: gotemplating.fn.crossplane.io/v1beta1
      kind: GoTemplate
      source: Inline
      inline:
        template: |
          {{- $spec := .observed.composite.resource.spec -}}

          {{- $scope := $spec.targetCluster.scope | default "Namespaced" -}}
          {{- $pcKind := "ProviderConfig" -}}
          {{- if eq $scope "Cluster" -}}
          {{- $pcKind = "ClusterProviderConfig" -}}
          {{- end -}}

          {{- $provider := $spec.targetCluster.name | default "in-cluster" -}}
          ---
          apiVersion: helm.m.crossplane.io/v1beta1
          kind: Release
          metadata:
            annotations:
              {{ setResourceNameAnnotation "my-app" }}
          spec:
            providerConfigRef:
              name: {{ $provider }}
              kind: {{ $pcKind }}
            forProvider:
              chart:
                version: {{ $spec.version | default "1.0.0" }}

          ---
          apiVersion: resources.stuttgart-things.com/v1alpha1
          kind: XMyApp
          status:
            installed: true

  - step: automatically-detect-ready-composed-resources
    functionRef:
      name: crossplane-contrib-function-auto-ready
```

Key conversion rules:

- Each `fromFieldPath` patch becomes a Go template variable read from `$spec`
- `CombineFromComposite` patches with `fmt` become Go `printf` calls
- `setResourceNameAnnotation` replaces manual `crossplane.io/external-name` annotations
- The Helm API group changes to `helm.m.crossplane.io/v1beta1`
- Add a status resource at the end of the template
- Add `function-auto-ready` as the final pipeline step

## Step 3 — Update `crossplane.yaml`

```yaml
spec:
  crossplane:
    version: ">=2.13.0"      # was >=v1.19.0-0
  dependsOn:
    - provider: xpkg.upbound.io/crossplane-contrib/provider-helm
      version: ">=v0.19.0"
    # Remove provider-kubernetes if not used
```

## Step 4 — Create `examples/functions.yaml`

```yaml
apiVersion: pkg.crossplane.io/v1beta1
kind: Function
metadata:
  name: function-go-templating
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-go-templating:v0.11.3
---
apiVersion: pkg.crossplane.io/v1beta1
kind: Function
metadata:
  name: crossplane-contrib-function-auto-ready
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-auto-ready:v0.6.0
```

## Step 5 — Create `examples/provider-config.yaml`

```yaml
apiVersion: helm.m.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: in-cluster
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: in-cluster
      key: config
```

## Step 6 — Update the example XR

The example must use the **XR kind** (not the claim kind) for `crossplane render` to work:

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: XMyApp          # XR kind, not the claim kind
metadata:
  name: test
spec:
  targetCluster:
    name: in-cluster
    scope: Namespaced
```

## Step 7 — Validate with crossplane render

```bash
crossplane render examples/<name>.yaml \
  compositions/<name>.yaml \
  examples/functions.yaml \
  --include-function-results
```

This should output the rendered Helm Release resource and a function result confirming readiness.

## Checklist

- [ ] XRD apiVersion changed to `apiextensions.crossplane.io/v2`
- [ ] Added `defaultCompositeDeletePolicy: Foreground` and `scope: Namespaced`
- [ ] Removed `connectionSecretKeys` (if unused)
- [ ] Added `targetCluster` field with scope support
- [ ] Added `status` schema
- [ ] Moved composition to `compositions/` directory
- [ ] Converted to `function-go-templating` with inline template
- [ ] Updated Helm API group to `helm.m.crossplane.io/v1beta1`
- [ ] Added `function-auto-ready` as final pipeline step
- [ ] Updated `crossplane.yaml` version to `>=2.13.0`
- [ ] Removed unused `provider-kubernetes` dependency
- [ ] Created `examples/functions.yaml` and `examples/provider-config.yaml`
- [ ] Example uses XR kind (not claim kind)
- [ ] `crossplane render` runs without errors
