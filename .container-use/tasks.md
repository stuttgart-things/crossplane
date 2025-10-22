# Stuttgart-Things Development Tasks

## Universal Development Phases

### Phase 1: Planning & Setup

- [ ] **1.1 Project Scoping and Requirements**
  - [ ] Define project purpose and scope clearly
  - [ ] Identify target technology stack and architecture
  - [ ] Document requirements and constraints
  - [ ] Choose appropriate repository category/technology

- [ ] **1.2 Technology Stack Selection**
  - [ ] Select appropriate technology (KCL, Crossplane, Terraform, Ansible)
  - [ ] Identify dependencies and required providers/modules
  - [ ] Define integration points and interfaces
  - [ ] Plan for testing and deployment strategies

- [ ] **1.3 Environment Setup via Container-Use**
  - [ ] Load Container-Use environment configuration
    ```bash
    source .container-use/container-use.sh && cu-setup
    ```
  - [ ] Access or create appropriate development environment
  - [ ] Verify tool availability and versions
  - [ ] Configure project-specific environment variables

- [ ] **1.4 Template Selection and Application**
  - [ ] Choose appropriate project template
  - [ ] Apply stuttgart-things naming conventions
  - [ ] Set up standard directory structure
  - [ ] Initialize documentation framework

### Phase 2: Development

- [ ] **2.1 Code Implementation Following Standards**
  - [ ] Follow domain-specific coding standards
  - [ ] Implement business logic and functionality
  - [ ] Apply consistent naming conventions
  - [ ] Use approved patterns and practices

- [ ] **2.2 Pattern Application and Consistency**
  - [ ] Apply domain-specific patterns (see below for details)
  - [ ] Ensure consistency with existing codebase
  - [ ] Follow organizational conventions
  - [ ] Implement proper error handling

- [ ] **2.3 Local Validation and Testing**
  - [ ] Execute local syntax and validation tests
  - [ ] Run unit tests and integration tests
  - [ ] Validate against schemas and interfaces
  - [ ] Performance testing and optimization

- [ ] **2.4 Documentation Creation**
  - [ ] Create comprehensive README.md
  - [ ] Document API interfaces and usage
  - [ ] Provide clear examples and use cases
  - [ ] Document troubleshooting procedures

### Phase 3: Quality Assurance

- [ ] **3.1 Automated Testing Execution**
  - [ ] Run full test suite locally
  - [ ] Execute Container-Use integrated tests
  - [ ] Validate end-to-end workflows
  - [ ] Check test coverage and quality metrics

- [ ] **3.2 Code Review and Compliance Check**
  - [ ] Self-review against standards checklist
  - [ ] Validate compliance with organizational policies
  - [ ] Check security best practices implementation
  - [ ] Verify documentation completeness

- [ ] **3.3 Security and Vulnerability Scanning**
  - [ ] Scan for security vulnerabilities
  - [ ] Validate secret management practices
  - [ ] Check for hardcoded credentials or sensitive data
  - [ ] Review access control and permissions

- [ ] **3.4 Performance Validation**
  - [ ] Benchmark performance against requirements
  - [ ] Validate resource usage and efficiency
  - [ ] Test scalability and limits
  - [ ] Optimize for production workloads

### Phase 4: Publication & Release

- [ ] **4.1 Version Management and Tagging**
  - [ ] Follow semantic versioning conventions
  - [ ] Create appropriate git tags
  - [ ] Update version numbers in configuration files
  - [ ] Prepare release notes and changelog

- [ ] **4.2 Automated Publication Workflow**
  - [ ] Trigger CI/CD pipeline for publication
  - [ ] Validate automated tests pass
  - [ ] Ensure all quality gates are met
  - [ ] Monitor publication process

- [ ] **4.3 Registry/Repository Publication**
  - [ ] Publish to appropriate registry (OCI, npm, etc.)
  - [ ] Update package metadata and descriptions
  - [ ] Verify availability and accessibility
  - [ ] Test installation from registry

