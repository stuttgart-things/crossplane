# Core Concepts & Architecture

## Core Principles

1. **Declarative Infrastructure** — Resources defined through Kubernetes custom resources
2. **Composition Pattern** — XRD + Composition + Functions = managed resource
3. **Go Templating** — Use `function-go-templating` for inline resource rendering
4. **Testability** — Local validation with `crossplane render` before cluster deployment
5. **Multi-Cluster** — `targetCluster` pattern with scope-aware ProviderConfig selection

## Composition Pattern

```
                   ┌──────────────────┐
                   │   Claim (CR)     │
                   │  (namespaced)    │
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │   XR (Composite) │
                   │  (cluster-scoped)│
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │   Composition    │
                   │   (Pipeline)     │
                   └────────┬─────────┘
                            │
               ┌────────────┼────────────┐
               ▼            ▼            ▼
        ┌────────────┐ ┌──────────┐ ┌──────────┐
        │ go-template│ │  ...     │ │auto-ready│
        │ (step 1)   │ │ (step N) │ │ (final)  │
        └────────────┘ └──────────┘ └──────────┘
               │
               ▼
        ┌────────────┐
        │  Managed   │
        │  Resources │
        │ (Helm, K8s)│
        └────────────┘
```

A **Claim** is the user-facing namespaced resource. Crossplane creates a cluster-scoped **Composite Resource (XR)** which the **Composition** transforms through a pipeline of functions into **Managed Resources**.

## Standard Folder Structure

Every Crossplane v2 configuration follows this layout:

```
<configuration>/
├── apis/
│   └── definition.yaml           # XRD (CompositeResourceDefinition)
├── compositions/
│   └── <name>.yaml               # Composition with go-templating pipeline
├── examples/
│   ├── <name>.yaml               # Example XR for crossplane render
│   ├── functions.yaml            # Function declarations for testing
│   ├── provider-config.yaml      # Example ProviderConfig
│   └── configuration.yaml        # Package install manifest
├── crossplane.yaml               # Package metadata and dependencies
└── README.md                     # Module documentation with render command
```

## Key Components

| Component | Purpose | File |
|---|---|---|
| **XRD** | Defines the API schema (spec + status) | `apis/definition.yaml` |
| **Composition** | Renders managed resources via go-templating | `compositions/<name>.yaml` |
| **crossplane.yaml** | Package metadata and provider dependencies | `crossplane.yaml` |
| **Functions** | Pipeline functions (go-templating, auto-ready) | `examples/functions.yaml` |

## Pipeline Functions

| Function | Purpose |
|---|---|
| `function-go-templating` | Renders Kubernetes resources from inline Go templates |
| `function-auto-ready` | Automatically detects when composed resources are ready |

## targetCluster Pattern

Every composition supports multi-cluster deployment through the `targetCluster` field:

```yaml
spec:
  targetCluster:
    name: in-cluster           # ProviderConfig name
    scope: Namespaced          # Namespaced or Cluster
```

The composition translates `scope` into the correct ProviderConfig kind:

- `Namespaced` → `ProviderConfig`
- `Cluster` → `ClusterProviderConfig`
