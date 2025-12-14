# Crossplane Configuration Agents

## Overview

This document defines the standard structure and patterns for creating Crossplane configuration modules at Stuttgart-Things. Each configuration acts as an autonomous agent that provisions and manages infrastructure resources through declarative APIs.

## Core Principles

1. **Declarative Infrastructure**: Resources defined through Kubernetes custom resources
2. **Composition Pattern**: XRD + Composition + Functions = Resource Agent
3. **KCL Integration**: Use KCL functions for complex transformations via OCI modules
4. **Testability**: Local validation with `crossplane render` before cluster deployment
5. **Reusability**: OCI-based KCL modules shared across configurations

## Standard Folder Structure

Every Crossplane configuration module MUST follow this structure:

```
configuration-{name}/
├── apis/
│   ├── composition.yaml      # Composition with pipeline functions
│   └── definition.yaml        # XRD with claim types
├── crossplane.yaml            # Configuration package metadata
├── examples/
│   ├── claim.yaml            # Example XR/Claim instance
│   └── functions.yaml        # Function dependencies for testing
└── README.md                 # Module documentation
```

**3 directories, 6 files** - no more, no less for basic configurations.

## Component Specifications

### 1. Definition (XRD)

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

### 2. Composition

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

### 3. Configuration Package

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

### 4. Example Claim

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

### 5. Functions Declaration

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

## Development Workflow

### Phase 1: Design

1. **Define the API contract** in `apis/definition.yaml`
   - What resources will users create?
   - What parameters are required vs optional?
   - What's the user experience?

2. **Plan the KCL module structure**
   - What managed resources are needed?
   - How do parameters transform to resources?
   - What connection secrets are exposed?

### Phase 2: Implementation

1. **Create the KCL module** (separate repository/module)
   ```
   xplane-{resource}/
   ├── main.k          # Primary composition logic
   ├── kcl.mod         # Module dependencies
   └── README.md       # Module documentation
   ```

2. **Package and publish** to OCI registry
   ```bash
   kcl mod push oci://ghcr.io/stuttgart-things/xplane-{resource}:{version}
   ```

3. **Create the Crossplane configuration**
   - Write XRD in `apis/definition.yaml`
   - Write Composition in `apis/composition.yaml`
   - Write Configuration in `crossplane.yaml`
   - Create example in `examples/claim.yaml`
   - Add functions in `examples/functions.yaml`

### Phase 3: Testing

1. **Local testing** with crossplane CLI:
   ```bash
   # Test basic rendering
   crossplane render examples/claim.yaml \
                      apis/composition.yaml \
                      examples/functions.yaml

   # Verify output
   # - Check resource count
   # - Validate resource types
   # - Inspect generated manifests
   ```

2. **Integration testing** in cluster:
   ```bash
   # Install configuration
   kubectl apply -f crossplane.yaml
   kubectl apply -f apis/

   # Deploy claim
   kubectl apply -f examples/claim.yaml

   # Monitor status
   kubectl get x{resources} -w
   kubectl describe x{resource} {name}
   ```

3. **Validation checklist**:
   - [ ] XRD installs successfully
   - [ ] Composition references correct XRD
   - [ ] KCL module resolves from OCI registry
   - [ ] Claim creates expected resources
   - [ ] Connection secrets are generated (if applicable)
   - [ ] Resources reach ready state
   - [ ] No errors in crossplane logs

### Phase 4: Documentation

1. **README.md** must include:
   - Overview and features
   - Architecture diagram
   - Installation instructions
   - Configuration options table
   - Usage examples
   - Troubleshooting section

2. **Inline documentation**:
   - Comment complex XRD fields
   - Document composition pipeline steps
   - Explain parameter defaults

## KCL Module Integration

### OCI Registry Pattern

All KCL modules are published to `ghcr.io/stuttgart-things`:

```
oci://ghcr.io/stuttgart-things/xplane-{resource}:{version}
```

### Version Management

- **KCL Module Version**: Semantic versioning (e.g., `0.29.1`)
- **Configuration Version**: Tracks module version
- **Breaking Changes**: Bump major version

### Module Structure

```kcl
# main.k - Stuttgart-Things KCL module pattern
schema Config:
    """Configuration schema for resource composition"""
    name: str
    # ... additional fields

# Transform function
transform = lambda c: Config -> []:
    """Transforms Config into Kubernetes resources"""
    [
        {
            apiVersion: "v1"
            kind: "Resource"
            metadata.name: c.name
            # ... resource spec
        }
        # ... additional resources
    ]

# Expose Items for Crossplane
Items = transform(Config {
    # Map from observed composite resource spec
    name = option("params").oxr.spec.name
    # ... map additional fields
})
```

## Testing Strategy

### Local Testing (Recommended)

**Prerequisites**:
- Crossplane CLI v1.20.0+
- Docker (for KCL function runtime)

**Commands**:
```bash
# Basic render test
crossplane render examples/claim.yaml \
                   apis/composition.yaml \
                   examples/functions.yaml

# Verbose output
crossplane render examples/claim.yaml \
                   apis/composition.yaml \
                   examples/functions.yaml \
                   --verbose

# Multiple claim tests
for claim in examples/*.yaml; do
  echo "Testing $claim..."
  crossplane render $claim apis/composition.yaml examples/functions.yaml
done
```

**Expected Output**:
- Clean YAML manifests
- Correct resource types
- Proper metadata and labels
- Valid resource counts

### Cluster Testing