- [ ] **4.4 Release Documentation**
  - [ ] Update repository documentation
  - [ ] Create release announcement
  - [ ] Update dependent projects if needed
  - [ ] Notify relevant teams and stakeholders

### Phase 5: Maintenance & Evolution

- [ ] **5.1 Monitoring and Health Checks**
  - [ ] Set up monitoring and alerting
  - [ ] Implement health checks and status pages
  - [ ] Monitor usage patterns and performance
  - [ ] Track error rates and user feedback

- [ ] **5.2 Dependency Updates**
  - [ ] Regularly update dependencies and providers
  - [ ] Test compatibility with new versions
  - [ ] Coordinate updates across related projects
  - [ ] Maintain security patch levels

- [ ] **5.3 Community Feedback Integration**
  - [ ] Monitor issues and feature requests
  - [ ] Prioritize and plan improvements
  - [ ] Engage with users and contributors
  - [ ] Maintain responsive support

- [ ] **5.4 Breaking Change Management**
  - [ ] Plan and communicate breaking changes
  - [ ] Provide migration guides and tools
  - [ ] Support multiple versions during transition
  - [ ] Coordinate with dependent projects

---

## Domain-Specific Task Extensions

### Crossplane Configuration Development

#### Planning & Setup Extensions
- [ ] **Configuration Category Selection**
  - [ ] Choose category: `apps/`, `config/`, `infra/`, `k8s/`, `terraform/`
  - [ ] Define API schema and parameters
  - [ ] Select required KCL modules from stuttgart-things registry
  - [ ] Plan provider dependencies and functions

- [ ] **Environment Setup**
  ```bash
  container-use checkout crossplane-development
  cd configurations/{category}/{name}
  ```

#### Development Extensions
- [ ] **XRD Development** (`apis/definition.yaml`)
  - [ ] Define composite resource API schema with OpenAPI validation
  - [ ] Configure connection secret keys for infrastructure resources
  - [ ] Use `{category}.stuttgart-things.com/v1alpha1` API group format
  - [ ] Add status subresource definition

- [ ] **Composition Development** (`apis/composition.yaml`)
  - [ ] Implement KCL function-based composition
  - [ ] Configure OCI module source: `oci://ghcr.io/stuttgart-things/xplane-{module}`
  - [ ] Define parameter mapping from XR spec to KCL module
  - [ ] Use pipeline mode with proper function references

- [ ] **Example Claims Development**
  - [ ] Create basic example (`examples/claim.yaml`)
  - [ ] Create development scenario (`examples/development.yaml`)
  - [ ] Create production scenario (`examples/production.yaml`)
  - [ ] Configure function dependencies (`examples/functions.yaml`)

#### Testing Extensions
- [ ] **Local Render Testing**
  ```bash
  crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml
  crossplane render examples/development.yaml apis/composition.yaml examples/functions.yaml
  crossplane render examples/production.yaml apis/composition.yaml examples/functions.yaml
  ```

- [ ] **Container-Use Integration Testing**
  ```bash
  cu-test-{configuration-name}  # Test specific configuration
  cu-test-all                   # Test all configurations
  ```

- [ ] **Resource Validation**
  - [ ] Verify expected resource count generation
  - [ ] Check required annotations presence
  - [ ] Validate naming conventions compliance
  - [ ] Test multiple claim scenarios

### KCL Module Development

#### Planning & Setup Extensions
- [ ] **Module Planning**
  - [ ] Define Crossplane resource types to generate
  - [ ] Plan variable structure and validation
  - [ ] Design boolean handling patterns
  - [ ] Plan namespace and RBAC requirements

- [ ] **Environment Setup**
  ```bash
  container-use checkout kcl-development
  cd xplane-{module-name}
  ```

#### Development Extensions
- [ ] **KCL Module Implementation** (`main.k`)
  - [ ] Import required schemas and providers
  - [ ] Implement variable validation and defaults
  - [ ] Create resource generation logic
  - [ ] Add proper annotations and labels

