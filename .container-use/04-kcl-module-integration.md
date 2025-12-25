# KCL Module Integration

## OCI Registry Pattern

All KCL modules are published to `ghcr.io/stuttgart-things`:

```
oci://ghcr.io/stuttgart-things/xplane-{resource}:{version}
```

## Version Management

- **KCL Module Version**: Semantic versioning (e.g., `0.29.1`)
- **Configuration Version**: Tracks module version
- **Breaking Changes**: Bump major version

## Module Structure

```kcl
# main.k - Stuttgart-Things KCL module pattern
schema Config:
    """Configuration schema for resource composition"""
    name: str
    # ... additional fields

# Transform function
transform = lambda c: Config -> []:
    """Transforms Config into Kubernetes resources"""
    [
        {
            apiVersion: "v1"
            kind: "Resource"
            metadata.name: c.name
            # ... resource spec
        }
        # ... additional resources
    ]

# Expose Items for Crossplane
Items = transform(Config {
    # Map from observed composite resource spec
    name = option("params").oxr.spec.name
    # ... map additional fields
})
```
