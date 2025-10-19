# Container-Use Configuration for Crossplane Development

This directory contains Container-Use configuration files for standardized Crossplane development environments.

## Files

- **`container-use.yaml`** - Main environment configuration defining the development container
- **`container-use.sh`** - Helper script with shortcuts and testing commands
- **`README-container-use.md`** - This documentation

## Quick Start

### 1. Setup Environment

```bash
# Load helper functions (from repository root)
source .container-use/container-use.sh

# Create development environment
cu-setup
```

### 2. Access Environment

```bash
# Access the environment
container-use checkout crossplane-development

# View environment logs
container-use log crossplane-development
```

### 3. Test Configurations

```bash
# Test individual configurations
cu-test-vcluster      # Test VCluster configuration
cu-test-ansible       # Test Ansible-Run configuration

# Test all configurations
cu-test-all
```

## Environment Features

### 🛠️ Installed Tools

| Tool | Version | Purpose |
|------|---------|---------|
| **Crossplane CLI** | v1.20.0 | Configuration rendering and package building |
| **kubectl** | v1.31.0 | Kubernetes cluster interaction |
| **Helm** | v3.16.0 | Package management |
| **yq** | v4.44.3 | YAML processing |
| **KCL** | v0.11.3 | Configuration language |
| **Docker CE** | latest | Function runtime support |

### 🎯 Available Commands (inside environment)

```bash
# Crossplane shortcuts
xp                    # crossplane
xp-render             # crossplane render
xp-build              # crossplane xpkg build
xp-push               # crossplane xpkg push

# kubectl shortcuts
k                     # kubectl
kg                    # kubectl get
kd                    # kubectl describe
ka                    # kubectl apply

# Testing shortcuts
test-vcluster         # Test VCluster configuration
test-ansible-run      # Test Ansible-Run configuration
```

### 📁 Directory Structure

```
/workdir/
├── configurations/           # Crossplane configurations
│   ├── apps/                # Application configurations
│   │   ├── vcluster/        # VCluster configuration
│   │   └── ansible-run/     # Ansible-Run configuration
│   └── infra/               # Infrastructure configurations
├── tests/                   # Test files and examples
├── .kube/                   # Kubernetes configuration
└── tmp/                     # Temporary files
```

## Development Workflow

### Testing Configuration Changes

```bash
# 1. Access environment
container-use checkout crossplane-development

# 2. Navigate to configuration
cd configurations/apps/vcluster

# 3. Test local rendering
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml

# 4. Validate output
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '. | length' -
# Should output: 4 (for VCluster configuration)
```

### Building Packages

```bash
# Inside environment
cd configurations/apps/vcluster
crossplane xpkg build --package-root=. --examples-root=examples

# Or using helper (outside environment)
cu-build configurations/apps/vcluster
```

### Testing Multiple Configurations

```bash
# Test all configurations at once
cu-test-all

# Test specific configuration
cu-test-vcluster
cu-test-ansible
```

## Configuration Details

### Base Image
- **Ubuntu 24.04** - Stable LTS base with full package support

### Environment Variables
```bash
DEBIAN_FRONTEND=noninteractive
KUBECONFIG=/workdir/.kube/config
CROSSPLANE_CLI_VERSION=v1.20.0
KUBECTL_VERSION=v1.31.0
HELM_VERSION=v3.16.0
YQ_VERSION=v4.44.3
KCL_VERSION=v0.11.3
```

### Resource Limits
```yaml
limits:
  memory: 4Gi
  cpu: 2 cores
requests:
  memory: 2Gi
  cpu: 1 core
```

### Services
- **Docker-in-Docker**: For Crossplane KCL function runtime

### Health Checks
Automatic validation of:
- Crossplane CLI installation
- kubectl functionality
- Helm availability
- yq YAML processor
- KCL configuration language
- Docker runtime

## Troubleshooting

### Common Issues

#### Docker Connection Problems
```bash
# Check Docker status inside environment
docker ps

# Restart Docker service if needed
sudo service docker start
```

#### Crossplane Function Runtime Issues
```bash
# Verify function runtime
crossplane render --help

# Check Docker connectivity for functions
docker run hello-world
```

#### Missing Tools
```bash
# Check installed versions
crossplane version
kubectl version --client
helm version
yq --version
kcl version
```

### Debug Commands

```bash
# Environment status
container-use list

# Environment logs
container-use log crossplane-development

# Environment differences
container-use diff crossplane-development

# Access environment shell
container-use checkout crossplane-development
```

## Customization

### Adding New Tools

Edit `container-use.yaml` and add to `setupCommands`:

```yaml
setupCommands:
  # ... existing commands ...
  - "curl -L https://example.com/tool | bash"
  - "mv tool /usr/local/bin/"
```

### Adding New Aliases

Edit the `files` section in `container-use.yaml`:

```yaml
files:
  - path: "/workdir/.bashrc_custom"
    content: |
      # ... existing aliases ...
      alias my-command='some-long-command'
```

### Environment-Specific Configuration

Create configuration variants:

```bash
# Copy and modify for different use cases
cp container-use.yaml container-use-minimal.yaml
cp container-use.yaml container-use-extended.yaml
```

## Integration with CI/CD

### GitHub Actions Example

```yaml
- name: Setup Crossplane Environment
  run: |
    source .container-use/container-use.sh
    cu-setup
    cu-test-all
```

### Local Testing Script

```bash
#!/bin/bash
# test-crossplane.sh

source .container-use/container-use.sh

echo "🚀 Setting up test environment..."
cu-setup

echo "🧪 Running tests..."
cu-test-all

echo "✅ Tests completed!"
```

## Best Practices

1. **Always test locally** before pushing configuration changes
2. **Use helper commands** for consistent testing across team members
3. **Version lock tool versions** in environment configuration
4. **Document custom configurations** in this README
5. **Test all configurations** after tool updates
6. **Use resource limits** to prevent environment resource exhaustion

## Support

For issues with Container-Use configuration:

1. Check environment logs: `container-use log crossplane-development`
2. Verify tool versions match configuration
3. Test individual components with health checks
4. Review Docker connectivity for function runtime
5. Consult Container-Use documentation for environment management

## Contributing

To update the environment configuration:

1. Modify `container-use.yaml`
2. Test with `cu-setup`
3. Validate all configurations with `cu-test-all`
4. Update this README if needed
5. Commit changes and create PR