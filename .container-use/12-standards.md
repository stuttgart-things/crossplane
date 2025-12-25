# Stuttgart-Things Code Standards

## Naming Conventions

### Universal Standards

#### Repository Naming
- **Format**: `{technology}-{purpose}` or `{category}-{name}`
- **Examples**:
  - `kcl` (KCL modules repository)
  - `crossplane` (Crossplane configurations repository)
  - `terraform-provider-vsphere` (Terraform provider)
  - `ansible-collections` (Ansible collection repository)

#### Branch Naming
- **Format**: `{type}/{description}`
- **Types**: `feat/`, `fix/`, `chore/`, `docs/`, `refactor/`, `test/`
- **Examples**:
  - `feat/vault-config-module`
  - `fix/boolean-handling-edge-case`
  - `chore/update-dependencies`
  - `docs/improve-testing-guide`

#### Tag Naming
- **Format**: Semantic versioning `v{MAJOR}.{MINOR}.{PATCH}`
- **Examples**: `v1.0.0`, `v0.1.5`, `v2.3.1-alpha.1`
- **Pre-release**: Use suffixes like `-alpha`, `-beta`, `-rc`

### Domain-Specific Naming

#### KCL Modules
- **Module Names**: `xplane-{service-name}`
- **Examples**: `xplane-vault-config`, `xplane-vcluster`, `xplane-ansible-run`
- **OCI Registry**: `oci://ghcr.io/stuttgart-things/xplane-{service-name}`

#### Crossplane Configurations
- **Configuration Names**: `configuration-{name}` or by category
- **Examples**: `vault-config`, `vcluster`, `ansible-run`
- **Directory Structure**: `configurations/{category}/{name}/`

#### Terraform Modules
- **Module Names**: `terraform-{provider}-{resource}`
- **Examples**: `terraform-vsphere-vm`, `terraform-aws-vpc`
- **Registry Format**: `stuttgart-things/{name}/{provider}`

#### Ansible Collections
- **Collection Names**: `stuttgart_things.{category}`
- **Examples**: `stuttgart_things.base`, `stuttgart_things.proxmox`
- **Galaxy Format**: `stuttgart_things.{category}`

---

## Documentation Standards

### Required Files

#### Universal Documentation
- [ ] **`README.md`** - Comprehensive usage guide (MANDATORY)
- [ ] **`CHANGELOG.md`** - Version history and changes (MANDATORY)
- [ ] **`LICENSE`** - Apache 2.0 license (MANDATORY)
- [ ] **`CONTRIBUTING.md`** - Contribution guidelines (for public repos)

#### Technology-Specific Documentation
- [ ] **`TESTING.md`** - Comprehensive testing procedures (for complex modules)
- [ ] **`API.md`** - API documentation (for libraries and modules)
- [ ] **`EXAMPLES.md`** - Extended examples and use cases
- [ ] **`TROUBLESHOOTING.md`** - Common issues and solutions

### README.md Structure

#### Standard Template
```markdown
# {Project Title}

{Brief description of purpose and functionality}

## Features

- {List key features and capabilities}
- {Highlight unique value propositions}
- {Include supported platforms/environments}

## Quick Start

### Prerequisites
{List required tools, versions, and dependencies}

### Installation
{Step-by-step installation instructions}

### Basic Usage
{Simple example to get started quickly}

## Usage Examples

### {Use Case 1}
{Detailed example with code and explanation}

### {Use Case 2}
{Another example showing different functionality}

## Configuration

### Parameters
{Document all configuration options}

### Environment Variables
{List required and optional environment variables}

### Advanced Configuration
{Complex configuration scenarios}

## Testing

### Local Testing
{How to run tests locally}

### Integration Testing
{How to run integration tests}

### Container-Use Testing
{How to use Container-Use for testing}

## Contributing

{Link to CONTRIBUTING.md or brief guidelines}

## License

{License information and link to LICENSE file}

## Support

{How to get help, report issues, or contact maintainers}
```

