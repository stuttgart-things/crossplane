# VCluster Crossplane Configuration

This Crossplane configuration provides VCluster deployment capabilities using the [stuttgart-things/xplane-vcluster](https://github.com/stuttgart-things/kcl/tree/main/xplane-vcluster) KCL module.

## Features

- **Production-Ready VCluster**: Deploys VCluster with persistence, NodePort service, and custom SANs
- **Connection Secret Management**: Automatic kubeconfig extraction via Crossplane connection secrets
- **ProviderConfig Generation**: Creates ready-to-use Kubernetes and Helm ProviderConfigs
- **KCL Integration**: Uses OCI registry `oci://ghcr.io/stuttgart-things/xplane-vcluster` for module source
- **Flexible Configuration**: Customizable storage classes, ports, networking, and additional secrets

## Architecture

```
VCluster Claim → XVCluster XRD → Composition (KCL Function) → VCluster Resources
                                         ↓
    Connection Secret ← Object (Observe) ← VCluster Secret ← VCluster Pod
                                         ↓
                              ProviderConfigs (K8s + Helm)
```

1. **VCluster Claim** creates **XVCluster** composite resource
2. **Composition** uses **KCL Function** with `oci://ghcr.io/stuttgart-things/xplane-vcluster` module
3. **KCL Module** generates:
   - Helm Release for VCluster deployment
   - Object to observe VCluster secret (management policy: Observe)
   - Connection secret extraction
   - Kubernetes and Helm ProviderConfigs

## Installation

### Prerequisites

- **Crossplane**: `>=v1.14.0` installed in your Kubernetes cluster
- **Crossplane CLI**: v1.20.0+ for local testing - [Installation Guide](https://docs.crossplane.io/latest/cli/)
- **Docker**: Required for KCL function runtime during testing
- **kubectl**: Kubernetes command-line tool

### 1. Install Dependencies

```bash
# Install KCL Function
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: function-kcl
spec:
  package: xpkg.upbound.io/crossplane-contrib/function-kcl:v0.9.0
EOF

# Install Helm Provider (Stuttgart-Things)
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-helm
spec:
  package: ghcr.io/stuttgart-things/crossplane-provider-helm:0.1.1
EOF

# Install Kubernetes Provider
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-kubernetes:v0.18.0
EOF
```

### 2. Install VCluster Configuration

```bash
# Install the configuration
kubectl apply -f crossplane.yaml

# Apply XRD and Composition
kubectl apply -f apis/
```

## Usage

### 1. Deploy VCluster via Claim

```bash
# Apply VCluster claim
kubectl apply -f examples/claim.yaml

# Monitor deployment
kubectl get vcluster vcluster-k3s-tink1 -w

# Check created resources
kubectl get xvcluster
kubectl get releases
kubectl get object
kubectl get providerconfig
```

### 2. Access VCluster

```bash
# Extract kubeconfig from connection secret
kubectl get secret vcluster-k3s-tink1-connection -n default -o jsonpath='{.data.kubeconfig}' | base64 -d > vcluster-kubeconfig.yaml

# Test VCluster connectivity
KUBECONFIG=vcluster-kubeconfig.yaml kubectl get nodes
KUBECONFIG=vcluster-kubeconfig.yaml kubectl cluster-info

# Create test resources
KUBECONFIG=vcluster-kubeconfig.yaml kubectl create namespace test
KUBECONFIG=vcluster-kubeconfig.yaml kubectl run test-pod --image=nginx:alpine -n test
```

### 3. Use Generated ProviderConfigs

Deploy resources to VCluster using the generated ProviderConfigs:

```yaml
# Kubernetes resource in VCluster
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: vcluster-configmap
spec:
  forProvider:
    manifest:
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: test-configmap
        namespace: default
      data:
        message: "Hello from VCluster via Crossplane!"
  providerConfigRef:
    name: vlcuster-k3s-tink1  # Generated ProviderConfig
```

```yaml
# Helm release in VCluster
apiVersion: helm.crossplane.io/v1beta1
kind: Release
metadata:
  name: nginx-in-vcluster
spec:
  forProvider:
    chart:
      name: nginx
      repository: https://charts.bitnami.com/bitnami
      version: "15.14.2"
    namespace: default
  providerConfigRef:
    name: vlcuster-k3s-tink1-helm  # Generated Helm ProviderConfig
```

## Configuration Options

### Basic Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | string | **required** | VCluster release name |
| `version` | string | `"0.29.0"` | VCluster chart version |
| `clusterName` | string | `"kind"` | Crossplane provider config reference |
| `targetNamespace` | string | `"vcluster"` | Target namespace for deployment |

### VCluster Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `storageClass` | string | `"standard"` | Storage class for persistence |
| `bindAddress` | string | `"0.0.0.0"` | Proxy bind address |
| `proxyPort` | integer | `8443` | Internal proxy port |
| `nodePort` | integer | `32443` | External NodePort |
| `extraSANs` | array | `["localhost"]` | Additional Subject Alternative Names |
| `serverUrl` | string | `"https://localhost:32443"` | External server URL for kubeconfig |

### Connection Secret Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `connectionSecret.enabled` | boolean | `true` | Enable connection secret creation |
| `connectionSecret.name` | string | `"{name}-connection"` | Connection secret name |
| `connectionSecret.namespace` | string | `"crossplane-system"` | Connection secret namespace |
| `connectionSecret.vclusterSecretName` | string | `"vc-{name}"` | VCluster secret name to observe |
| `connectionSecret.vclusterSecretNamespace` | string | `targetNamespace` | VCluster secret namespace |

### Additional Secrets

Configure additional kubeconfig secrets with custom contexts:

```yaml
additionalSecrets:
  - name: vc-vlcuster-k3s-tink1-crossplane
    namespace: vcluster-k3s-tink2
    context: vcluster-crossplane-context
    server: https://10.31.103.23:32445
```

## Examples

### Production VCluster with External Access

```yaml
apiVersion: apps.stuttgart-things.com/v1alpha1
kind: VCluster
metadata:
  name: prod-vcluster
  namespace: production
spec:
  name: prod-vcluster
  version: "0.29.0"
  clusterName: prod-k8s-cluster
  targetNamespace: vcluster-prod
  storageClass: fast-ssd
  nodePort: 30443
  extraSANs:
    - vcluster.prod.example.com
    - 10.0.0.100
    - localhost
  serverUrl: https://vcluster.prod.example.com:30443
  connectionSecret:
    enabled: true
    name: prod-vcluster-connection
    namespace: crossplane-system
  writeConnectionSecretToRef:
    name: prod-vcluster-kubeconfig
    namespace: production
```

### Development VCluster with Custom Values

```yaml
apiVersion: apps.stuttgart-things.com/v1alpha1
kind: VCluster
metadata:
  name: dev-vcluster
  namespace: development
spec:
  name: dev-vcluster
  version: "0.29.0"
  clusterName: dev-k8s-cluster
  targetNamespace: vcluster-dev
  storageClass: local-path
  nodePort: 31443
  values:
    # Custom Helm values
    controlPlane:
      coredns:
        enabled: true
      distro:
        k8s:
          enabled: true
          version: "1.29"
    networking:
      replicateService:
        services:
          - fromNamespace: kube-system
    telemetry:
      disabled: true
  writeConnectionSecretToRef:
    name: dev-vcluster-kubeconfig
    namespace: development
```

## Troubleshooting

### Check Resource Status

```bash
# Check VCluster claim
kubectl get vcluster -o wide

# Check XVCluster composite resource
kubectl get xvcluster -o wide

# Check generated resources
kubectl get releases
kubectl get object
kubectl get secret -n crossplane-system | grep connection
kubectl get providerconfig
```

### Debug KCL Function

```bash
# Check function status
kubectl get function function-kcl

# Check function logs
kubectl logs -n crossplane-system deployment/function-kcl

# Check composition events
kubectl describe composition xvcluster-kcl
```

### Test Connection Secret

```bash
# Verify connection secret exists
kubectl get secret VCLUSTER_NAME-connection -n default

# Test kubeconfig extraction
kubectl get secret VCLUSTER_NAME-connection -n default -o jsonpath='{.data.kubeconfig}' | base64 -d | head -10

# Test VCluster connectivity
kubectl get secret VCLUSTER_NAME-connection -n default -o jsonpath='{.data.kubeconfig}' | base64 -d > test-kubeconfig.yaml
KUBECONFIG=test-kubeconfig.yaml kubectl get nodes
```

## Dependencies

- **Crossplane**: `>=v1.14.0`
- **KCL Function**: `xpkg.upbound.io/crossplane-contrib/function-kcl:>=v0.9.0`
- **Stuttgart-Things Helm Provider**: `ghcr.io/stuttgart-things/crossplane-provider-helm:>=v0.1.1`
- **Kubernetes Provider**: `xpkg.upbound.io/crossplane-contrib/provider-kubernetes:>=v0.18.0`
- **KCL Module**: `oci://ghcr.io/stuttgart-things/xplane-vcluster`

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](../../LICENSE) file for details.
