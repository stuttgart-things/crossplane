# Component Specifications

## 1. Definition (XRD)

**Path**: `apis/definition.yaml`

The CompositeResourceDefinition defines the API contract:

```yaml
---
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: x{resources}.github.stuttgart-things.com
spec:
  group: github.stuttgart-things.com
  names:
    kind: X{Resource}               # Composite Resource (cluster-scoped)
    plural: x{resources}
  claimNames:
    kind: {Resource}                # Claim (namespace-scoped)
    plural: {resources}
  defaultCompositionRef:
    name: xplane-{resource}
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
                # Define your API fields here
                name:
                  type: string
                  description: Resource name
                # ... additional fields
              required:
                - name
```

**Naming Convention**:
- **Group**: `github.stuttgart-things.com` (standard for all modules)
- **XR Kind**: `X{Resource}` (e.g., `Xvcluster`, `Xdatabase`, `Xvm`)
- **Claim Kind**: `{Resource}` (e.g., `Vcluster`, `Database`, `Vm`)
- **Composition**: `xplane-{resource}` (e.g., `xplane-vcluster`)

## 2. Composition

**Path**: `apis/composition.yaml`

The Composition defines the resource transformation pipeline:

```yaml
---
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: xplane-{resource}
  labels:
    provider: xplane
spec:
  compositeTypeRef:
    apiVersion: github.stuttgart-things.com/v1alpha1
    kind: X{Resource}
  mode: Pipeline
  pipeline:
    - functionRef:
        name: function-kcl
      input:
        apiVersion: krm.kcl.dev/v1alpha1
        kind: KCLRun
        metadata:
          name: kcl-input
        spec:
          source: oci://ghcr.io/stuttgart-things/xplane-{resource}:{version}
          target: Resources
      step: create-{resource}
```

**Pipeline Pattern**:
- **Mode**: Always `Pipeline` for function-based compositions
- **Function**: Use `function-kcl` for KCL-based transformations
- **Source**: OCI module from `ghcr.io/stuttgart-things/xplane-{resource}`
- **Step Name**: Descriptive action (e.g., `create-vcluster`, `provision-database`)

## 3. Configuration Package

**Path**: `crossplane.yaml`

The Configuration metadata defines dependencies and versioning:

```yaml
---
apiVersion: meta.pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: configuration-{resource}
  annotations:
    meta.crossplane.io/maintainer: Stuttgart-Things
    meta.crossplane.io/source: github.com/stuttgart-things/crossplane
    meta.crossplane.io/license: Apache-2.0
    meta.crossplane.io/description: |
      Brief description of what this configuration provides.

      Features:
      - Feature 1
      - Feature 2
      - Feature 3
    meta.crossplane.io/readme: |
      # {Resource} Configuration

      Quick start guide and basic usage examples.

spec:
  crossplane:
    version: ">=v1.14.0"
  dependsOn:
    - provider: xpkg.upbound.io/crossplane-contrib/function-kcl
      version: ">=v0.9.0"
    # Add additional provider dependencies
```

**Required Dependencies**:
- **function-kcl**: Always required for KCL-based compositions
- **Providers**: Add specific providers needed (helm, kubernetes, etc.)

## 4. Example Claim

**Path**: `examples/claim.yaml`

Provide a working example that users can apply:

```yaml
---
apiVersion: github.stuttgart-things.com/v1alpha1
kind: X{Resource}
metadata:
  name: {resource}-example
  namespace: crossplane-system
spec:
  compositionRef:
    name: xplane-{resource}
  # Include all required fields with realistic values
  name: example-{resource}
  # ... additional parameters
```

**Best Practices**:
- Use realistic, working values
- Include comments for complex parameters
- Demonstrate common use cases
- Keep it simple for first-time users

## 5. Functions Declaration

**Path**: `examples/functions.yaml`

Declare functions for local testing with `crossplane render`:

```yaml
---
apiVersion: pkg.crossplane.io/v1beta1
kind: Function
metadata:
  name: function-kcl
spec:
  package: xpkg.upbound.io/crossplane-contrib/function-kcl:v0.11.5
```

**Note**: Only include functions used in your composition's pipeline.