#### Expandable Sections
Use expandable sections for detailed information:

```markdown
<details>
<summary>Advanced Configuration Options</summary>

{Detailed configuration documentation that doesn't clutter the main view}

</details>
```

---

## Testing Standards

### Test Categories

#### 1. Syntax Tests
- **Purpose**: Validate YAML/HCL/KCL syntax and structure
- **Tools**: `yq`, `terraform validate`, `kcl vet`
- **Coverage**: All configuration files
- **Automation**: Pre-commit hooks and CI/CD

#### 2. Unit Tests
- **Purpose**: Test individual components and functions
- **Scope**: Module logic, validation rules, error handling
- **Tools**: Technology-specific testing frameworks
- **Coverage**: > 80% code coverage where applicable

#### 3. Integration Tests
- **Purpose**: Test cross-component interaction and interfaces
- **Scope**: Module composition, API integration, data flow
- **Environment**: Container-Use environments for consistency
- **Coverage**: All major integration points

#### 4. End-to-End Tests
- **Purpose**: Validate complete workflow and user scenarios
- **Scope**: Full deployment cycles, user workflows
- **Environment**: Dedicated test clusters/environments
- **Coverage**: All supported deployment scenarios

#### 5. Performance Tests
- **Purpose**: Validate resource usage, timing, and scalability
- **Metrics**: Memory usage, execution time, resource generation speed
- **Benchmarks**: Established performance baselines
- **Monitoring**: Continuous performance tracking

### Quality Gates

#### Pre-Commit Requirements
- [ ] All syntax tests pass
- [ ] Unit tests pass with >80% coverage
- [ ] Code formatting applied (automated)
- [ ] No hardcoded secrets or credentials
- [ ] Documentation updated for changes
- [ ] Naming conventions followed

#### Pull Request Requirements
- [ ] All automated tests pass
- [ ] Integration tests pass
- [ ] Code review completed by team member
- [ ] Documentation review completed
- [ ] Breaking changes documented
- [ ] Performance impact assessed

#### Release Requirements
- [ ] All test categories pass
- [ ] End-to-end testing completed
- [ ] Performance benchmarks met
- [ ] Security scan clean
- [ ] Documentation complete and accurate
- [ ] Version numbers updated correctly

---

## Security Standards

### Secret Management

#### Principles
- **Never commit secrets** to repositories (use secret scanners)
- **Use secret management systems** (Vault, Kubernetes secrets, cloud KMS)
- **Implement secret rotation** where possible and document procedures
- **Document secret requirements** clearly in README and setup guides

#### Implementation
```yaml
# Example: Kubernetes secret usage
apiVersion: v1
kind: Secret
metadata:
  name: example-secret
type: Opaque
data:
  # Use base64 encoded values, never plain text
  password: <base64-encoded-value>
```

#### Tools
- **Pre-commit hooks**: `gitleaks`, `truffleHog`
- **CI/CD scanning**: GitHub secret scanning, GitLab secret detection
- **Runtime scanning**: `kube-score`, security policy engines

### Access Control

#### Principles
- **Principle of least privilege**: Grant minimum required permissions
- **Use service accounts** for automation and CI/CD
- **Implement proper RBAC** in Kubernetes resources
- **Regular access review** and cleanup procedures

#### Kubernetes RBAC Example
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: minimal-required-role
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "create", "update"]
  # Only grant specific permissions needed
