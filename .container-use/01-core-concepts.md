# Core Concepts & Architecture

## Core Principles

1. **Declarative Infrastructure**: Resources defined through Kubernetes custom resources
2. **Composition Pattern**: XRD + Composition + Functions = Resource Agent
3. **KCL Integration**: Use KCL functions for complex transformations via OCI modules
4. **Testability**: Local validation with `crossplane render` before cluster deployment
5. **Reusability**: OCI-based KCL modules shared across configurations

## Standard Folder Structure

Every Crossplane configuration module MUST follow this structure:

```
configuration-{name}/
├── apis/
│   ├── composition.yaml      # Composition with pipeline functions
│   └── definition.yaml        # XRD with claim types
├── crossplane.yaml            # Configuration package metadata
├── examples/
│   ├── claim.yaml            # Example XR/Claim instance
│   └── functions.yaml        # Function dependencies for testing
└── README.md                 # Module documentation
```

**3 directories, 6 files** - no more, no less for basic configurations.