- [ ] **Testing and Validation** (`test_main.k`)
  - [ ] Create comprehensive test cases
  - [ ] Test different parameter combinations
  - [ ] Validate resource generation counts
  - [ ] Test boolean handling edge cases

#### Testing Extensions
- [ ] **Local KCL Testing**
  ```bash
  kcl run main.k -D params='{"oxr": {"spec": {...}}}'
  kcl test test_main.k
  ```

- [ ] **Integration Testing**
  ```bash
  kcl run --quiet main.k -D params='{"oxr": {"spec": {...}}}' --format yaml
  ```

### Terraform Module Development

#### Planning & Setup Extensions
- [ ] **Module Planning**
  - [ ] Define provider requirements and versions
  - [ ] Plan variable validation patterns
  - [ ] Design output standardization
  - [ ] Plan module composition and dependencies

- [ ] **Environment Setup**
  ```bash
  container-use checkout terraform-development
  cd terraform-{provider}-{resource}
  ```

#### Development Extensions
- [ ] **Terraform Module Implementation**
  - [ ] Define provider configurations
  - [ ] Implement resource definitions
  - [ ] Create variable validation rules
  - [ ] Standardize outputs and data sources

- [ ] **Testing and Validation**
  - [ ] Create comprehensive test cases
  - [ ] Implement validation tests
  - [ ] Test different variable combinations
  - [ ] Validate provider compatibility

#### Testing Extensions
- [ ] **Local Terraform Testing**
  ```bash
  terraform validate
  terraform plan
  terraform fmt -check
  ```

---

## Standard Commands by Domain

### Crossplane Configuration Commands

```bash
# Setup and Navigation
source .container-use/container-use.sh && cu-setup
container-use checkout crossplane-development
cd configurations/{category}/{name}

# Local Testing
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml
crossplane render examples/development.yaml apis/composition.yaml examples/functions.yaml

# Resource Count Validation
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '. | length' -

# Syntax Validation
yq e . examples/claim.yaml
yq e . apis/composition.yaml

# Container-Use Testing
cu-test-{configuration-name}
cu-test-all
```

### KCL Module Commands

```bash
# Setup and Navigation
source .container-use/container-use.sh && cu-setup
container-use checkout kcl-development
cd xplane-{module-name}

# Local Testing
kcl run main.k -D params='{"oxr": {"spec": {...}}}'
kcl test test_main.k

# Validation and Formatting
kcl fmt main.k
kcl vet main.k

# Integration Testing
kcl run --quiet main.k -D params='{"oxr": {"spec": {...}}}' --format yaml
```

### Terraform Module Commands

```bash
# Setup and Navigation
source .container-use/container-use.sh && cu-setup
container-use checkout terraform-development
cd terraform-{provider}-{resource}

# Local Testing
terraform validate
terraform plan
terraform fmt -check

# Testing and Validation
terraform test
tflint
```

---

## Quality Standards by Domain

### Universal Quality Gates
- [ ] All automated tests pass
- [ ] Documentation complete and accurate
- [ ] Code review completed
- [ ] Security scan clean
- [ ] Dependency vulnerability scan clean
- [ ] Performance meets requirements

### Crossplane Configuration Quality Gates
- [ ] All render tests pass for multiple scenarios
- [ ] Resource count matches specifications
- [ ] XRD schema complete with validation
- [ ] Container-Use integration tests pass
- [ ] KCL module dependencies properly versioned

### KCL Module Quality Gates
- [ ] All KCL tests pass
- [ ] Resource generation validated
- [ ] Boolean handling edge cases tested
- [ ] Module publishes to OCI registry successfully
- [ ] Crossplane integration tested

### Terraform Module Quality Gates
- [ ] Terraform validation passes
- [ ] Plan generation successful
- [ ] Provider compatibility validated
- [ ] Variable validation comprehensive
- [ ] Output standardization implemented

This unified task framework ensures consistent development practices across all Stuttgart-Things technology domains while providing specific guidance for each technology stack.