```

#### Guidelines
- Document all required permissions clearly
- Use namespace-scoped roles when possible
- Implement resource name restrictions where applicable
- Regular audit of service account usage

---

## Domain-Specific Standards

### Crossplane Configuration Standards

#### Directory Structure
```
configurations/{category}/{name}/
├── apis/
│   ├── composition.yaml          # KCL-based composition (MANDATORY)
│   └── definition.yaml           # XRD specification (MANDATORY)
├── examples/
│   ├── claim.yaml               # Basic example claim (MANDATORY)
│   ├── development.yaml         # Development environment example (MANDATORY)
│   ├── production.yaml          # Production environment example (MANDATORY)
│   ├── functions.yaml           # Function configuration (MANDATORY)
│   └── xr.yaml                  # Composite resource example (OPTIONAL)
├── crossplane.yaml              # Package configuration (MANDATORY)
├── README.md                    # Complete documentation (MANDATORY)
└── TESTING.md                   # Testing procedures (OPTIONAL for complex configs)
```

#### API Design Standards
```yaml
# XRD API group format
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: x{resources}.{category}.stuttgart-things.com
spec:
  group: {category}.stuttgart-things.com  # MANDATORY format
  names:
    kind: X{Resource}                      # PascalCase
    plural: x{resources}                   # lowercase plural
  claimNames:
    kind: {Resource}                       # PascalCase without X prefix
    plural: {resources}                    # lowercase plural
```

#### Required Annotations
```yaml
# All generated resources MUST include these annotations
metadata:
  annotations:
    crossplane.io/composition-resource-name: {logical-name}
    krm.kcl.dev/composition-resource-name: {module}-{type}-{instance}
```

#### Provider Standards
```yaml
# Standard provider versions for stuttgart-things
dependsOn:
- provider: xpkg.upbound.io/crossplane-contrib/function-kcl
  version: ">=v0.9.0"
- provider: ghcr.io/stuttgart-things/crossplane-provider-helm
  version: ">=v0.1.1"
- provider: xpkg.upbound.io/crossplane-contrib/provider-kubernetes
  version: ">=v0.18.0"
```

### KCL Module Standards

#### Module Structure
```
xplane-{service-name}/
├── main.k                       # Main module logic (MANDATORY)
├── test_main.k                  # Test cases (MANDATORY)
├── README.md                    # Documentation (MANDATORY)
├── examples/                    # Usage examples
│   ├── basic.yaml
│   ├── development.yaml
│   └── production.yaml
└── .container-use/              # Development environment
    ├── container-use.yaml
    └── container-use.sh
```

#### Code Standards
```python
# KCL code formatting and conventions
import crossplane

# Use descriptive variable names
crossplane_resources = []

# Document complex logic with comments
# Generate namespace resource with proper labels
namespace_resource = {
    apiVersion = "v1"
    kind = "Namespace"
    metadata = {
        name = namespace_name
        labels = base_labels | {
            "stuttgart-things.com/module" = "vault-config"
        }
    }
}

# Use consistent indentation (4 spaces)
# Group related resources logically
# Add validation for required parameters
```

#### Testing Requirements
```python
# test_main.k example structure
import main

# Test basic functionality
test_basic_generation = lambda {
    result = main.generate_resources({
        "clusterName": "test-cluster"
        "namespace": "vault-system"
    })

    # Validate resource count and types
    assert len(result) == 16, "Expected 16 resources"
    assert result[0]["kind"] == "Namespace", "First resource should be Namespace"
}

# Test edge cases and error conditions
test_boolean_handling = lambda {
    # Test boolean parameter handling
    result = main.generate_resources({
        "clusterName": "test"
        "enableCSI": True
        "enableVSO": False
    })

    # Validate conditional resource generation
    csi_resources = [r for r in result if "csi" in r.get("metadata", {}).get("name", "")]
    assert len(csi_resources) > 0, "CSI resources should be generated when enabled"
}
```

### Terraform Module Standards

#### Module Structure
```
terraform-{provider}-{resource}/
├── main.tf                      # Main resource definitions
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values
├── versions.tf                  # Provider version constraints
├── README.md                    # Documentation
├── examples/                    # Usage examples
│   ├── basic/
│   ├── complete/
│   └── minimal/
└── test/                        # Test configurations
    ├── integration_test.go
    └── unit_test.tf
```

#### Code Standards
```hcl
# Terraform formatting and conventions
terraform {
  required_version = ">= 1.0"
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.0"
    }
  }
}

