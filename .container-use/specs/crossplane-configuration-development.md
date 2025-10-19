# Crossplane Configuration Development Specification

> **Version**: 1.0.0
> **Status**: Draft
> **Author**: Stuttgart-Things Team
> **Date**: October 19, 2025
> **Last Updated**: October 19, 2025

## Abstract

This specification defines the standardized approach for developing Crossplane configurations within the Stuttgart-Things organization. It provides a structured methodology for creating, testing, and maintaining Crossplane configurations using KCL modules, Container-Use environments, and automated validation workflows.

## Table of Contents

1. [Overview](#overview)
2. [Terminology](#terminology)
3. [Development Workflow](#development-workflow)
4. [Directory Structure](#directory-structure)
5. [Configuration Components](#configuration-components)
6. [Testing Requirements](#testing-requirements)
7. [Container-Use Integration](#container-use-integration)
8. [Quality Gates](#quality-gates)
9. [Examples](#examples)
10. [References](#references)

## 1. Overview

### 1.1 Purpose

This specification establishes a consistent approach for developing Crossplane configurations that:

- Ensures reproducible development environments via Container-Use
- Standardizes configuration structure and naming conventions
- Defines mandatory testing and validation procedures
- Enables collaborative development and review processes
- Facilitates automated CI/CD pipelines

### 1.2 Scope

This specification applies to:

- **Application Configurations**: VCluster, Ansible-Run, etc.
- **Infrastructure Configurations**: Cilium, networking, storage
- **KCL Module Integration**: Using stuttgart-things/kcl modules
- **Container-Use Environments**: Development and testing environments

### 1.3 Goals

- **Standardization**: Consistent structure across all configurations
- **Automation**: Automated testing and validation workflows
- **Collaboration**: Clear development and review processes
- **Quality**: Mandatory testing before deployment
- **Documentation**: Comprehensive and maintainable documentation

## 2. Terminology

| Term | Definition |
|------|------------|
| **Configuration** | A complete Crossplane configuration package |
| **XRD** | Crossplane Composite Resource Definition |
| **Composition** | Crossplane Composition using KCL functions |
| **Claim** | User-facing API for requesting resources |
| **KCL Module** | Configuration logic written in KCL language |
| **Container-Use** | Development environment management system |
| **Render Test** | Local validation using `crossplane render` |

## 3. Development Workflow

### 3.1 Phase 1: Planning & Setup

#### 3.1.1 Environment Preparation

```bash
# 1. Setup Container-Use environment
source .container-use/container-use.sh
cu-setup

# 2. Access development environment
container-use checkout crossplane-development

# 3. Verify tool availability
crossplane version
kubectl version --client
kcl version
```

#### 3.1.2 Configuration Planning

Before development, define:

- **Resource Type**: Application vs Infrastructure
- **KCL Module**: New or existing module usage
- **API Design**: XRD schema and claim structure
- **Dependencies**: Required providers and functions
- **Testing Strategy**: Local and integration test approach

### 3.2 Phase 2: Implementation

#### 3.2.1 Directory Structure Creation

```bash
# Create configuration directory
mkdir -p configurations/{category}/{name}
cd configurations/{category}/{name}

# Create required subdirectories
mkdir -p apis examples .container-use
```

#### 3.2.2 Component Development Order

1. **XRD Definition** (`apis/definition.yaml`)
2. **Function Configuration** (`examples/functions.yaml`)
3. **Composition Logic** (`apis/composition.yaml`)
4. **Example Claims** (`examples/claim.yaml`)
5. **Package Configuration** (`crossplane.yaml`)
6. **Documentation** (`README.md`)

### 3.3 Phase 3: Testing & Validation

#### 3.3.1 Local Render Testing

```bash
# Test basic rendering
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml

# Validate resource count
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '. | length' -

# Test with multiple claims
crossplane render examples/development.yaml apis/composition.yaml examples/functions.yaml
crossplane render examples/production.yaml apis/composition.yaml examples/functions.yaml
```

#### 3.3.2 Container-Use Testing

```bash
# Test via helper commands (outside environment)
cu-test-{configuration-name}

# Test all configurations
cu-test-all
```

### 3.4 Phase 4: Documentation & Review

#### 3.4.1 Documentation Requirements

- **README.md**: Complete usage documentation
- **TESTING.md**: Testing procedures (optional for complex configs)
- **API Examples**: Multiple claim examples
- **Troubleshooting**: Common issues and solutions

#### 3.4.2 Review Process

1. **Self-Review**: Local testing and validation
2. **Peer Review**: Code review via pull request
3. **Integration Testing**: Full cluster deployment test
4. **Documentation Review**: Accuracy and completeness

## 4. Directory Structure

### 4.1 Standard Layout

```
configurations/{category}/{name}/
├── apis/
│   ├── composition.yaml          # KCL-based composition
│   └── definition.yaml           # XRD specification
├── examples/
│   ├── claim.yaml               # Basic example claim
│   ├── development.yaml         # Development environment example
│   ├── production.yaml          # Production environment example
│   ├── functions.yaml           # Function configuration
│   └── xr.yaml                  # Composite resource example (optional)
├── crossplane.yaml              # Package configuration
├── README.md                    # Complete documentation
└── TESTING.md                   # Testing procedures (optional)
```

### 4.2 Category Guidelines

| Category | Purpose | Examples |
|----------|---------|----------|
| `apps/` | Application deployments | vcluster, ansible-run |
| `infra/` | Infrastructure components | cilium, networking |
| `platform/` | Platform services | monitoring, logging |

## 5. Configuration Components

### 5.1 XRD Definition (`apis/definition.yaml`)

**Requirements**:
- API version: `apps.stuttgart-things.com/v1alpha1` or appropriate group
- Complete OpenAPI schema with validation
- Connection secret configuration
- Status subresource definition

**Template**:
```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: x{resources}.{group}.stuttgart-things.com
spec:
  group: {group}.stuttgart-things.com
  names:
    kind: X{Resource}
    plural: x{resources}
  claimNames:
    kind: {Resource}
    plural: {resources}
  connectionSecretKeys:
    - kubeconfig
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        # Complete OpenAPI schema
```

### 5.2 Composition (`apis/composition.yaml`)

**Requirements**:
- KCL function usage mandatory
- Stuttgart-Things KCL module from OCI registry
- Parameter mapping from XR spec
- Proper resource naming conventions

**Template**:
```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: x{resource}-kcl
spec:
  compositeTypeRef:
    apiVersion: {group}.stuttgart-things.com/v1alpha1
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
            spec: {}  # Parameter mapping from XR spec
```

### 5.3 Function Configuration (`examples/functions.yaml`)

**Requirements**:
- KCL function definition
- Version specification
- Provider dependencies

**Template**:
```yaml
---
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: function-kcl
spec:
  package: xpkg.upbound.io/crossplane-contrib/function-kcl:v0.9.0
```

### 5.4 Example Claims

#### 5.4.1 Basic Claim (`examples/claim.yaml`)
- Simple configuration for getting started
- All required parameters specified
- Clear naming and namespace

#### 5.4.2 Environment-Specific Claims
- `development.yaml`: Development-optimized settings
- `production.yaml`: Production-ready configuration
- Custom values and resource allocations

### 5.5 Package Configuration (`crossplane.yaml`)

**Requirements**:
- Proper metadata and annotations
- Dependency declarations
- Version constraints
- Complete README in metadata

## 6. Testing Requirements

### 6.1 Mandatory Tests

#### 6.1.1 Render Tests
```bash
# Basic render test
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml

# Multi-claim validation
for claim in examples/*.yaml; do
  if [[ "$claim" != *"functions.yaml" ]]; then
    crossplane render "$claim" apis/composition.yaml examples/functions.yaml
  fi
done
```

#### 6.1.2 Resource Count Validation
```bash
# Verify expected resource count
RESOURCE_COUNT=$(crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '. | length' -)
echo "Generated resources: $RESOURCE_COUNT"
```

#### 6.1.3 Schema Validation
```bash
# Validate YAML syntax
yq e . examples/claim.yaml
yq e . apis/composition.yaml
yq e . apis/definition.yaml
```

### 6.2 Container-Use Integration Tests

#### 6.2.1 Automated Testing
```bash
# Test individual configuration
cu-test-{configuration-name}

# Test all configurations
cu-test-all
```

#### 6.2.2 Build Tests
```bash
# Package build test
cu-build configurations/{category}/{name}
```

### 6.3 Quality Metrics

| Metric | Requirement |
|--------|------------|
| **Render Time** | < 30 seconds |
| **Resource Count** | Must match specification |
| **Schema Validation** | No YAML/JSON errors |
| **Documentation** | 100% API coverage |

## 7. Container-Use Integration

### 7.1 Environment Requirements

All development MUST use the standardized Container-Use environment:

```bash
# Environment access
container-use checkout crossplane-development

# Tool availability validation
xp version          # Crossplane CLI
k version --client  # kubectl
helm version        # Helm
yq --version        # YAML processor
kcl version         # KCL CLI
```

### 7.2 Development Commands

#### 7.2.1 Inside Environment
```bash
# Quick testing shortcuts
test-vcluster         # Test VCluster configuration
test-ansible-run      # Test Ansible-Run configuration

# Manual testing
xp-render examples/claim.yaml apis/composition.yaml examples/functions.yaml
xp-build --package-root=.
```

#### 7.2.2 Outside Environment (via helpers)
```bash
# Load helper functions
source .container-use/container-use.sh

# Run tests
cu-test-{configuration-name}
cu-test-all
cu-build configurations/{category}/{name}
```

### 7.3 Environment Validation

Before development, validate environment:

```bash
# Health checks (inside environment)
crossplane version    # Should show v1.20.0+
kubectl version       # Should show v1.31.0+
docker ps            # Docker daemon running
kcl version          # Should show v0.11.3+
```

## 8. Quality Gates

### 8.1 Pre-Commit Requirements

Before committing code:

- [ ] All render tests pass
- [ ] Resource count validation successful
- [ ] YAML syntax validation clean
- [ ] Documentation updated
- [ ] Container-Use tests pass

### 8.2 Pull Request Requirements

Before merging:

- [ ] Peer review completed
- [ ] All automated tests pass
- [ ] Integration test successful
- [ ] Documentation review approved
- [ ] Breaking changes documented

### 8.3 Release Requirements

Before tagging release:

- [ ] Full test suite passes
- [ ] Package builds successfully
- [ ] Documentation complete
- [ ] Version numbers updated
- [ ] Release notes prepared

## 9. Examples

### 9.1 Complete VCluster Example

See [configurations/apps/vcluster/](../../configurations/apps/vcluster/) for a reference implementation following this specification.

**Key Features**:
- KCL-based composition using `oci://ghcr.io/stuttgart-things/xplane-vcluster`
- Complete XRD with connection secret support
- Multiple example claims (basic, development, production)
- Comprehensive documentation and testing

### 9.2 Development Workflow Example

```bash
# 1. Setup
source .container-use/container-use.sh && cu-setup
container-use checkout crossplane-development

# 2. Create new configuration
mkdir -p configurations/apps/my-app
cd configurations/apps/my-app

# 3. Develop components (XRD, Composition, Claims)
# ... implementation ...

# 4. Test locally
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml

# 5. Validate via Container-Use
cu-test-my-app

# 6. Build package
cu-build configurations/apps/my-app

# 7. Documentation and review
# ... documentation ...
```

## 10. References

### 10.1 Tools and Dependencies

- **Crossplane CLI**: [Installation Guide](https://docs.crossplane.io/latest/cli/)
- **KCL Language**: [Documentation](https://kcl-lang.io/)
- **Stuttgart-Things KCL Modules**: [Repository](https://github.com/stuttgart-things/kcl)
- **Container-Use**: Environment management system

### 10.2 Stuttgart-Things Standards

- **KCL Module Registry**: `oci://ghcr.io/stuttgart-things/xplane-{module}`
- **API Group**: `{category}.stuttgart-things.com`
- **Function Versions**: KCL Function >= v0.9.0
- **Provider Versions**: See individual configuration dependencies

### 10.3 Related Specifications

- Container-Use Environment Specification (see `.container-use/README-container-use.md`)
- Stuttgart-Things Development Guidelines
- Crossplane Configuration Best Practices

---

**Document Status**: This specification is a living document and will be updated as new requirements and best practices emerge.

**Feedback**: Please create issues or pull requests for improvements to this specification.