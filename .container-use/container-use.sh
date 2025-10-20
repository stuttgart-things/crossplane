#!/bin/bash
# Stuttgart-Things Crossplane Development - Container-Use Configuration
# Aligned with unified organizational standards
# Usage: source this file to set up container-use environment

# Environment configuration
export CONTAINER_USE_CONFIG="/workdir/.container-use/container-use.yaml"
export CROSSPLANE_DEV_ENV="crossplane-development"
export STUTTGART_THINGS_REGISTRY="ghcr.io/stuttgart-things"

# Quick setup commands aligned with unified standards
cu-setup() {
    echo "🚀 Setting up Stuttgart-Things Crossplane development environment..."
    echo "📋 Aligned with unified organizational standards"

    # Create environment from unified config
    container-use create --config .container-use/container-use.yaml --title "Stuttgart-Things Crossplane Development"

    echo "✅ Environment created successfully!"
    echo ""
    echo "📋 Unified Stuttgart-Things commands:"
    echo "  container-use checkout $CROSSPLANE_DEV_ENV  # Access the environment"
    echo "  container-use log $CROSSPLANE_DEV_ENV       # View environment logs"
    echo ""
    echo "🛠️  Available tools (unified standards):"
    echo "  - Crossplane CLI (render, build, push)"
    echo "  - kubectl (Kubernetes CLI)"
    echo "  - Helm (Package manager)"
    echo "  - yq (YAML processor)"
    echo "  - KCL (Configuration language)"
    echo "  - Docker (For function runtime)"
    echo ""
    echo "📚 Stuttgart-Things Standards:"
    echo "  show-decisions         # View organizational decisions"
    echo "  show-tasks            # View development task workflow"
    echo "  show-standards        # View code standards and conventions"
    echo ""
    echo "🧪 Unified test commands:"
    echo "  cu-test-vault-config  # Test Vault Config configuration"
    echo "  cu-test-vcluster      # Test VCluster configuration"
    echo "  cu-test-ansible-run   # Test Ansible-Run configuration"
    echo "  cu-test-all          # Test all configurations"
}

# Test specific configurations using unified command pattern
cu-test-vault-config() {
    echo "🧪 Testing Vault Config configuration (Stuttgart-Things unified standards)..."
    container-use exec $CROSSPLANE_DEV_ENV "cd configurations/config/vault-config && crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml"
}

cu-test-vcluster() {
    echo "🧪 Testing VCluster configuration..."
    container-use exec $CROSSPLANE_DEV_ENV "cd configurations/apps/vcluster && crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml"
}

cu-test-ansible-run() {
    echo "🧪 Testing Ansible-Run configuration..."
    container-use exec $CROSSPLANE_DEV_ENV "cd configurations/apps/ansible-run && crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml"
}

cu-test-all() {
    echo "🧪 Testing all configurations (Stuttgart-Things unified pattern)..."

    # Find all configuration directories following unified structure
    configs=$(find configurations -name "composition.yaml" -type f | sed 's|/apis/composition.yaml||' | sort)

    for config in $configs; do
        echo "Testing: $config"
        if [ -f "$config/examples/claim.yaml" ] && [ -f "$config/examples/functions.yaml" ]; then
            container-use exec $CROSSPLANE_DEV_ENV "cd $config && crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml"
        else
            echo "⚠️  Missing required files in $config (check unified standards)"
        fi
        echo "---"
    done
}

# Build crossplane packages following unified standards
cu-build() {
    local package_path="$1"
    if [ -z "$package_path" ]; then
        echo "❌ Usage: cu-build <package-path>"
        echo "   Example: cu-build configurations/config/vault-config"
        echo "   Follows Stuttgart-Things unified directory structure:"
        echo "   configurations/{category}/{name}/"
        return 1
    fi

    echo "🏗️  Building package: $package_path (Stuttgart-Things standards)"
    container-use exec $CROSSPLANE_DEV_ENV "crossplane xpkg build --package-root=$package_path --examples-root=$package_path/examples"
}

