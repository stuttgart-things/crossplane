# Container-Use Configuration

This directory contains the Container-Use configuration for the Stuttgart-Things Crossplane repository.

## Quick Start

```bash
# From repository root
source .container-use/container-use.sh
cu-setup
```

## Files

- **`container-use.yaml`** - Main environment configuration
- **`container-use.sh`** - Helper script with development shortcuts
- **`README.md`** - This overview
- **`README-container-use.md`** - Detailed documentation
- **`specs/`** - Development specifications and templates

## Usage

```bash
# Setup development environment
source .container-use/container-use.sh && cu-setup

# Access environment
container-use checkout crossplane-development

# Test configurations
cu-test-vcluster      # Test VCluster
cu-test-ansible       # Test Ansible-Run
cu-test-all           # Test all configurations
```

## Development Specifications

This directory includes comprehensive development specifications:

- **[Development Specification](specs/crossplane-configuration-development.md)** - Complete workflow for Crossplane configurations
- **[Configuration Template](specs/configuration-template.md)** - Standardized template for new configurations
- **[Specifications Index](specs/README.md)** - Overview of all specifications

## Documentation

See [README-container-use.md](README-container-use.md) for detailed documentation.