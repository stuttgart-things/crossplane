# Common Patterns

## Connection Secret Management

When resources need credentials or kubeconfig access:

```yaml
# In XRD
spec:
  versions:
    - name: v1alpha1
      schema:
        openAPIV3Schema:
          properties:
            spec:
              properties:
                writeConnectionSecretToRef:
                  type: object
                  properties:
                    name:
                      type: string
                    namespace:
                      type: string
```

## ProviderConfig Generation

Create provider configs from connection secrets:

```kcl
# In KCL module
{
    apiVersion: "kubernetes.crossplane.io/v1alpha1"
    kind: "ProviderConfig"
    metadata.name: "${name}-provider"
    spec.credentials = {
        source: "Secret"
        secretRef = {
            name: connectionSecretName
            namespace: connectionSecretNamespace
            key: "kubeconfig"
        }
    }
}
```

## Multi-Step Pipelines

For complex compositions, chain multiple KCL functions:

```yaml
pipeline:
  - functionRef:
      name: function-kcl
    input:
      apiVersion: krm.kcl.dev/v1alpha1
      kind: KCLRun
      spec:
        source: oci://ghcr.io/stuttgart-things/xplane-{resource}-core
    step: create-core-resources

  - functionRef:
      name: function-kcl
    input:
      apiVersion: krm.kcl.dev/v1alpha1
      kind: KCLRun
      spec:
        source: oci://ghcr.io/stuttgart-things/xplane-{resource}-networking
    step: configure-networking
```
