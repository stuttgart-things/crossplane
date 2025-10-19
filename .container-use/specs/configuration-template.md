# Configuration Development Template

> **Template Version**: 1.0.0
> **Based on**: [Crossplane Configuration Development Specification](crossplane-configuration-development.md)
> **Purpose**: Standardized template for new Crossplane configuration development

## Pre-Development Checklist

### Planning Phase

- [ ] **Configuration Name**: `{configuration-name}` defined
- [ ] **Category**: Selected from `apps/`, `infra/`, `platform/`
- [ ] **KCL Module**: Identified existing or plan new module
- [ ] **API Design**: XRD schema planned
- [ ] **Dependencies**: Required providers and functions identified
- [ ] **Testing Strategy**: Local and integration test approach defined

### Environment Setup

- [ ] **Container-Use**: Environment setup completed
- [ ] **Tool Verification**: All required tools available and correct versions
- [ ] **Repository Access**: Development environment prepared

```bash
# Environment Setup Commands
source .container-use/container-use.sh
cu-setup
container-use checkout crossplane-development

# Verify tools
crossplane version    # Should be ≥v1.20.0
kubectl version       # Should be ≥v1.31.0
kcl version          # Should be ≥v0.11.3
```

## Development Workflow

### Step 1: Directory Structure

```bash
# Create configuration structure
mkdir -p configurations/{category}/{name}
cd configurations/{category}/{name}
mkdir -p apis examples

# Expected structure:
# configurations/{category}/{name}/
# ├── apis/
# │   ├── composition.yaml
# │   └── definition.yaml
# ├── examples/
# │   ├── claim.yaml
# │   ├── development.yaml (optional)
# │   ├── production.yaml (optional)
# │   └── functions.yaml
# ├── crossplane.yaml
# └── README.md
```

### Step 2: XRD Development (`apis/definition.yaml`)

**Template Checklist**:
- [ ] API version follows Stuttgart-Things convention
- [ ] Complete OpenAPI schema with validation
- [ ] Connection secret configuration included
- [ ] Status subresource defined
- [ ] Proper naming conventions used

```yaml
# Template Structure
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: x{resources}.{category}.stuttgart-things.com
spec:
  group: {category}.stuttgart-things.com
  names:
    kind: X{Resource}
    plural: x{resources}
  claimNames:
    kind: {Resource}
    plural: {resources}
  connectionSecretKeys:
    - kubeconfig  # Add other keys as needed
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
                # Define complete schema here
              required:
                # List required fields
            status:
              type: object
              properties:
                # Define status fields
```

### Step 3: Function Configuration (`examples/functions.yaml`)

**Template**:
```yaml
---
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: function-kcl
spec:
  package: xpkg.upbound.io/crossplane-contrib/function-kcl:v0.9.0
---
# Add additional functions/providers as needed
```

### Step 4: Composition Development (`apis/composition.yaml`)

**Template Checklist**:
- [ ] KCL function used with Stuttgart-Things module
- [ ] Parameter mapping from XR spec configured
- [ ] Proper resource naming conventions
- [ ] Pipeline mode used

```yaml
# Template Structure
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: x{resource}-kcl
  labels:
    provider: stuttgart-things
    category: {category}
spec:
  compositeTypeRef:
    apiVersion: {category}.stuttgart-things.com/v1alpha1
    kind: X{Resource}
  mode: Pipeline
  pipeline:
    - step: {resource}-kcl
      functionRef:
        name: function-kcl
      input:
        apiVersion: krm.kcl.dev/v1alpha1
        kind: KCLInput
        source: oci://ghcr.io/stuttgart-things/xplane-{resource}
        params:
          oxr:
            spec:
              # Map parameters from XR spec
              name: ""
              # Add all parameters here
```

### Step 5: Example Claims Development

#### Basic Claim (`examples/claim.yaml`)
```yaml
apiVersion: {category}.stuttgart-things.com/v1alpha1
kind: {Resource}
metadata:
  name: {resource}-example
  namespace: default
spec:
  # Minimal required configuration
  name: {resource}-example
  # Add required parameters
writeConnectionSecretToRef:
  name: {resource}-connection
  namespace: default
```

#### Development Claim (`examples/development.yaml`)
```yaml
# Development-optimized configuration
# Include dev-specific settings, smaller resources, etc.
```

#### Production Claim (`examples/production.yaml`)
```yaml
# Production-ready configuration
# Include prod-specific settings, HA setup, etc.
```

### Step 6: Package Configuration (`crossplane.yaml`)

```yaml
apiVersion: meta.pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: configuration-{resource}
  annotations:
    meta.crossplane.io/maintainer: Stuttgart-Things
    meta.crossplane.io/source: github.com/stuttgart-things/crossplane
    meta.crossplane.io/license: Apache-2.0
    meta.crossplane.io/description: |
      {Brief description of the configuration}
    meta.crossplane.io/readme: |
      # {Resource} Configuration

      {Quick start and usage information}

      ## Features

      - Feature 1
      - Feature 2

      ## Usage

      ```yaml
      # Example usage
      ```
spec:
  crossplane:
    version: ">=v1.14.0"
  dependsOn:
    - provider: xpkg.upbound.io/crossplane-contrib/function-kcl
      version: ">=v0.9.0"
    # Add other dependencies
```

