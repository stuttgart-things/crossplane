# TrustManager

Crossplane composition that deploys [trust-manager](https://cert-manager.io/docs/trust/trust-manager/) and creates a cluster-wide trust `Bundle` aggregating system CAs and custom CA secrets into a single ConfigMap.

## API

- **Group:** `platform.stuttgart-things.com`
- **Version:** `v1alpha1`
- **XR Kind:** `XTrustManager`
- **Scope:** `Namespaced`

### Spec Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `targetCluster.name` | string | required | Helm ClusterProviderConfig |
| `targetCluster.kubernetesRef` | string | required | Kubernetes ClusterProviderConfig |
| `install.enabled` | boolean | `true` | Deploy trust-manager Helm chart |
| `install.version` | string | `0.22.0` | Chart version |
| `install.namespace` | string | `cert-manager` | Namespace for trust-manager |
| `install.trustNamespace` | string | `cert-manager` | Namespace for trust distribution |
| `bundle.enabled` | boolean | `true` | Create a cluster trust Bundle |
| `bundle.name` | string | `cluster-trust-bundle` | Bundle resource name |
| `bundle.useDefaultCAs` | boolean | `true` | Include system default CAs |
| `bundle.secrets` | []object | `[]` | Additional CA secrets (`name`, `key`) |
| `bundle.targetConfigMapKey` | string | `trust-bundle.pem` | Key in target ConfigMap |

### Status Fields

| Field | Type | Description |
|-------|------|-------------|
| `ready` | boolean | True when install + bundle are Ready |
| `installReady` | boolean | Helm release ready |
| `bundleReady` | boolean | Bundle object ready |
| `trustManagerVersion` | string | Deployed chart version |

### Composed Resources

| Resource | Kind | Depends on |
|----------|------|-----------|
| trust-manager Helm Release | `Release` | — |
| cluster-trust-bundle | `Object` (Bundle) | Helm Release (Usage) |

## Install

```bash
kubectl apply -f apis/definition.yaml
kubectl apply -f compositions/trust-manager.yaml
```

## Example

```yaml
apiVersion: platform.stuttgart-things.com/v1alpha1
kind: XTrustManager
metadata:
  name: my-cluster-trust-manager
  namespace: crossplane-system
spec:
  targetCluster:
    name: my-cluster-helm
    kubernetesRef: my-cluster-kubernetes
  bundle:
    secrets:
      - name: cluster-ca-secret
        key: ca.crt
      - name: vault-pki-ca
        key: ca.crt
```
