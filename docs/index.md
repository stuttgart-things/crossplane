# Stuttgart Things Crossplane Configurations

This repository contains Crossplane configuration packages for deploying infrastructure and applications.

## Structure

```
configurations/
  apps/          # Application deployments (ARC, runners, ...)
  config/        # Cluster configuration
  infra/         # Infrastructure (networking, storage, ...)
  k8s/           # Kubernetes resources
  terraform/     # Terraform-backed resources
```

Each configuration follows the Crossplane v2 package layout:

```
<configuration>/
  apis/
    definition.yaml          # XRD (CompositeResourceDefinition)
  compositions/
    <name>.yaml              # Composition with go-templating pipeline
  examples/
    <name>.yaml              # Example XR for crossplane render
    functions.yaml           # Function declarations
    provider-config.yaml     # Example ProviderConfig
    configuration.yaml       # Package install manifest
  crossplane.yaml            # Package metadata and dependencies
```

## Guides

- [Migrating v1 configurations to v2](guides/migration-v1-to-v2.md) — Step-by-step migration from Crossplane v1 to v2 format
- [Creating new Helm v2 configurations](guides/new-helm-v2-configuration.md) — Build a new configuration from scratch

## Reference

- [Core Concepts](reference/core-concepts.md) — Architecture, composition pattern, folder structure
- [Component Specifications](reference/component-specifications.md) — XRD, Composition, and package format details
- [Common Patterns](reference/common-patterns.md) — targetCluster, secrets, Helm values, conditionals
- [Best Practices](reference/best-practices.md) — API design, template guidelines, naming conventions
- [Combined Configurations](reference/combined-configurations.md) — Composition-of-compositions pattern
- [Testing Strategy](reference/testing-strategy.md) — Local render and cluster testing
- [Troubleshooting](reference/troubleshooting.md) — Common errors and debug commands
