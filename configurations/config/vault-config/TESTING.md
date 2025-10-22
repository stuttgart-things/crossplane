# Vault Config Configuration Testing Guide

This document provides comprehensive testing procedures for the Vault Config Crossplane configuration.

## Prerequisites

### Required Tools

- **Crossplane CLI**: v1.20.0+ - [Installation Guide](https://docs.crossplane.io/latest/cli/)
- **Docker**: Required for KCL function runtime
- **kubectl**: Kubernetes command-line tool
- **yq**: YAML processor for validation

```bash
# Verify tool versions
crossplane version  # Should be ≥v1.20.0
docker --version    # Should be running
kubectl version     # Should be ≥v1.31.0
yq --version        # Any recent version
```

### Environment Setup

```bash
# Ensure Docker is running (required for KCL function)
docker ps

# Verify current directory
pwd  # Should be in configurations/config/vault-config/
```

## Local Testing (No Cluster Required)

### Basic Rendering Tests

#### 1. Test All Services Enabled

```bash
# Test comprehensive configuration
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml

# Expected: 16 resources generated
# - 3 Namespaces
# - 3 Helm Releases (CSI, VSO, ESO)
# - 3 ServiceAccounts
# - 3 Secrets
# - 3 ClusterRoleBindings
# - 1 Token Reader for each auth config (variable)
```

#### 2. Test Development Configuration

```bash
# Test CSI + ESO only
crossplane render examples/development.yaml apis/composition.yaml examples/functions.yaml

# Expected: ~11 resources generated
# - 2 Namespaces (CSI, ESO)
# - 2 Helm Releases (CSI, ESO)
# - ServiceAccounts and RBAC for development auth
```

#### 3. Test Production Configuration

```bash
# Test production setup with multiple auth configs
crossplane render examples/production.yaml apis/composition.yaml examples/functions.yaml

# Expected: 16 resources + additional auth resources
# - All services enabled
# - Multiple K8s auth configurations
# - Production-grade namespaces
```

### Validation Tests

#### Resource Count Validation

```bash
# Count generated resources for each configuration
echo "=== All Services Test ==="
RESOURCE_COUNT=$(crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '. | length' -)
echo "Generated resources: $RESOURCE_COUNT (Expected: 16)"

echo "=== Development Test ==="
DEV_COUNT=$(crossplane render examples/development.yaml apis/composition.yaml examples/functions.yaml | yq e '. | length' -)
echo "Generated resources: $DEV_COUNT (Expected: ~11)"

echo "=== Production Test ==="
PROD_COUNT=$(crossplane render examples/production.yaml apis/composition.yaml examples/functions.yaml | yq e '. | length' -)
echo "Generated resources: $PROD_COUNT (Expected: 16+)"
```

#### Resource Type Validation

```bash
# Verify specific resource types are generated
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | \
yq e '.[] | select(.kind == "Release") | .metadata.name' -

# Expected output:
# secrets-store-csi-driver-vault-config-test
# vault-secrets-operator-vault-config-test
# external-secrets-operator-vault-config-test
```

#### Namespace Validation

```bash
# Check namespace generation
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | \
yq e '.[] | select(.kind == "Namespace") | .metadata.name' -

# Expected output:
# secrets-store-csi
# vault-secrets-operator
# external-secrets-system
```

#### ServiceAccount Validation

```bash
# Check ServiceAccount generation
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | \
yq e '.[] | select(.kind == "ServiceAccount") | .metadata.name' -

# Expected output based on k8sAuths configuration
```

### Performance Testing

```bash
# Measure render time
time crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml > /dev/null

# Should complete in under 10 seconds
```

### Syntax Validation

```bash
# Validate all YAML files
echo "=== Validating Claim Files ==="
yq e . examples/claim.yaml
yq e . examples/development.yaml
yq e . examples/production.yaml

echo "=== Validating API Files ==="
yq e . apis/composition.yaml
yq e . apis/definition.yaml

echo "=== Validating Functions ==="
yq e . examples/functions.yaml

echo "=== Validating Package ==="
yq e . crossplane.yaml
```

## Integration Testing (Cluster Required)

### 1. Prerequisites Setup

```bash
# Install required providers and functions
kubectl apply -f examples/functions.yaml

# Wait for providers to be healthy
kubectl wait --for=condition=Healthy provider/provider-helm --timeout=300s
kubectl wait --for=condition=Healthy provider/provider-kubernetes --timeout=300s
kubectl wait --for=condition=Healthy function/function-kcl --timeout=300s
```

### 2. Install Configuration

```bash
# Install the configuration package
kubectl apply -f crossplane.yaml

# Install XRD and Composition
kubectl apply -f apis/

# Verify installation
kubectl get xrd xvaultconfigs.config.stuttgart-things.com
kubectl get composition xvault-config-kcl

# Wait for resources to be established
kubectl wait --for=condition=Established xrd/xvaultconfigs.config.stuttgart-things.com --timeout=60s
```

### 3. Deploy Test Claims

#### Basic Deployment Test

```bash
# Deploy basic configuration
kubectl apply -f examples/claim.yaml

# Monitor deployment
kubectl get xvaultconfig vault-config-example -w

# Check status
kubectl describe xvaultconfig vault-config-example
```

#### Development Deployment Test

```bash
# Deploy development configuration
kubectl apply -f examples/development.yaml

# Monitor deployment
kubectl get vaultconfig vault-config-dev -n development -w

# Check resources in development namespace
kubectl get all -n development
```

#### Production Deployment Test

```bash
# Deploy production configuration
kubectl apply -f examples/production.yaml

# Monitor deployment
kubectl get vaultconfig vault-config-prod -n production -w

# Check resources in production namespace
kubectl get all -n production
```

### 4. Resource Verification

#### Helm Releases

```bash
# Check Helm releases are created
kubectl get releases -A

# Verify release status
kubectl describe release secrets-store-csi-driver-vault-config-test
kubectl describe release vault-secrets-operator-vault-config-test
kubectl describe release external-secrets-operator-vault-config-test
```

#### Service Deployments

```bash
# Check CSI Driver deployment
kubectl get pods -n secrets-store-csi
kubectl get daemonset -n secrets-store-csi

# Check VSO deployment
kubectl get pods -n vault-secrets-operator
kubectl get deployment -n vault-secrets-operator

# Check ESO deployment
kubectl get pods -n external-secrets-system
kubectl get deployment -n external-secrets-system
```

#### RBAC Resources

```bash
# Check ServiceAccounts
kubectl get serviceaccounts -A | grep vault-auth

# Check Secrets (ServiceAccount tokens)
kubectl get secrets -A | grep vault-auth

# Check ClusterRoleBindings
kubectl get clusterrolebindings | grep vault-auth
```

#### Connection Secrets

```bash
# Check connection secrets are created
kubectl get secrets -n crossplane-system | grep vault-config

# Verify secret content (should have token keys)
kubectl describe secret vault-config-connection -n crossplane-system

# Test token extraction
kubectl get secret vault-config-connection -n crossplane-system -o jsonpath='{.data.csi-token}' | base64 -d | head -10
kubectl get secret vault-config-connection -n crossplane-system -o jsonpath='{.data.vso-token}' | base64 -d | head -10
```

### 5. Service Functionality Tests

#### CSI Driver Test

```bash
# Create test SecretProviderClass (requires actual Vault setup)
cat <<EOF | kubectl apply -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-test-spc
  namespace: default
spec:
  provider: vault
  parameters:
    vaultAddress: "http://vault.vault.svc.cluster.local:8200"
    roleName: "test-role"
    objects: |
      - objectName: "test-secret"  # pragma: allowlist secret
        secretPath: "secret/test"  # pragma: allowlist secret
        secretKey: "value"
EOF

# Check if SPC is created successfully
kubectl get secretproviderclass vault-test-spc
```

#### VSO Test

```bash
# Check if VSO CRDs are available
kubectl get crd | grep vault

# Test VaultAuth resource creation (requires Vault setup)
kubectl get vaultauth -A
kubectl get vaultstaticsecret -A
```

#### ESO Test

```bash
# Check ESO CRDs are available
kubectl get crd | grep external-secrets

# Test SecretStore creation
kubectl get secretstore -A
kubectl get externalsecret -A
```

## Automated Testing

### Test Script

Create a comprehensive test script:

```bash
#!/bin/bash
# test-vault-config.sh

set -e

echo "🧪 Starting Vault Config Configuration Tests"

# Local render tests
echo "📋 Running local render tests..."

echo "  ✓ Testing all services configuration"
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml > /dev/null
echo "  ✓ All services render: PASS"

echo "  ✓ Testing development configuration"
crossplane render examples/development.yaml apis/composition.yaml examples/functions.yaml > /dev/null
echo "  ✓ Development render: PASS"

echo "  ✓ Testing production configuration"
crossplane render examples/production.yaml apis/composition.yaml examples/functions.yaml > /dev/null
echo "  ✓ Production render: PASS"

# Resource count validation
echo "📊 Validating resource counts..."

ALL_COUNT=$(crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '. | length' -)
if [ "$ALL_COUNT" -eq 16 ]; then
    echo "  ✓ All services resource count: PASS ($ALL_COUNT resources)"
else
    echo "  ❌ All services resource count: FAIL (Expected 16, got $ALL_COUNT)"
    exit 1
fi

DEV_COUNT=$(crossplane render examples/development.yaml apis/composition.yaml examples/functions.yaml | yq e '. | length' -)
if [ "$DEV_COUNT" -ge 10 ] && [ "$DEV_COUNT" -le 12 ]; then
    echo "  ✓ Development resource count: PASS ($DEV_COUNT resources)"
else
    echo "  ❌ Development resource count: FAIL (Expected 10-12, got $DEV_COUNT)"
    exit 1
fi

# Syntax validation
echo "📝 Validating syntax..."

yq e . examples/claim.yaml > /dev/null && echo "  ✓ Claim YAML: PASS"
yq e . examples/development.yaml > /dev/null && echo "  ✓ Development YAML: PASS"
yq e . examples/production.yaml > /dev/null && echo "  ✓ Production YAML: PASS"
yq e . apis/composition.yaml > /dev/null && echo "  ✓ Composition YAML: PASS"
yq e . apis/definition.yaml > /dev/null && echo "  ✓ Definition YAML: PASS"
yq e . examples/functions.yaml > /dev/null && echo "  ✓ Functions YAML: PASS"
yq e . crossplane.yaml > /dev/null && echo "  ✓ Package YAML: PASS"

# Resource type validation
echo "🔍 Validating resource types..."

HELM_RELEASES=$(crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '.[] | select(.kind == "Release") | .metadata.name' - | wc -l)
if [ "$HELM_RELEASES" -eq 3 ]; then
    echo "  ✓ Helm releases count: PASS ($HELM_RELEASES releases)"
else
    echo "  ❌ Helm releases count: FAIL (Expected 3, got $HELM_RELEASES)"
    exit 1
fi

NAMESPACES=$(crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '.[] | select(.kind == "Namespace") | .metadata.name' - | wc -l)
if [ "$NAMESPACES" -eq 3 ]; then
    echo "  ✓ Namespaces count: PASS ($NAMESPACES namespaces)"
else
    echo "  ❌ Namespaces count: FAIL (Expected 3, got $NAMESPACES)"
    exit 1
fi

echo "🎉 All tests passed successfully!"
```

### Container-Use Integration

Add to `.container-use/container-use.sh`:

```bash
# Vault Config testing function
test_vault_config() {
    echo "🧪 Testing Vault Config configuration..."
    container-use exec $CROSSPLANE_DEV_ENV "cd configurations/config/vault-config && bash test-vault-config.sh"
}

# Add alias
alias cu-test-vault-config="test_vault_config"
```

## Troubleshooting

### Common Issues

#### 1. Render Failures

```bash
# Check Docker is running
docker ps

# Verify KCL module availability
kcl mod list

# Test with verbose output
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml --verbose
```

#### 2. Resource Count Mismatches

```bash
# Debug specific configuration
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '.[] | {kind: .kind, name: .metadata.name}' -

# Check enabled services in claim
yq e '.spec | {csiEnabled, vsoEnabled, esoEnabled}' examples/claim.yaml
```

#### 3. Parameter Mapping Issues

```bash
# Verify composition parameter structure
yq e '.spec.pipeline[0].input.params' apis/composition.yaml

# Check XRD schema matches claim
yq e '.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties | keys' apis/definition.yaml
```

#### 4. Function Issues

```bash
# Check function status in cluster
kubectl get function function-kcl
kubectl describe function function-kcl

# Check function logs
kubectl logs -n crossplane-system deployment/function-kcl
```

### Debug Commands

```bash
# Generate resources with debug info
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml --verbose 2>&1 | tee debug-output.log

# Analyze specific resource types
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '.[] | select(.kind == "KIND_NAME")' -

# Check annotations
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '.[] | .metadata.annotations' -

# Verify resource naming
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '.[] | .metadata.name' -
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Test Vault Config Configuration

on:
  push:
    paths:
      - 'configurations/config/vault-config/**'
  pull_request:
    paths:
      - 'configurations/config/vault-config/**'

jobs:
  test-vault-config:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Crossplane CLI
        run: |
          curl -sL https://cli.crossplane.io/stable/v1.20.0/bin/linux_amd64/crank -o crossplane
          chmod +x crossplane
          sudo mv crossplane /usr/local/bin/

      - name: Install yq
        run: |
          sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
          sudo chmod +x /usr/local/bin/yq

      - name: Test Vault Config Configuration
        run: |
          cd configurations/config/vault-config
          bash test-vault-config.sh
```

## Performance Benchmarks

### Expected Performance

- **Local Render Time**: < 10 seconds per configuration
- **Resource Generation**: 16 resources for full configuration
- **Memory Usage**: < 100MB during rendering
- **Package Size**: < 10MB

### Benchmark Script

```bash
#!/bin/bash
# benchmark-vault-config.sh

echo "📊 Vault Config Performance Benchmarks"

# Render time benchmark
echo "⏱️  Measuring render times..."

for config in claim development production; do
    echo "  Testing $config configuration..."
    TIME=$( { time crossplane render examples/$config.yaml apis/composition.yaml examples/functions.yaml > /dev/null; } 2>&1 | grep real | awk '{print $2}' )
    echo "    Render time: $TIME"
done

# Resource count benchmark
echo "📈 Resource generation metrics..."

for config in claim development production; do
    COUNT=$(crossplane render examples/$config.yaml apis/composition.yaml examples/functions.yaml | yq e '. | length' -)
    echo "  $config: $COUNT resources"
done

echo "✅ Benchmarking complete"
```

This comprehensive testing guide ensures the Vault Config configuration works correctly across all scenarios and provides debugging tools for troubleshooting issues.
