# Vault Config Crossplane Configuration

This Crossplane configuration provides comprehensive Vault service deployment capabilities using the [stuttgart-things/xplane-vault-config](https://github.com/stuttgart-things/kcl/tree/main/xplane-vault-config) KCL module.

## Features

- **Secrets Store CSI Driver**: Mount secrets from external systems as Kubernetes volumes
- **Vault Secrets Operator**: Native HashiCorp Vault integration for Kubernetes secret management
- **External Secrets Operator**: Sync secrets from multiple external systems (AWS, GCP, Azure, etc.)
- **Kubernetes RBAC**: Complete ServiceAccount, Secret, and ClusterRoleBinding setup with proper permissions
- **Token Extraction**: Automatic ServiceAccount JWT token extraction to connection secrets for external authentication
- **Flexible Configuration**: Enable/disable services independently based on requirements
- **KCL Integration**: Uses OCI registry `oci://ghcr.io/stuttgart-things/xplane-vault-config` for module source
- **Namespace Management**: Automatic namespace creation for all services

## Architecture

```
VaultConfig Claim → XVaultConfig XRD → Composition (KCL Function) → Vault Services
                                              ↓
              Connection Secrets ← Token Readers ← ServiceAccount Secrets
                                              ↓
                                    Helm Releases (CSI, VSO, ESO)
                                              ↓
                                    Kubernetes Resources (SA, RBAC)
```

### Service Overview

| Service | Purpose | Optional |
|---------|---------|----------|
| **Secrets Store CSI Driver** | Mount external secrets as volumes | ✅ |
| **Vault Secrets Operator** | HashiCorp Vault native integration | ✅ |
| **External Secrets Operator** | Multi-platform secret synchronization | ✅ |
| **Kubernetes RBAC** | ServiceAccount and permission management | ✅ |

### Generated Resources

The configuration generates up to 16 Kubernetes resources depending on enabled services:
- **Namespaces**: 1-3 (automatic creation for each enabled service)
- **Helm Releases**: 1-3 (CSI/VSO/ESO based on configuration)
- **ServiceAccounts**: 1-3 (authentication for each auth configuration)
- **Secrets**: 1-3 (ServiceAccount token storage)
- **ClusterRoleBindings**: 1-3 (RBAC permissions)
- **Token Readers**: 1-3 (JWT token extraction objects)

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

### 2. Install Vault Config Configuration

```bash
# Install the configuration package
kubectl apply -f crossplane.yaml

# Apply XRD and Composition
kubectl apply -f apis/

# Verify installation
kubectl get xrd xvaultconfigs.config.stuttgart-things.com
kubectl get composition xvault-config-kcl
```

## Local Testing

Before deploying to a cluster, you can test the configuration locally using the Crossplane CLI:

```bash
# Test basic rendering
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml

# Test with different configurations
crossplane render examples/development.yaml apis/composition.yaml examples/functions.yaml
crossplane render examples/production.yaml apis/composition.yaml examples/functions.yaml
```

**Expected Output**: Each render should produce up to 16 resources based on enabled services:
- 1-3 Namespaces (automatic creation)
- 1-3 Helm Releases (CSI, VSO, ESO)
- 1-3 ServiceAccounts (per auth configuration)
- 1-3 Secrets (ServiceAccount tokens)
- 1-3 ClusterRoleBindings (RBAC permissions)
- 1-3 Token Readers (JWT extraction)

For comprehensive testing instructions, see [TESTING.md](TESTING.md).

## Usage

### 1. Deploy Vault Services via Claim

```bash
# Apply VaultConfig claim
kubectl apply -f examples/claim.yaml

# Monitor deployment
kubectl get vaultconfig vault-config-example -w

# Check created resources
kubectl get xvaultconfig
kubectl get releases
kubectl get serviceaccounts -A
kubectl get secrets -A | grep vault
```

### 2. Access ServiceAccount Tokens

```bash
# List generated connection secrets
kubectl get secrets -n crossplane-system | grep vault-config

# Extract tokens for external authentication
kubectl get secret vault-config-connection -n crossplane-system -o jsonpath='{.data.csi-token}' | base64 -d
kubectl get secret vault-config-connection -n crossplane-system -o jsonpath='{.data.vso-token}' | base64 -d
kubectl get secret vault-config-connection -n crossplane-system -o jsonpath='{.data.eso-token}' | base64 -d
```

### 3. Verify Service Deployments

```bash
# Check CSI Driver (if enabled)
kubectl get pods -n secrets-store-csi
kubectl get daemonset -n secrets-store-csi

# Check Vault Secrets Operator (if enabled)
kubectl get pods -n vault-secrets-operator
kubectl get deployment -n vault-secrets-operator

# Check External Secrets Operator (if enabled)
kubectl get pods -n external-secrets-system
kubectl get deployment -n external-secrets-system
```

## Configuration Options

### Service Control

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `csiEnabled` | boolean | `false` | Enable Secrets Store CSI Driver |
| `vsoEnabled` | boolean | `false` | Enable Vault Secrets Operator |
| `esoEnabled` | boolean | `false` | Enable External Secrets Operator |

### Chart Versions

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `csiChartVersion` | string | `"1.5.4"` | Chart version for CSI Driver |
| `vsoChartVersion` | string | `"1.0.1"` | Chart version for Vault Secrets Operator |
| `esoChartVersion` | string | `"0.20.3"` | Chart version for External Secrets Operator |

### Namespace Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `namespaceCsi` | string | `"secrets-store-csi"` | Namespace for CSI Driver |
| `namespaceVso` | string | `"vault-secrets-operator"` | Namespace for VSO |
| `namespaceEso` | string | `"external-secrets"` | Namespace for ESO |

### Authentication Setup

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `k8sAuths` | array | `[{"name": "vault-auth-default", "namespace": "default"}]` | Kubernetes auth configurations |

### Connection Secrets

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `connectionSecret.enabled` | boolean | `true` | Enable connection secret creation |
| `connectionSecret.name` | string | Generated | Connection secret name |
| `connectionSecret.namespace` | string | `"crossplane-system"` | Connection secret namespace |

## Examples

### All Services Configuration (Production)

```yaml
apiVersion: config.stuttgart-things.com/v1alpha1
kind: VaultConfig
metadata:
  name: vault-config-prod
  namespace: production
spec:
  name: vault-config-production
  clusterName: k8s-prod-cluster

  # Enable all services
  csiEnabled: true
  vsoEnabled: true
  esoEnabled: true

  # Production namespaces
  namespaceCsi: "vault-csi-system"
  namespaceVso: "vault-operator-system"
  namespaceEso: "external-secrets-system"

  # Multiple auth configurations
  k8sAuths:
    - name: "vault-auth-apps"
      namespace: "applications"
    - name: "vault-auth-platform"
      namespace: "platform-system"
    - name: "vault-auth-monitoring"
      namespace: "monitoring-system"

writeConnectionSecretToRef:
  name: vault-production-secrets
  namespace: production
```

### CSI-Only Configuration (Lightweight)

```yaml
apiVersion: config.stuttgart-things.com/v1alpha1
kind: VaultConfig
metadata:
  name: vault-config-csi
  namespace: default
spec:
  name: vault-csi-only
  clusterName: k3s-dev

  # Only CSI Driver
  csiEnabled: true
  vsoEnabled: false
  esoEnabled: false

  # Custom namespace
  namespaceCsi: "secrets-csi"

  # Single auth
  k8sAuths:
    - name: "vault-auth-csi"
      namespace: "applications"

writeConnectionSecretToRef:
  name: vault-csi-secrets
  namespace: default
```

### External Secrets Focus (Multi-Cloud)

```yaml
apiVersion: config.stuttgart-things.com/v1alpha1
kind: VaultConfig
metadata:
  name: vault-config-eso
  namespace: security
spec:
  name: vault-external-secrets
  clusterName: k8s-multi-cloud

  # Focus on External Secrets
  csiEnabled: false
  vsoEnabled: false
  esoEnabled: true

  # External secrets namespace
  namespaceEso: "external-secrets-system"

  # Multiple auth for different cloud providers
  k8sAuths:
    - name: "vault-auth-aws"
      namespace: "aws-workloads"
    - name: "vault-auth-gcp"
      namespace: "gcp-workloads"
    - name: "vault-auth-azure"
      namespace: "azure-workloads"

writeConnectionSecretToRef:
  name: vault-multicloud-secrets
  namespace: security
```

## Service Details

### Secrets Store CSI Driver

When enabled (`csiEnabled: true`), deploys:
- **Helm Release**: `secrets-store-csi-driver` chart from Kubernetes SIGs
- **DaemonSet**: CSI node driver on all nodes
- **Controller**: CSI controller for volume provisioning
- **CRDs**: SecretProviderClass custom resources

**Use Cases**:
- Mount secrets from external systems as Kubernetes volumes
- Integration with HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, GCP Secret Manager
- Secret rotation and lifecycle management

### Vault Secrets Operator

When enabled (`vsoEnabled: true`), deploys:
- **Helm Release**: `vault-secrets-operator` from HashiCorp
- **Operator**: Manages VaultAuth, VaultStaticSecret, VaultDynamicSecret resources
- **ServiceAccount**: With proper RBAC for Vault integration
- **Token Reader**: JWT token extraction for Vault authentication

**Use Cases**:
- Native HashiCorp Vault integration
- Dynamic secret generation
- Vault authentication and authorization
- Secret lifecycle management with Vault policies

### External Secrets Operator

When enabled (`esoEnabled: true`), deploys:
- **Helm Release**: `external-secrets` chart from External Secrets community
- **Operator**: Manages SecretStore and ExternalSecret resources
- **Controllers**: For multiple secret backends (AWS, GCP, Azure, Vault, etc.)
- **ServiceAccount**: With RBAC for Kubernetes secret management

**Use Cases**:
- Multi-cloud secret synchronization
- Integration with cloud provider secret services
- Centralized secret management across platforms
- Secret templating and transformation

## Troubleshooting

### Debug Commands

```bash
# Check VaultConfig claim status
kubectl get vaultconfig -o wide
kubectl describe vaultconfig VAULT_CONFIG_NAME

# Check XVaultConfig composite resource
kubectl get xvaultconfig -o wide
kubectl describe xvaultconfig

# Check generated resources
kubectl get releases -A
kubectl get serviceaccounts -A | grep vault
kubectl get secrets -A | grep vault
kubectl get clusterrolebindings | grep vault

# Check function status
kubectl get function function-kcl
kubectl logs -n crossplane-system deployment/function-kcl
```

### Local Testing Issues

```bash
# Check crossplane CLI version (should be v1.20.0+)
crossplane version

# Verify Docker is running (required for KCL function)
docker ps

# Test render with verbose output
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml --verbose

# Count generated resources
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml | yq e '. | length' -
```

### Service-Specific Issues

```bash
# CSI Driver Issues
kubectl get pods -n secrets-store-csi
kubectl logs -n secrets-store-csi -l app=secrets-store-csi-driver

# Vault Secrets Operator Issues
kubectl get pods -n vault-secrets-operator
kubectl logs -n vault-secrets-operator -l app.kubernetes.io/name=vault-secrets-operator

# External Secrets Operator Issues
kubectl get pods -n external-secrets-system
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets
```

### Token Extraction Issues

```bash
# Check if ServiceAccount exists
kubectl get serviceaccount vault-auth-CONFIGNAME -n NAMESPACE

# Check if Secret was created
kubectl get secret vault-auth-CONFIGNAME-token -n NAMESPACE

# Check Token Reader object
kubectl get object vault-token-reader-CONFIGNAME
kubectl describe object vault-token-reader-CONFIGNAME

# Verify connection secret
kubectl get secret VAULT_CONFIG_NAME-connection -n crossplane-system
kubectl describe secret VAULT_CONFIG_NAME-connection -n crossplane-system
```

## Dependencies

- **Crossplane**: `>=v1.14.0`
- **Crossplane CLI**: `>=v1.20.0` (for local testing)
- **KCL Function**: `xpkg.upbound.io/crossplane-contrib/function-kcl:>=v0.9.0`
- **Stuttgart-Things Helm Provider**: `ghcr.io/stuttgart-things/crossplane-provider-helm:>=v0.1.1`
- **Kubernetes Provider**: `xpkg.upbound.io/crossplane-contrib/provider-kubernetes:>=v0.18.0`
- **KCL Module**: `oci://ghcr.io/stuttgart-things/xplane-vault-config:0.1.0`
- **Docker**: Required for KCL function runtime during testing

## Integration Examples

### Using with Vault Authentication

```bash
# Extract ServiceAccount tokens for Vault auth
CSI_TOKEN=$(kubectl get secret vault-config-connection -n crossplane-system -o jsonpath='{.data.csi-token}' | base64 -d)
VSO_TOKEN=$(kubectl get secret vault-config-connection -n crossplane-system -o jsonpath='{.data.vso-token}' | base64 -d)

# Use tokens for Vault authentication
vault write auth/kubernetes/config \
  token_reviewer_jwt="$CSI_TOKEN" \
  kubernetes_host="https://kubernetes.default.svc.cluster.local"
```

### SecretProviderClass Example (CSI)

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-database-creds
  namespace: applications
spec:
  provider: vault
  parameters:
    vaultAddress: "https://vault.example.com:8200"
    roleName: "database-role"
    objects: |
      - objectName: "database-username"
        secretPath: "secret/database"  # pragma: allowlist secret
        secretKey: "username"  # pragma: allowlist secret
      - objectName: "database-password"
        secretPath: "secret/database"  # pragma: allowlist secret
        secretKey: "password"
  secretObjects:  # pragma: allowlist secret
    - secretName: database-credentials  # pragma: allowlist secret
      type: Opaque
      data:
        - objectName: database-username
          key: username
        - objectName: database-password
          key: password
```

### ExternalSecret Example (ESO)

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: vault-external-secret
  namespace: applications
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: vault-secret
    creationPolicy: Owner
  data:
    - secretKey: username
      remoteRef:
        key: secret/database
        property: username
    - secretKey: password
      remoteRef:
        key: secret/database
        property: password
```

## Testing

This configuration includes comprehensive testing capabilities:

- **Local Rendering**: Use `crossplane render` to test without a cluster
- **Integration Tests**: Full cluster deployment testing with all services
- **Service Validation**: Individual service deployment verification
- **Token Extraction Tests**: ServiceAccount JWT token functionality
- **Multi-Configuration Tests**: Development, staging, and production scenarios

See [TESTING.md](TESTING.md) for detailed testing instructions and troubleshooting guides.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Test your changes with `crossplane render`
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](../../../LICENSE) file for details.