```bash
# Deploy to test cluster
kubectl apply -f crossplane.yaml
kubectl wait --for=condition=Healthy configuration/configuration-{resource}

# Apply resources
kubectl apply -f apis/
kubectl apply -f examples/claim.yaml

# Monitor
kubectl get x{resources} -w
kubectl describe x{resource} {name}

# Cleanup
kubectl delete -f examples/claim.yaml
kubectl delete -f apis/
```

## Common Patterns

### Connection Secret Management

When resources need credentials or kubeconfig access:

```yaml
# In XRD
spec:
  versions:
    - name: v1alpha1
      schema:
        openAPIV3Schema:
          properties:
            spec:
              properties:
                writeConnectionSecretToRef:
                  type: object
                  properties:
                    name:
                      type: string
                    namespace:
                      type: string
```

### ProviderConfig Generation

Create provider configs from connection secrets:

```kcl
# In KCL module
{
    apiVersion: "kubernetes.crossplane.io/v1alpha1"
    kind: "ProviderConfig"
    metadata.name: "${name}-provider"
    spec.credentials = {
        source: "Secret"
        secretRef = {
            name: connectionSecretName
            namespace: connectionSecretNamespace
            key: "kubeconfig"
        }
    }
}
```

### Multi-Step Pipelines

For complex compositions, chain multiple KCL functions:

```yaml
pipeline:
  - functionRef:
      name: function-kcl
    input:
      apiVersion: krm.kcl.dev/v1alpha1
      kind: KCLRun
      spec:
        source: oci://ghcr.io/stuttgart-things/xplane-{resource}-core
    step: create-core-resources

  - functionRef:
      name: function-kcl
    input:
      apiVersion: krm.kcl.dev/v1alpha1
      kind: KCLRun
      spec:
        source: oci://ghcr.io/stuttgart-things/xplane-{resource}-networking
    step: configure-networking
```

## Troubleshooting

### Common Issues

**Issue**: KCL module not found
```
Error: failed to pull OCI artifact: not found
```
**Solution**:
- Verify OCI path in composition
- Check module is published: `kcl mod metadata oci://ghcr.io/stuttgart-things/xplane-{resource}`
- Ensure version tag exists

**Issue**: XRD validation failed
```
Error: spec.names.kind is immutable
```
**Solution**: Delete and recreate XRD (only in development)
```bash
kubectl delete xrd x{resources}.github.stuttgart-things.com
kubectl apply -f apis/definition.yaml
```

**Issue**: Composition not selecting claims
```
Condition: Ready, Status: False, Reason: CompositeResourceNotReady
```
**Solution**: Check composition selector matches XRD
```bash
kubectl get composition xplane-{resource} -o yaml
kubectl get xrd x{resources}.github.stuttgart-things.com -o yaml
```

### Debug Commands

```bash
# Check function status
kubectl get functions
kubectl logs -n crossplane-system deployment/function-kcl

# Check composition status
kubectl get compositions
kubectl describe composition xplane-{resource}

# Check composite resource
kubectl get x{resources} -o wide
kubectl describe x{resource} {name}

# Check managed resources
kubectl get managed

# Crossplane logs
kubectl logs -n crossplane-system deployment/crossplane -f
```

## Best Practices

### API Design

1. **Keep APIs Simple**: Start with minimal required fields
2. **Use Sensible Defaults**: Reduce user configuration burden
3. **Semantic Naming**: Field names should be self-explanatory
4. **Documentation**: Comment every field in XRD schema

### Composition Design

1. **Single Responsibility**: One composition per resource type
2. **Idempotent Operations**: Ensure safe re-application
3. **Error Handling**: Use appropriate conditions and status
4. **Resource Naming**: Predictable, deterministic names

### KCL Module Design

1. **Pure Functions**: No side effects in transformations
2. **Validation**: Validate inputs early
3. **Defaults**: Provide sensible default values
4. **Modularity**: Break complex logic into functions

### Testing

1. **Test Locally First**: Use `crossplane render` before cluster testing
2. **Multiple Scenarios**: Test with different parameter combinations
3. **Edge Cases**: Test minimum, maximum, and invalid values
4. **Integration Tests**: Verify actual resource creation in cluster

### Documentation

1. **README Template**: Use consistent structure across modules
2. **Usage Examples**: Provide complete, working examples
3. **Troubleshooting**: Document common issues and solutions
4. **Architecture Diagrams**: Visual representation of resource flow

## Module Registry

Stuttgart-Things maintains KCL modules at:

```
ghcr.io/stuttgart-things/xplane-{module}:{version}
```

**Available Modules**:
- `xplane-vcluster`: VCluster deployment with connection secrets
- `xplane-vm`: Virtual machine provisioning
- `xplane-database`: Database instance management
- *(Add your modules here)*

## References

- **Crossplane Documentation**: https://docs.crossplane.io
- **KCL Language Guide**: https://kcl-lang.io/docs
- **Stuttgart-Things GitHub**: https://github.com/stuttgart-things
- **OCI Registry**: https://github.com/orgs/stuttgart-things/packages

## Contribution Guidelines

1. **Fork** the repository
2. **Create** a feature branch
3. **Test** locally with `crossplane render`
4. **Document** all changes in README.md
5. **Submit** pull request with clear description

## Version History

- **v1.0.0** (2024-12): Initial agent specification for Crossplane configurations
- **v1.1.0** (2025-01): Added KCL function patterns and testing guidelines