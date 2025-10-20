# Stuttgart-Things Development Decisions

## Universal Organizational Decisions

### Decision 1: Container-Use Development Environment
- **Status**: ✅ Accepted
- **Date**: 2025-01-19
- **Applies to**: All repositories
- **Context**: Standardized development environments across all Stuttgart-Things projects
- **Consequences**: Consistent tooling, reproducible builds, easier onboarding

### Decision 2: Stuttgart-Things Domain and Naming
- **Status**: ✅ Accepted
- **Date**: 2025-01-19
- **Applies to**: All repositories
- **Context**: Consistent organizational branding and API grouping
- **Consequences**: All APIs use `*.stuttgart-things.com` groups, consistent repository naming

### Decision 3: Git Workflow and Conventional Commits
- **Status**: ✅ Accepted
- **Date**: 2025-01-19
- **Applies to**: All repositories
- **Context**: Version management and automation consistency
- **Consequences**: Automated semantic versioning, standardized commit messages

### Decision 4: Testing Strategy and Quality Gates
- **Status**: ✅ Accepted
- **Date**: 2025-01-19
- **Applies to**: All repositories
- **Context**: Quality assurance standards across all technology stacks
- **Consequences**: Mandatory testing before merge, consistent CI/CD pipelines

### Decision 5: Documentation Requirements
- **Status**: ✅ Accepted
- **Date**: 2025-01-19
- **Applies to**: All repositories
- **Context**: Knowledge sharing and onboarding standardization
- **Consequences**: Comprehensive README.md files, testing documentation, API examples

### Decision 6: OCI Registry for Modules and Packages
- **Status**: ✅ Accepted
- **Date**: 2025-01-19
- **Applies to**: All repositories
- **Context**: Centralized distribution of reusable components
- **Consequences**: All modules published to `ghcr.io/stuttgart-things/*`, version management

---

## Crossplane Configuration Decisions

### Decision CP-1: KCL Function-Based Architecture
- **Status**: ✅ Accepted
- **Date**: 2025-01-19
- **Context**: All compositions should use KCL functions from stuttgart-things registry
- **Consequences**: Standardized composition patterns, external KCL module dependency
- **Implementation**: All compositions MUST use `oci://ghcr.io/stuttgart-things/xplane-{module}` sources

### Decision CP-2: XRD Schema Design Standards
- **Status**: ✅ Accepted
- **Date**: 2025-01-19
- **Context**: API design consistency across configurations
- **Consequences**: Predictable API surfaces, easier integration
- **Implementation**: All XRDs use `{category}.stuttgart-things.com` API groups

### Decision CP-3: Multi-Environment Testing
- **Status**: ✅ Accepted
- **Date**: 2025-01-19
- **Context**: Support development and production configurations
- **Consequences**: Multiple example files required, testing complexity
- **Implementation**: Each configuration provides `development.yaml` and `production.yaml` examples

### Decision CP-4: Directory Structure Standardization
- **Status**: ✅ Accepted
- **Date**: 2025-10-20
- **Context**: Consistent configuration organization across all Crossplane modules
- **Consequences**: `apis/`, `examples/` directories mandatory, predictable file locations

### Decision CP-5: Container-Use Integration Mandatory
- **Status**: ✅ Accepted
- **Date**: 2025-10-20
- **Context**: All development must use Container-Use environments for consistency
- **Consequences**: Helper commands available, standardized tool versions
- **Implementation**: All configurations testable via `cu-test-{name}` commands

### Decision CP-6: Mandatory Resource Annotations
- **Status**: ✅ Accepted
- **Date**: 2025-10-20
- **Context**: Need traceability and identification of resources created by Crossplane compositions
- **Implementation**: All generated resources include standardized Crossplane and KCL annotations

### Decision CP-7: Provider and Function Standardization
- **Status**: ✅ Accepted
- **Date**: 2025-10-20
- **Context**: Consistent provider and function usage across all configurations
- **Implementation**: Pinned versions, coordinated upgrades, standard dependency list

---

## Crossplane Configuration Development Standards

### Directory Structure Requirements
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

### API Design Standards
- **API Groups**: Use `{category}.stuttgart-things.com/v1alpha1` format
- **Resource Names**: Clear, descriptive, following Kubernetes conventions
- **Connection Secrets**: Implement where applicable (especially for infrastructure)
- **OpenAPI Schema**: Complete validation schema with proper types and constraints

### KCL Module Integration
- **Registry Source**: Use `oci://ghcr.io/stuttgart-things/xplane-{module}` for all KCL modules
- **Version Pinning**: Pin to specific module versions for stability
- **Parameter Mapping**: Clear mapping from XR spec to KCL module parameters
- **Documentation**: Document KCL module dependencies and versions

### Testing Requirements
- **Local Render Tests**: All claims must render successfully with `crossplane render`
- **Resource Count Validation**: Must generate expected number of resources
- **Container-Use Integration**: Must pass `cu-test-{configuration-name}` validation
- **Multi-Environment Testing**: All example claims must render without errors

### Required Annotations
```yaml
# Required annotations on all generated resources
metadata:
  annotations:
    # Crossplane composition resource name
    crossplane.io/composition-resource-name: {logical-name}
    # KCL composition resource name for identification
    krm.kcl.dev/composition-resource-name: {module-prefix}-{resource-type}-{instance}
```

### Standard Providers
```yaml
# Required providers for stuttgart-things configurations
- provider: xpkg.upbound.io/crossplane-contrib/function-kcl
  version: ">=v0.9.0"
- provider: ghcr.io/stuttgart-things/crossplane-provider-helm
  version: ">=v0.1.1"
- provider: xpkg.upbound.io/crossplane-contrib/provider-kubernetes
  version: ">=v0.18.0"
```

### Configuration Categories
- **`configurations/apps/`**: Application-level deployments and services
- **`configurations/config/`**: Configuration management and settings
- **`configurations/infra/`**: Infrastructure provisioning and platform setup
- **`configurations/k8s/`**: Kubernetes-native resource management
- **`configurations/terraform/`**: Terraform-based infrastructure provisioning

### Quality Gates
- [ ] All render tests pass locally
- [ ] Container-Use tests pass (`cu-test-{name}`)
- [ ] Documentation complete and accurate
- [ ] Package builds successfully (`cu-build`)
- [ ] Multiple environment examples provided
- [ ] Code review completed
- [ ] Integration test successful

---

## Implementation Guidelines

### New Configuration Checklist
- [ ] Choose appropriate category based on purpose and scope
- [ ] Use stuttgart-things.com API domain with category subdomain
- [ ] Implement KCL function-based composition
- [ ] Include all required annotations on generated resources
- [ ] Set up Container-Use development environment
- [ ] Create comprehensive local testing suite
- [ ] Use standardized providers and functions with pinned versions
- [ ] Follow naming conventions and directory structure
- [ ] Document testing procedures and troubleshooting guides
- [ ] Implement CI/CD integration for automated testing

### Review Requirements
- [ ] Architecture follows KCL function pattern
- [ ] API design uses proper stuttgart-things.com domain
- [ ] All generated resources have required annotations
- [ ] Local testing passes all scenarios
- [ ] Documentation is complete and accurate
- [ ] Provider versions are pinned and compatible
- [ ] Category placement is logical and appropriate

---

**Document Status**: This specification is a living document and will be updated as new requirements and best practices emerge.

**Feedback**: Please create issues or pull requests for improvements to this specification.