# Stuttgart-Things unified standards helpers
show-decisions() {
    echo "📋 Stuttgart-Things Development Decisions (Unified Standards):"
    container-use exec $CROSSPLANE_DEV_ENV "less .container-use/decisions-unified.md"
}

show-tasks() {
    echo "� Stuttgart-Things Development Tasks (Unified Workflow):"
    container-use exec $CROSSPLANE_DEV_ENV "less .container-use/tasks-unified.md"
}

show-standards() {
    echo "� Stuttgart-Things Code Standards (Unified Framework):"
    container-use exec $CROSSPLANE_DEV_ENV "less .container-use/standards.md"
}

# Create new configuration following unified standards
cu-new() {
    local config_name="$1"
    local category="$2"

    if [ -z "$config_name" ] || [ -z "$category" ]; then
        echo "❌ Usage: cu-new <config-name> <category>"
        echo "   Categories (Stuttgart-Things unified): apps, config, infra, k8s, terraform"
        echo "   Example: cu-new vault-config config"
        echo "   Follows unified directory structure and standards"
        return 1
    fi

    echo "🚀 Creating new configuration: $config_name in category: $category"
    echo "📋 Following Stuttgart-Things unified standards"
    echo ""
    echo "📚 Review unified standards first:"
    echo "   show-decisions    # Organizational decisions"
    echo "   show-tasks       # Development workflow"
    echo "   show-standards   # Code standards and conventions"
    echo ""
    echo "🏗️  Unified directory structure:"
    echo "   mkdir -p configurations/$category/$config_name/{apis,examples}"
    echo "   cd configurations/$category/$config_name"
    echo ""
    echo "📝 Required files (unified standards):"
    echo "   apis/definition.yaml          # XRD with {category}.stuttgart-things.com API group"
    echo "   apis/composition.yaml         # KCL function using oci://$STUTTGART_THINGS_REGISTRY/xplane-{name}"
    echo "   examples/claim.yaml           # Basic example"
    echo "   examples/development.yaml     # Development scenario"
    echo "   examples/production.yaml      # Production scenario"
    echo "   examples/functions.yaml       # Function configuration"
    echo "   crossplane.yaml              # Package configuration"
    echo "   README.md                    # Documentation following unified template"
}

# Help function aligned with unified standards
crossplane_dev_help() {
    cat << 'EOF'
🚀 Stuttgart-Things Crossplane Development (Unified Standards v1.0.0)

SETUP (Unified Framework):
  cu-setup                    # Create development environment
  source container-use.sh     # Load unified helper script

TESTING (Unified Command Pattern):
  cu-test-vault-config       # Test Vault Config configuration
  cu-test-vcluster           # Test VCluster configuration
  cu-test-ansible-run        # Test Ansible-Run configuration
  cu-test-all                # Test all configurations

BUILDING (Unified Standards):
  cu-build <config-path>     # Build crossplane package

STANDARDS & DOCUMENTATION (Unified Framework):
  show-decisions             # View organizational decisions
  show-tasks                # View development task workflow
  show-standards            # View code standards and conventions
  cu-new <name> <category>   # Create new configuration with unified guidance

ENVIRONMENT ACCESS:
  container-use checkout crossplane-development  # Access environment
  container-use log crossplane-development       # View logs and work output

UNIFIED COMMAND SHORTCUTS (inside environment):
  cu-test-vault-config      # Quick vault config test
  cu-test-vcluster          # Quick vcluster test
  cu-test-all              # Test all configurations
  show-decisions           # View organizational decisions
  show-tasks              # View development workflow
  show-standards          # View code standards

UNIFIED STRUCTURE:
  .container-use/
  ├── decisions-unified.md     # Organizational decisions (unified)
  ├── tasks-unified.md         # Development workflow (unified)
  ├── standards.md             # Code standards (unified)
  ├── container-use.yaml       # Environment config (unified)
  └── container-use.sh         # This helper script (unified)

REGISTRY & STANDARDS:
  Registry: ghcr.io/stuttgart-things/*
  API Groups: {category}.stuttgart-things.com
  KCL Modules: oci://ghcr.io/stuttgart-things/xplane-{name}
  Documentation: Unified README template
  Testing: Multi-scenario validation (basic, dev, prod)

EOF
}
