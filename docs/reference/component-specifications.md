# Component Specifications

## 1. XRD — CompositeResourceDefinition

**Path:** `apis/definition.yaml`

The XRD defines the API contract users interact with.

```yaml
---
apiVersion: apiextensions.crossplane.io/v2
kind: CompositeResourceDefinition
metadata:
  name: x<plural>.resources.stuttgart-things.com
spec:
  group: resources.stuttgart-things.com
  defaultCompositeDeletePolicy: Foreground
  scope: Namespaced
  names:
    kind: X<Kind>
    plural: x<plural>
    singular: x<singular>
  claimNames:
    kind: <Kind>
    plural: <plural>
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                targetCluster:
                  type: object
                  required: [name]
                  properties:
                    name:
                      type: string
                      default: in-cluster
                    scope:
                      type: string
                      enum: [Namespaced, Cluster]
                      default: Namespaced
                # app-specific fields here
              required:
                - targetCluster
            status:
              type: object
              properties:
                installed:
                  type: boolean
```

### Naming Conventions

| Element | Pattern | Example |
|---|---|---|
| Group | `resources.stuttgart-things.com` | — |
| XR Kind | `X<Kind>` | `XGithubController` |
| Claim Kind | `<Kind>` | `GithubController` |
| XRD name | `x<plural>.resources.stuttgart-things.com` | `xgithubcontrollers.resources.stuttgart-things.com` |

### Required v2 Fields

| Field | Value | Purpose |
|---|---|---|
| `apiVersion` | `apiextensions.crossplane.io/v2` | v2 XRD format |
| `defaultCompositeDeletePolicy` | `Foreground` | Clean deletion of composed resources |
| `scope` | `Namespaced` | Claims are namespace-scoped |

## 2. Composition

**Path:** `compositions/<name>.yaml`

The Composition defines the resource rendering pipeline using `function-go-templating`.

```yaml
---
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: <name>
  labels:
    crossplane.io/xrd: x<plural>.resources.stuttgart-things.com
spec:
  compositeTypeRef:
    apiVersion: resources.stuttgart-things.com/v1alpha1
    kind: X<Kind>
  mode: Pipeline
  pipeline:
    - step: deploy-<name>
      functionRef:
        name: function-go-templating
      input:
        apiVersion: gotemplating.fn.crossplane.io/v1beta1
        kind: GoTemplate
        source: Inline
        inline:
          template: |
            {{- $spec := .observed.composite.resource.spec -}}
            # ... template rendering managed resources ...

    - step: automatically-detect-ready-composed-resources
      functionRef:
        name: crossplane-contrib-function-auto-ready
```

### Pipeline Structure

Every composition has at minimum two steps:

1. **`deploy-<name>`** — Go template that renders managed resources
2. **`automatically-detect-ready-composed-resources`** — Auto-ready detection

### Helm Release API Group

All Helm releases use the managed provider API group:

```yaml
apiVersion: helm.m.crossplane.io/v1beta1
kind: Release
```

### Resource Naming

Use `setResourceNameAnnotation` instead of manual `crossplane.io/external-name` annotations:

```gotemplate
metadata:
  annotations:
    {{ setResourceNameAnnotation "my-release" }}
```

## 3. Configuration Package

**Path:** `crossplane.yaml`

```yaml
---
apiVersion: meta.pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: <name>
  annotations:
    meta.crossplane.io/maintainer: <email>
    meta.crossplane.io/source: https://github.com/stuttgart-things/crossplane
    meta.crossplane.io/license: Apache-2.0
    meta.crossplane.io/description: |
      deploys <name> with crossplane
    meta.crossplane.io/readme: |
      deploys <name> with crossplane
spec:
  crossplane:
    version: ">=2.13.0"
  dependsOn:
    - provider: xpkg.upbound.io/crossplane-contrib/provider-helm
      version: ">=v0.19.0"
```

### Required Settings

| Field | Value |
|---|---|
| `spec.crossplane.version` | `>=2.13.0` |
| `dependsOn` | Only providers actually used by the composition |

## 4. Function Declarations

**Path:** `examples/functions.yaml`

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

Function names in `functions.yaml` **must match** the `functionRef.name` in the composition.

## 5. Example XR

**Path:** `examples/<name>.yaml`

```yaml
---
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: X<Kind>           # Must use XR kind, not claim kind
metadata:
  name: test
spec:
  targetCluster:
    name: in-cluster
    scope: Namespaced
  # app-specific fields
```

The example must use the **XR kind** (e.g. `XGithubController`), not the claim kind, for `crossplane render` to work.
