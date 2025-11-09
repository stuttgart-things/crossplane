# stuttart-things/crossplane

crossplane configurations, apis and examples

## CONFIGURATIONS

<details><summary><b>ANSIBLE-RUN</b></summary>

* [SEE-HOW-TO-USE](configurations/ansible-run/README.md)

* INSTALL

```bash
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: ansible-run
spec:
  package: ghcr.io/stuttgart-things/crossplane/ansible-run:11.0.0
EOF
```

</details>


## DEVELOPMENT

### Quick Start

```bash
# Setup standardized development environment
source .container-use/container-use.sh
cu-setup

# Access development environment
container-use checkout crossplane-development

# Test existing configurations
cu-test-vcluster
cu-test-ansible-run
cu-test-all
```

### Development Standards

This repository follows structured development specifications:

- 📋 **[Development Specification](.container-use/specs/crossplane-configuration-development.md)** - Complete development workflow
- 🛠️ **[Configuration Template](.container-use/specs/configuration-template.md)** - Standardized template for new configurations
- � **[Container-Use Workflow](docs/container-use-workflow.md)** - Environment merge and workflow automation
- �📚 **[Specifications Index](.container-use/specs/README.md)** - Overview of all specifications

### Workflow Automation

Standardized tasks for environment management:

```bash
# Interactive environment merge
task merge-environment

# Direct environment merge
task merge-environment-auto ENV_ID=your-env-id

# Pull request workflow
task merge-environment-pr

# View all available tasks
task do
```
- 🚀 **[Container-Use Setup](.container-use/README.md)** - Standardized development environment

### Quick Specification Access

```bash
# Load helper functions
source .container-use/container-use.sh

# View specifications
cu-spec                           # Show available specs
cu-new my-config apps            # Create new config with guidance
```

### Available Tasks

```bash
task: Available tasks for this project:
* branch:                    Create branch from main
* check:                     Run pre-commit hooks
* commit:                    Commit + push code into branch
* do:                        Select a task to run
* pr:                        Create pull request into main
* run-pre-commit-hook:       Run the pre-commit hook script to replace .example.com with .example.com
* xplane-push:               Push crossplane package
```
