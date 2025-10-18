# VCluster Crossplane Configuration Testing

This guide provides comprehensive testing instructions for the VCluster Crossplane configuration using the Crossplane CLI.

## Prerequisites

### Install Crossplane CLI

```bash
# Install Crossplane CLI
curl -sL "https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh" | sh
sudo mv crossplane /usr/local/bin/

# Verify installation
crossplane version
```

### Install Docker (Required for Function Rendering)

The `crossplane render` command requires Docker to run function containers locally:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker

# Verify Docker
docker --version
```

## Testing with Crossplane Render

### 1. Basic Render Test

```bash
# Navigate to configuration directory
cd configurations/apps/vcluster

# Test render with minimal XR
crossplane render examples/render-test.yaml apis/composition.yaml examples/functions.yaml
```

### 2. Development Environment Test

```bash
# Render development VCluster (convert claim to XR first)
# Convert claim to XR for rendering
cat examples/development-claim.yaml | sed 's/kind: VCluster/kind: XVCluster/' > examples/development-xr.yaml

# Render development configuration
crossplane render examples/development-xr.yaml apis/composition.yaml examples/functions.yaml
```

### 3. Production Environment Test

```bash
# Convert production claim to XR
cat examples/production-claim.yaml | sed 's/kind: VCluster/kind: XVCluster/' > examples/production-xr.yaml

# Render production configuration
crossplane render examples/production-xr.yaml apis/composition.yaml examples/functions.yaml
```

### 4. Complete Resource Validation

```bash
# Render and validate all generated resources
crossplane render examples/xr.yaml apis/composition.yaml examples/functions.yaml > rendered-resources.yaml

# Check generated resources
kubectl --dry-run=client apply -f rendered-resources.yaml
```

## Expected Output

When successfully rendered, you should see resources similar to:

```yaml
---
apiVersion: helm.crossplane.io/v1beta1
kind: Release
metadata:
  name: vlcuster-k3s-tink1
spec:
  deletionPolicy: Delete
  forProvider:
    chart:
      name: vcluster
      repository: https://charts.loft.sh
      version: '0.29.0'
    namespace: vcluster-k3s-tink2
    values:
      # VCluster configuration values
  managementPolicies: ["*"]
  providerConfigRef:
    name: k3s-tink1

---
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: vcluster-kubeconfig-reader
spec:
  deletionPolicy: Delete
  managementPolicies: ["Observe"]
  providerConfigRef:
    name: k3s-tink1
  forProvider:
    manifest:
      apiVersion: v1
      kind: Secret
      metadata:
        name: vc-vlcuster-k3s-tink1
        namespace: vcluster-k3s-tink2
  connectionDetails:
    - apiVersion: v1
      kind: Secret
      name: vc-vlcuster-k3s-tink1
      namespace: vcluster-k3s-tink2
      fieldPath: data.config
      toConnectionSecretKey: kubeconfig
  writeConnectionSecretToRef:
    name: vcluster-k3s-tink2-connection
    namespace: crossplane-system

---
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: vlcuster-k3s-tink1
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: vcluster-k3s-tink2-connection
      key: kubeconfig

---
apiVersion: helm.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: vlcuster-k3s-tink1-helm
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: vcluster-k3s-tink2-connection
      key: kubeconfig
```

## Troubleshooting

### Docker Issues

```bash
# Check Docker daemon
systemctl status docker

# Start Docker if not running
sudo systemctl start docker

# Test Docker access
docker run hello-world
```

### Function Issues

```bash
# Check available functions
crossplane xpkg list functions

# Pull function manually if needed
docker pull xpkg.upbound.io/crossplane-contrib/function-kcl:v0.9.0

# Check function logs during render (in another terminal)
docker logs -f $(docker ps --filter ancestor=xpkg.upbound.io/crossplane-contrib/function-kcl:v0.9.0 -q)
```

### YAML Validation Issues

```bash
# Validate individual files
yq eval '.' apis/definition.yaml
yq eval '.' apis/composition.yaml
yq eval '.' examples/xr.yaml
yq eval '.' examples/functions.yaml

# Check for YAML syntax errors
yamllint apis/ examples/
```

### KCL Module Issues

```bash
# Test KCL module accessibility
kcl mod download oci://ghcr.io/stuttgart-things/xplane-vcluster

# Test local KCL rendering (if you have the module locally)
kcl run oci://ghcr.io/stuttgart-things/xplane-vcluster -D params='{
  "oxr": {
    "spec": {
      "name": "test-vcluster",
      "version": "0.29.0",
      "clusterName": "test",
      "targetNamespace": "vcluster-test"
    }
  }
}'
```

## File Structure for Testing

```
configurations/apps/vcluster/
├── apis/
│   ├── definition.yaml         # XRD
│   └── composition.yaml        # Working KCL composition
├── examples/
│   ├── functions.yaml          # Required functions
│   ├── claim.yaml              # Basic claim example
│   ├── development-claim.yaml  # Development environment
│   ├── production-claim.yaml   # Production environment
│   └── xr.yaml                 # XR for rendering
├── crossplane.yaml             # Package configuration
├── README.md                   # Main documentation
├── TESTING.md                  # This testing guide
└── test-render.sh              # Automated test script
```

## Common Render Commands

```bash
# Basic test
crossplane render examples/render-test.yaml apis/composition.yaml examples/functions.yaml

# With output to file
crossplane render examples/xr.yaml apis/composition.yaml examples/functions.yaml > output.yaml

# With verbose logging
crossplane render examples/xr.yaml apis/composition.yaml examples/functions.yaml --verbose

# Test claim (convert to XR first)
sed 's/kind: VCluster/kind: XVCluster/' examples/claim.yaml | crossplane render - apis/composition.yaml examples/functions.yaml
```

## Integration Testing

### With Real Cluster

```bash
# Apply functions first
kubectl apply -f examples/functions.yaml

# Apply XRD and Composition
kubectl apply -f apis/

# Test with claim
kubectl apply -f examples/development-claim.yaml

# Monitor resources
kubectl get vcluster,xvcluster,releases,object,providerconfig -A
```

### Monitor Deployment

```bash
# Watch VCluster claim
kubectl get vcluster dev-vcluster -n development -w

# Check generated XR
kubectl get xvcluster -o wide

# Verify Helm release
kubectl get releases -A

# Check connection secret
kubectl get secret -n crossplane-system | grep connection

# Test kubeconfig extraction
kubectl get secret dev-vcluster-kubeconfig -n development -o jsonpath='{.data.kubeconfig}' | base64 -d > dev-kubeconfig.yaml
KUBECONFIG=dev-kubeconfig.yaml kubectl get nodes
```

This comprehensive testing approach ensures your VCluster Crossplane configuration works correctly in all scenarios.