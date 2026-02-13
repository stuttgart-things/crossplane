# Crossplane Configurations — Project Guide

## Project Overview

This repository contains Crossplane v2 configuration packages for deploying infrastructure and applications on Kubernetes. Each configuration wraps a Helm chart or Kubernetes resource behind a declarative Crossplane API.

## Repository Structure

```
configurations/
  apps/          # Application deployments (github-controller, github-runner, ...)
  config/        # Cluster configuration
  infra/         # Infrastructure (network-integration, ...)
  k8s/           # Kubernetes resources
  terraform/     # Terraform-backed resources
docs/            # Backstage-compatible mkdocs documentation
catalog-info.yaml  # Backstage component registration
mkdocs.yml         # TechDocs configuration
```

## Configuration Module Layout (v2)

Every configuration follows this structure:

```
<name>/
  apis/definition.yaml              # XRD (apiextensions.crossplane.io/v2)
  compositions/<name>.yaml           # Composition with function-go-templating
  examples/<name>.yaml               # Example XR (uses XR kind, NOT claim kind)
  examples/functions.yaml            # Function declarations for crossplane render
  examples/provider-config.yaml      # Example ProviderConfig
  examples/configuration.yaml        # Package install manifest
  crossplane.yaml                    # Package metadata (crossplane version >=2.13.0)
  README.md                          # Must include render command
```

## Key Conventions

### XRD (definition.yaml)
- apiVersion: `apiextensions.crossplane.io/v2`
- Always include: `defaultCompositeDeletePolicy: Foreground`, `scope: Namespaced`
- Always include `targetCluster` field with `name` and `scope` (Namespaced/Cluster)
- Always include `status` schema (at minimum `installed: boolean`)
- Group: `resources.stuttgart-things.com`
- No `connectionSecretKeys` unless actually exporting secrets

### Composition
- Located in `compositions/` directory (NOT `apis/`)
- Uses `function-go-templating` (NOT `function-patch-and-transform`)
- Helm API group: `helm.m.crossplane.io/v1beta1` (NOT `helm.crossplane.io/v1beta1`)
- Use `setResourceNameAnnotation` for resource naming
- Always end with `function-auto-ready` step
- Always include status resource at end of Go template

### Function Names (must match between composition and functions.yaml)
- Go templating: `function-go-templating`
- Auto ready: `crossplane-contrib-function-auto-ready`

### crossplane.yaml
- `spec.crossplane.version: ">=2.13.0"`
- Only declare providers actually used (typically just provider-helm)

### Examples
- Example XR files MUST use the XR kind (e.g. `XGithubController`), not the claim kind
- This is required for `crossplane render` to work

## targetCluster Pattern

Every composition supports multi-cluster via:
```yaml
spec:
  targetCluster:
    name: in-cluster        # ProviderConfig name
    scope: Namespaced       # Namespaced → ProviderConfig, Cluster → ClusterProviderConfig
```

Go template scope selection:
```gotemplate
{{- $scope := $spec.targetCluster.scope | default "Namespaced" -}}
{{- $pcKind := "ProviderConfig" -}}
{{- if eq $scope "Cluster" -}}
{{- $pcKind = "ClusterProviderConfig" -}}
{{- end -}}
```

## Validation

Always validate with crossplane render:
```bash
crossplane render examples/<name>.yaml \
  compositions/<name>.yaml \
  examples/functions.yaml \
  --include-function-results
```

## Reference Module

Use `configurations/infra/network-integration/` as the canonical v2 example when creating new configurations.

## Function Versions (current)
- `function-go-templating`: v0.11.3
- `function-auto-ready`: v0.6.0