# Use descriptive resource names
resource "vsphere_virtual_machine" "main" {
  name             = var.vm_name
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  # Group related configurations
  num_cpus = var.cpu_count
  memory   = var.memory_mb

  # Use consistent formatting
  guest_id = "ubuntu64Guest"

  # Add validation
  lifecycle {
    precondition {
      condition     = var.cpu_count > 0
      error_message = "CPU count must be greater than 0."
    }
  }
}
```

#### Variable Validation
```hcl
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.vm_name))
    error_message = "VM name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "cpu_count" {
  description = "Number of CPUs to allocate"
  type        = number
  default     = 2

  validation {
    condition     = var.cpu_count >= 1 && var.cpu_count <= 32
    error_message = "CPU count must be between 1 and 32."
  }
}
```

---

## Container-Use Integration Standards

### Environment Configuration

#### Standard container-use.yaml
```yaml
apiVersion: container-use/v1alpha1
kind: Environment
metadata:
  name: {technology}-development
spec:
  from_git_ref: main
  title: "{Technology} Development Environment"
  base_image: "ghcr.io/stuttgart-things/sthings-alpine:1.2024.10"
  setup_commands:
    - "apk add --no-cache {required-packages}"
    - "{technology-specific-setup-commands}"
  environment_variables:
    - "{TECHNOLOGY}_VERSION={version}"
    - "STUTTGART_THINGS_REGISTRY=ghcr.io/stuttgart-things"
```

#### Helper Functions
```bash
# Standard helper functions in container-use.sh

# Technology-specific setup
cu-setup-{technology}() {
    echo "Setting up {technology} development environment..."
    # Technology-specific setup commands
}

# Testing functions
cu-test-{module-name}() {
    container-use exec $DEV_ENV "cd {path} && {test-commands}"
}

cu-test-all() {
    echo "Running all {technology} tests..."
    # Iterate through all modules/configurations
}

# Build functions
cu-build-{type}() {
    container-use exec $DEV_ENV "cd $1 && {build-commands}"
}
```

### Environment Requirements

#### Tool Versions
- **Base Image**: `ghcr.io/stuttgart-things/sthings-alpine:1.2024.10`
- **Git**: Latest stable
- **Docker CLI**: Latest stable
- **yq**: v4.x latest
- **kubectl**: v1.31.0+

#### Technology-Specific Tools
```yaml
# Crossplane Environment
- crossplane: "v1.20.0+"
- kcl: "v0.11.2+"
- helm: "v3.12.0+"

# KCL Environment
- kcl: "v0.11.2+"
- docker: "latest"

# Terraform Environment
- terraform: "v1.5.0+"
- tflint: "latest"
- terraform-docs: "latest"

# Ansible Environment
- ansible: "v8.0.0+"
- ansible-lint: "latest"
- molecule: "latest"
```

---

## CI/CD Standards

### GitHub Actions Workflows

#### Standard Workflow Structure
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  STUTTGART_THINGS_REGISTRY: ghcr.io/stuttgart-things

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Container-Use
        run: |
          # Setup Container-Use environment
      - name: Run Tests
        run: |
          # Run technology-specific tests
      - name: Security Scan
        run: |
          # Run security scanning

  build:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Build and Publish
        run: |
          # Build and publish artifacts
```

#### Required Checks
- [ ] Syntax validation
- [ ] Unit tests
- [ ] Integration tests
- [ ] Security scanning
- [ ] License compliance
- [ ] Documentation validation

### Release Automation

#### Semantic Release Configuration
```yaml
# .releaserc.yml
preset: conventionalcommits
branches:
  - main
  - name: develop
    prerelease: beta
plugins:
  - "@semantic-release/commit-analyzer"
  - "@semantic-release/release-notes-generator"
  - "@semantic-release/github"
```

#### Automated Tasks
- [ ] Version bumping based on conventional commits
- [ ] Changelog generation
- [ ] Git tag creation
- [ ] Release notes generation
- [ ] Artifact publication
- [ ] Notification to dependent projects

This comprehensive standards document ensures consistency, quality, and maintainability across all Stuttgart-Things technology stacks and repositories.