### Step 7: Documentation (`README.md`)

**Required Sections**:
- [ ] Overview and features
- [ ] Installation instructions
- [ ] Usage examples
- [ ] Configuration options
- [ ] Testing procedures
- [ ] Troubleshooting guide
- [ ] Dependencies and requirements

See [VCluster README](../../configurations/apps/vcluster/README.md) as reference.

## Testing Workflow

### Local Testing Checklist

- [ ] **Basic Render**: `crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml`
- [ ] **Resource Count**: Verify expected number of resources generated
- [ ] **Multiple Claims**: Test all example claims
- [ ] **Schema Validation**: No YAML/JSON syntax errors
- [ ] **Parameter Mapping**: All claim parameters properly passed to composition

### Container-Use Testing

```bash
# Test via helper commands (outside environment)
source .container-use/container-use.sh
cu-test-{configuration-name}  # If helper created
cu-test-all                   # Test all configurations

# Manual testing (inside environment)
container-use checkout crossplane-development
cd configurations/{category}/{name}
test-{configuration-name}     # If alias created
```

### Validation Commands

```bash
# Inside development environment

# 1. Render test
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml

# 2. Count validation
RESOURCE_COUNT=$(crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '. | length' -)
echo "Generated resources: $RESOURCE_COUNT"

# 3. Schema validation
yq e . examples/claim.yaml
yq e . apis/composition.yaml
yq e . apis/definition.yaml

# 4. Package build test
crossplane xpkg build --package-root=. --examples-root=examples
```

## Quality Gates

### Pre-Commit Checklist

- [ ] All render tests pass without errors
- [ ] Resource count matches expected output
- [ ] All YAML files validate successfully
- [ ] Documentation complete and accurate
- [ ] Container-Use tests pass
- [ ] No hardcoded values or secrets

### Review Checklist

- [ ] Code follows Stuttgart-Things conventions
- [ ] XRD schema is complete and validated
- [ ] Composition uses KCL function properly
- [ ] Examples are comprehensive and tested
- [ ] Documentation is clear and complete
- [ ] Testing procedures are documented

### Integration Testing

- [ ] Configuration deploys successfully in test cluster
- [ ] Generated resources function as expected
- [ ] Connection secrets work properly
- [ ] Clean-up procedures work correctly

## Common Patterns

### KCL Module Integration

```yaml
# Standard pattern for KCL function usage
source: oci://ghcr.io/stuttgart-things/xplane-{resource}
params:
  oxr:
    spec:
      # Direct mapping from XR spec
      name:
      version:
      # All parameters from XRD schema
```

### Connection Secret Handling

```yaml
# XRD connection secret configuration
connectionSecretKeys:
  - kubeconfig
  - endpoint
  - username
  - password
  # Add keys as needed

# Composition connection details
connectionDetails:
  - fromFieldPath: "data.config"
    name: "kubeconfig"
    type: "FromFieldPath"
```

### Parameter Validation

```yaml
# XRD schema validation examples
properties:
  name:
    type: string
    pattern: "^[a-z0-9-]+$"
    minLength: 1
    maxLength: 63
  version:
    type: string
    pattern: "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
  nodePort:
    type: integer
    minimum: 30000
    maximum: 32767
```

## Helper Commands Setup

### Add Configuration-Specific Helpers

Edit `.container-use/container-use.sh`:

```bash
# Add to existing functions
test_{configuration_name}() {
    echo "🧪 Testing {Resource} configuration..."
    container-use exec $CROSSPLANE_DEV_ENV "cd configurations/{category}/{name} && crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml"
}

# Add to aliases
alias cu-test-{configuration-name}="test_{configuration_name}"
```

### Update Helper Documentation

Update `.container-use/README.md` with new configuration testing commands.

## Troubleshooting

### Common Issues

#### Render Failures
- Check KCL module availability
- Verify parameter mapping in composition
- Validate XRD schema syntax

#### Resource Count Mismatches
- Review KCL module output
- Check composition pipeline configuration
- Validate function input parameters

#### Parameter Passing Issues
- Ensure proper `params.oxr.spec` structure
- Verify XRD schema matches claim structure
- Check composition parameter patches

### Debug Commands

```bash
# Verbose render output
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml --verbose

# Validate individual files
yq e . examples/claim.yaml
yq e . apis/composition.yaml
yq e . apis/definition.yaml

# Check function availability
kubectl get function function-kcl -o yaml
```

## Post-Development

### Documentation Updates

- [ ] Update main repository README if needed
- [ ] Add configuration to Container-Use helpers
- [ ] Update specifications if new patterns emerged
- [ ] Create or update integration tests

### Release Preparation

- [ ] Tag configuration version
- [ ] Update package version in crossplane.yaml
- [ ] Create release notes
- [ ] Test final package build

---

**Template Completion**: This template should be followed for all new Crossplane configuration development to ensure consistency and quality across the Stuttgart-Things organization.