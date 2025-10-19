#!/bin/bash
# Container-Use Configuration for Stuttgart-Things Crossplane Development
# Usage: source this file to set up container-use environment

# Environment configuration
export CONTAINER_USE_CONFIG="/workdir/.container-use/container-use.yaml"
export CROSSPLANE_DEV_ENV="crossplane-development"

# Quick setup commands
setup_crossplane_dev() {
    echo "🚀 Setting up Crossplane development environment..."

    # Create environment from config
    container-use create --config .container-use/container-use.yaml --title "Crossplane Development"

    echo "✅ Environment created successfully!"
    echo ""
    echo "📋 Quick commands:"
    echo "  container-use checkout $CROSSPLANE_DEV_ENV  # Access the environment"
    echo "  container-use log $CROSSPLANE_DEV_ENV       # View environment logs"
    echo ""
    echo "🛠️  Available tools in environment:"
    echo "  - Crossplane CLI (render, build, push)"
    echo "  - kubectl (Kubernetes CLI)"
    echo "  - Helm (Package manager)"
    echo "  - yq (YAML processor)"
    echo "  - KCL (Configuration language)"
    echo "  - Docker (For function runtime)"
    echo ""
    echo "🧪 Test commands:"
    echo "  test-vcluster      # Test VCluster configuration"
    echo "  test-ansible-run   # Test Ansible-Run configuration"
}

# Test specific configurations
test_vcluster() {
    echo "🧪 Testing VCluster configuration..."
    container-use exec $CROSSPLANE_DEV_ENV "cd configurations/apps/vcluster && crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml"
}

test_ansible_run() {
    echo "🧪 Testing Ansible-Run configuration..."
    container-use exec $CROSSPLANE_DEV_ENV "cd configurations/ansible-run && crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml"
}

test_all_configs() {
    echo "🧪 Testing all configurations..."

    # Find all configuration directories
    configs=$(find configurations -name "composition.yaml" -type f | sed 's|/apis/composition.yaml||' | sort)

    for config in $configs; do
        echo "Testing: $config"
        if [ -f "$config/examples/claim.yaml" ] && [ -f "$config/examples/functions.yaml" ]; then
            container-use exec $CROSSPLANE_DEV_ENV "cd $config && crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml"
        else
            echo "⚠️  Missing required files in $config"
        fi
        echo "---"
    done
}

# Build crossplane packages
build_package() {
    local package_path="$1"
    if [ -z "$package_path" ]; then
        echo "❌ Usage: build_package <package-path>"
        echo "   Example: build_package configurations/apps/vcluster"
        return 1
    fi

    echo "🏗️  Building package: $package_path"
    container-use exec $CROSSPLANE_DEV_ENV "crossplane xpkg build --package-root=$package_path --examples-root=$package_path/examples"
}

# Specification and documentation helpers
show_spec() {
    echo "📋 Available specifications:"
    echo ""
    echo "📖 Development Specification:"
    echo "   less .container-use/specs/crossplane-configuration-development.md"
    echo ""
    echo "📝 Configuration Template:"
    echo "   less .container-use/specs/configuration-template.md"
    echo ""
    echo "📚 Specifications Index:"
    echo "   less .container-use/specs/README.md"
}

new_config() {
    local config_name="$1"
    local category="$2"

    if [ -z "$config_name" ] || [ -z "$category" ]; then
        echo "❌ Usage: new_config <config-name> <category>"
        echo "   Categories: apps, infra, platform"
        echo "   Example: new_config my-app apps"
        return 1
    fi

    echo "🚀 Creating new configuration: $config_name in category: $category"
    echo ""
    echo "📋 Follow the development specification:"
    echo "   less .container-use/specs/crossplane-configuration-development.md"
    echo ""
    echo "📝 Use the configuration template:"
    echo "   less .container-use/specs/configuration-template.md"
    echo ""
    echo "🏗️  Directory structure:"
    echo "   mkdir -p configurations/$category/$config_name/{apis,examples}"
    echo "   cd configurations/$category/$config_name"
}

# Development shortcuts
alias cu-setup="setup_crossplane_dev"
alias cu-test-vcluster="test_vcluster"
alias cu-test-ansible="test_ansible_run"
alias cu-test-all="test_all_configs"
alias cu-build="build_package"
alias cu-spec="show_spec"
alias cu-new="new_config"

# Help function
crossplane_dev_help() {
    cat << 'EOF'
🚀 Stuttgart-Things Crossplane Development Helper

SETUP:
  cu-setup                    # Create development environment
  source container-use.sh     # Load this helper script

TESTING:
  cu-test-vcluster           # Test VCluster configuration
  cu-test-ansible            # Test Ansible-Run configuration
  cu-test-all                # Test all configurations

BUILDING:
  cu-build <config-path>     # Build crossplane package

SPECIFICATIONS:
  cu-spec                    # Show available specifications
  cu-new <name> <category>   # Create new configuration with guidance

ENVIRONMENT:
  container-use checkout crossplane-development  # Access environment
  container-use log crossplane-development       # View logs
  container-use diff crossplane-development      # View changes

MANUAL COMMANDS (inside environment):
  xp-render examples/claim.yaml apis/composition.yaml examples/functions.yaml
  xp-build --package-root=configurations/apps/vcluster
  k apply -f examples/claim.yaml
  test-vcluster
  test-ansible-run

CONFIGURATION FILES:
  .container-use/container-use.yaml         # Main environment configuration
  .container-use/container-use.sh           # This helper script (source it)
  .container-use/specs/                     # Development specifications and templates

EOF
}

# Show help by default
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    crossplane_dev_help
fi