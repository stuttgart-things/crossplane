# Stuttgart-Things Crossplane Development Environment

This directory contains the unified Container-Use configuration for Stuttgart-Things Crossplane development, aligned with organizational standards v1.0.0.

## 🚀 Quick Start

```bash
# From repository root
source .container-use/container-use.sh
cu-setup
```

## 📁 Unified Structure

- **`decisions-unified.md`** - Organizational decisions and Crossplane-specific standards
- **`tasks-unified.md`** - Development workflow with universal phases and domain extensions
- **`standards.md`** - Code standards, naming conventions, and quality requirements
- **`container-use.yaml`** - Environment configuration (aligned with unified standards)
- **`container-use.sh`** - Helper script with unified command patterns
- **`README.md`** - This overview

## 🛠️ Usage

### Environment Setup
```bash
# Setup development environment
source .container-use/container-use.sh && cu-setup

# Access environment
container-use checkout crossplane-development

# View your work output
container-use log crossplane-development
```

### Testing (Unified Command Pattern)
```bash
cu-test-vault-config      # Test Vault Config configuration
cu-test-vcluster          # Test VCluster configuration
cu-test-ansible-run       # Test Ansible-Run configuration
cu-test-all              # Test all configurations
```

### Standards & Documentation
```bash
show-decisions           # View organizational decisions
show-tasks              # View development task workflow
show-standards          # View code standards and conventions
```

### Building & Development
```bash
cu-build configurations/config/vault-config  # Build specific package
cu-new my-config apps                        # Create new configuration
```

## 📚 Stuttgart-Things Unified Standards

### Universal Development Phases
1. **Planning & Setup** - Project scoping, technology selection, environment setup
2. **Development** - Implementation following standards and patterns
3. **Quality Assurance** - Testing, review, security validation
4. **Publication & Release** - Version management, automated publication
5. **Maintenance & Evolution** - Monitoring, updates, community feedback

### Crossplane-Specific Standards
- **API Groups**: `{category}.stuttgart-things.com/v1alpha1`
- **KCL Modules**: `oci://ghcr.io/stuttgart-things/xplane-{name}`
- **Directory Structure**: `configurations/{category}/{name}/`
- **Required Files**: XRD, Composition, Examples (basic, dev, prod), Functions
- **Testing**: Multi-scenario validation with `crossplane render`

### Quality Gates
- [ ] All render tests pass for multiple scenarios
- [ ] Resource count matches specifications
- [ ] Container-Use integration tests pass (`cu-test-{name}`)
- [ ] Documentation complete and accurate
- [ ] Code review completed
- [ ] Security scan clean

## 🏗️ Configuration Categories

| Category | Purpose | Examples |
|----------|---------|----------|
| `apps/` | Application deployments | VCluster, Ansible-Run |
| `config/` | Configuration management | Vault Config, Certificate Management |
| `infra/` | Infrastructure provisioning | Network Setup, Storage Classes |
| `k8s/` | Kubernetes-native resources | RBAC, Network Policies |
| `terraform/` | Terraform-based infrastructure | Cloud Resources, Multi-cloud |

## 🔄 Development Workflow

1. **Setup Environment**: `cu-setup` → `container-use checkout crossplane-development`
2. **Create Configuration**: `cu-new {name} {category}` following unified structure
3. **Develop Components**: XRD → Composition → Examples → Documentation
4. **Local Testing**: `cu-test-{name}` for validation
5. **Quality Assurance**: All test scenarios, documentation review
6. **Build & Release**: `cu-build` → version tagging → publication

## 🎯 Benefits of Unified Approach

### For Developers
- **Consistent Experience** across all Stuttgart-Things repositories
- **Shared Command Patterns** (`cu-test-*`, `show-*`, etc.)
- **Unified Documentation** structure and standards
- **Cross-Repository Knowledge** transfer

### For Organization
- **Standardized Workflows** across technology stacks
- **Quality Consistency** through shared standards
- **Reduced Learning Curve** for new team members
- **Coordinated Evolution** of practices and tools

## 📞 Getting Help

- **Standards Questions**: `show-standards`
- **Development Workflow**: `show-tasks`
- **Organizational Decisions**: `show-decisions`
- **Command Help**: `crossplane_dev_help`
- **Issues**: Create GitHub issues in this repository

## 🔗 Related Stuttgart-Things Standards

- **KCL Repository**: Similar unified structure for KCL module development
- **Terraform Repository**: Unified standards for Terraform modules
- **Ansible Repository**: Unified standards for Ansible collections
- **Organization-wide**: Consistent Container-Use, Git workflows, OCI registries

---

**Stuttgart-Things Unified Standards v1.0.0** - Consistent, maintainable, and collaborative development across all technology stacks.
