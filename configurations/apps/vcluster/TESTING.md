# VCluster Crossplane Configuration Testing Guide

This document provides comprehensive testing instructions for the VCluster Crossplane configuration using the KCL module.

## Prerequisites

Before testing, ensure you have the following tools installed:

- **Crossplane CLI** v1.20.0+ - Download from [releases](https://github.com/crossplane/crossplane/releases)
- **Docker** (for function runtime) - Required for KCL function execution
- **kubectl** - For Kubernetes cluster interaction
- **yq** - For YAML processing

## Installation

### Crossplane CLI Installation

```bash
# Download and install crossplane CLI
curl -sL "https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh" | sh
sudo mv crossplane /usr/local/bin/

# Verify installation
crossplane version
```

### Dependencies Setup (Development)

For local development and testing without a cluster:

```bash
# Start Docker (required for KCL function runtime)
sudo systemctl start docker

# Verify Docker is running
docker ps
```

## Local Rendering Tests

### Basic Render Test

Test the complete configuration rendering:

```bash
cd configurations/apps/vcluster

# Render the claim using the composition and functions
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml
```

**Expected Output Structure:**
- Helm Release for VCluster deployment
- Object resource for secret observation
- Connection secret configuration
- Kubernetes and Helm ProviderConfigs

### Detailed Output Validation

The render output should contain these key resources:

#### 1. Helm Release Resource
```yaml
apiVersion: helm.crossplane.io/v1beta1
kind: Release
metadata:
  name: vcluster-k3s-tink1
spec:
  forProvider:
    chart:
      name: vcluster
      repository: https://charts.loft.sh
      version: "0.29.0"
    namespace: vcluster
    values:
      # VCluster configuration values...
```

#### 2. Connection Secret Object
```yaml
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: vcluster-k3s-tink1-secret-observer
spec:
  forProvider:
    manifest:
      apiVersion: v1
      kind: Secret
      metadata:
        name: vc-vcluster-k3s-tink1
        namespace: vcluster
  managementPolicies: ["Observe"]
  connectionDetails:
    - fromFieldPath: "data.config"
      name: "kubeconfig"
      type: "FromFieldPath"
```

#### 3. Kubernetes ProviderConfig
```yaml
apiVersion: pkg.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: vlcuster-k3s-tink1
spec:
  credentials:
    secretRef:
      key: kubeconfig
      name: vcluster-k3s-tink1-connection
      namespace: default
    source: Secret
```

#### 4. Helm ProviderConfig
```yaml
apiVersion: pkg.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: vlcuster-k3s-tink1-helm
spec:
  credentials:
    secretRef:
      key: kubeconfig
      name: vcluster-k3s-tink1-connection
      namespace: default
    source: Secret
```

### Advanced Testing Scenarios

#### Test Different Claim Configurations

**Production Scenario:**
```bash
# Create production claim
cat > test-production-claim.yaml <<EOF
apiVersion: apps.stuttgart-things.com/v1alpha1
kind: VCluster
metadata:
  name: prod-vcluster
  namespace: production
spec:
  name: prod-vcluster
  version: "0.29.0"
  clusterName: prod-cluster
  targetNamespace: vcluster-prod
  storageClass: fast-ssd
  nodePort: 30443
  extraSANs:
    - vcluster.prod.example.com
    - 10.0.0.100
  serverUrl: https://vcluster.prod.example.com:30443
  connectionSecret:
    enabled: true
    name: prod-vcluster-connection
    namespace: crossplane-system
  writeConnectionSecretToRef:
    name: prod-vcluster-kubeconfig
    namespace: production
EOF

# Test rendering
crossplane render test-production-claim.yaml apis/composition.yaml examples/functions.yaml
```

**Development Scenario:**
```bash
# Create development claim
cat > test-development-claim.yaml <<EOF
apiVersion: apps.stuttgart-things.com/v1alpha1
kind: VCluster
metadata:
  name: dev-vcluster
  namespace: development
spec:
  name: dev-vcluster
  version: "0.29.0"
  clusterName: dev-cluster
  targetNamespace: vcluster-dev
  storageClass: local-path
  nodePort: 31443
  values:
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
EOF

# Test rendering  
crossplane render test-development-claim.yaml apis/composition.yaml examples/functions.yaml
```

### Output Analysis

#### Resource Count Validation

Each successful render should produce exactly **4 resources**:

```bash
# Count rendered resources
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '. | length' -

# Expected output: 4
```

#### Resource Type Validation

```bash
# Extract all resource kinds
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '.[] | .kind' - | sort | uniq

# Expected kinds:
# - Object
# - ProviderConfig (2 instances: kubernetes + helm)  
# - Release
```

#### Connection Secret Validation

```bash
# Check connection secret configuration
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '.[] | select(.kind == "Object") | .spec.connectionDetails' -

# Should contain kubeconfig extraction configuration
```

## Cluster-based Testing

### Full Integration Test

After local rendering validation, test in a real cluster:

```bash
# 1. Install dependencies
kubectl apply -f examples/functions.yaml

# 2. Install XRD and Composition
kubectl apply -f apis/definition.yaml
kubectl apply -f apis/composition.yaml

# 3. Apply claim
kubectl apply -f examples/claim.yaml

# 4. Monitor deployment
kubectl get vcluster vcluster-k3s-tink1 -w
kubectl get xvcluster -w

# 5. Check generated resources
kubectl get releases
kubectl get object
kubectl get providerconfig
kubectl get secret -n default | grep connection
```

### Validation Commands

#### VCluster Status
```bash
# Check claim status
kubectl describe vcluster vcluster-k3s-tink1

# Check composite resource
kubectl describe xvcluster

# Check Helm release
kubectl get release vcluster-k3s-tink1 -o yaml
```

#### Connection Secret Verification
```bash
# Verify connection secret exists
kubectl get secret vcluster-k3s-tink1-connection -n default

# Extract and validate kubeconfig
kubectl get secret vcluster-k3s-tink1-connection -n default -o jsonpath='{.data.kubeconfig}' | base64 -d > vcluster-test.yaml

# Test VCluster access
KUBECONFIG=vcluster-test.yaml kubectl get nodes
KUBECONFIG=vcluster-test.yaml kubectl get namespaces
```

#### ProviderConfig Testing
```bash
# Test Kubernetes ProviderConfig
kubectl apply -f - <<EOF
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object  
metadata:
  name: test-vcluster-configmap
spec:
  forProvider:
    manifest:
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: crossplane-test
        namespace: default
      data:
        message: "Deployed via Crossplane to VCluster!"
  providerConfigRef:
    name: vlcuster-k3s-tink1
EOF

# Verify deployment in VCluster
KUBECONFIG=vcluster-test.yaml kubectl get configmap crossplane-test -n default
```

## Troubleshooting

### Common Issues

#### Docker Connection Issues
```bash
# Check Docker status
docker ps

# Restart Docker if needed
sudo systemctl restart docker

# Test Docker connectivity
docker run hello-world
```

#### KCL Function Issues
```bash
# Check function availability
crossplane xpkg build --help | grep kcl

# Verify function runtime
docker images | grep function-kcl
```

#### Rendering Failures
```bash
# Run with verbose output
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml --verbose

# Check individual file syntax
yq e . examples/claim.yaml
yq e . apis/composition.yaml  
yq e . examples/functions.yaml
```

#### Parameter Issues
```bash
# Debug parameter passing
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '.[] | select(.kind == "Release") | .spec.forProvider.values' -

# Should show all parameters from claim spec
```

### Validation Checklist

- [ ] All 4 resources rendered successfully
- [ ] Helm Release contains correct VCluster configuration
- [ ] Object resource has proper secret observation setup
- [ ] Kubernetes ProviderConfig points to connection secret
- [ ] Helm ProviderConfig points to connection secret  
- [ ] Connection details configured for kubeconfig extraction
- [ ] All parameters properly passed from claim to resources
- [ ] Resource names follow expected patterns
- [ ] Namespaces correctly configured

### Performance Metrics

Monitor these aspects during testing:

- **Render Time**: Should complete in under 30 seconds
- **Resource Count**: Always 4 resources for standard claim
- **Parameter Propagation**: All claim spec values present in rendered resources
- **Connection Secret**: Properly configured for kubeconfig extraction

## CI/CD Integration

For automated testing in pipelines:

```bash
#!/bin/bash
# test-crossplane-render.sh

set -e

echo "Testing VCluster Crossplane Configuration..."

# Test basic render
echo "1. Testing basic claim rendering..."
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml > /tmp/render-output.yaml

# Validate resource count
RESOURCE_COUNT=$(yq e '. | length' /tmp/render-output.yaml)
if [ "$RESOURCE_COUNT" != "4" ]; then
  echo "ERROR: Expected 4 resources, got $RESOURCE_COUNT"
  exit 1
fi

# Validate resource types
KINDS=$(yq e '.[] | .kind' /tmp/render-output.yaml | sort | uniq)
EXPECTED_KINDS="Object
ProviderConfig  
Release"

if [ "$KINDS" != "$EXPECTED_KINDS" ]; then
  echo "ERROR: Unexpected resource kinds"
  echo "Got: $KINDS"
  echo "Expected: $EXPECTED_KINDS"
  exit 1
fi

echo "✅ All render tests passed!"
```

## References

- [Crossplane CLI Documentation](https://docs.crossplane.io/latest/cli/)
- [KCL Function Reference](https://github.com/crossplane-contrib/function-kcl)
- [VCluster KCL Module](https://github.com/stuttgart-things/kcl/tree/main/xplane-vcluster)
- [Stuttgart-Things Crossplane Configurations](https://github.com/stuttgart-things/crossplane)