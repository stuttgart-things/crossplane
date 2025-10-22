# Vault Kubernetes Authentication Configuration

This Crossplane configuration manages Vault Kubernetes authentication backends using Terraform.

## Security Model

This configuration uses **Secret-based credential management** for enhanced security:

- ✅ **Vault tokens stored in Kubernetes Secrets** (not in claims)
- ✅ **No sensitive data in Git repositories**
- ✅ **Proper secret rotation support**
- ✅ **Namespace-scoped credential access**

## Quick Start

### 1. Create Vault Credentials Secret

Create a Kubernetes secret containing your Vault token:

```bash
kubectl create secret generic vault-credentials \
  --from-literal='terraform.tfvars.json={"vault_token":"hvs.YOUR-ACTUAL-VAULT-TOKEN"}' \
  --namespace default
```

Or apply the example (with your real token):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: vault-credentials
  namespace: default
type: Opaque
stringData:
  terraform.tfvars.json: |
    {
      "vault_token": "hvs.YOUR-ACTUAL-VAULT-TOKEN"
    }
```

### 2. Apply the Configuration

```bash
# Apply XRD and Composition
kubectl apply -f apis/definition.yaml
kubectl apply -f apis/composition.yaml

# Apply your claim
kubectl apply -f examples/claim.yaml
```

### 3. Monitor the Workspace

```bash
# Check the workspace status
kubectl get workspace.tf.upbound.io

# Check the claim status
kubectl get vaultk8sauth
```

## Configuration Structure

### Claim Example

```yaml
apiVersion: config.stuttgart-things.com/v1alpha1
kind: VaultK8sAuth
metadata:
  name: vault-auth-claim
spec:
  compositionRef:
    name: vault-auth-composition
  cluster_name: "my-cluster"
  vault_addr: "https://vault.example.com:8200"
  # Optional: specify custom ProviderConfig (defaults to "default")
  providerConfigRef: "custom-terraform-config"
  skip_tls_verify: false
  k8s_auths:
    - name: dev
      namespace: default
      token_policies: ["read-policy", "write-policy"]  # pragma: allowlist secret
      token_ttl: 3600  # pragma: allowlist secret
    - name: prod
      namespace: production
      token_policies: ["prod-policy"]  # pragma: allowlist secret
      token_ttl: 1800  # pragma: allowlist secret
```

### Secret Format

The Vault credentials must be provided as JSON in the secret:

```json
{
  "vault_token": "hvs.your-actual-vault-token"
}
```

## Security Features

### 🔐 **Secret Management**
- Vault tokens stored in Kubernetes Secrets
- No hardcoded credentials in Git
- Namespace-scoped access control
- Support for secret rotation

### 🛡️ **State Management**
- Terraform state stored in Kubernetes backend
- State isolation per workspace
- Crossplane managed lifecycle

### 🔄 **GitOps Ready**
- All configuration in Git (except secrets)
- Declarative resource management
- Version controlled compositions

## Terraform Resources Created

For each auth backend in `k8s_auths`, the composition creates:

1. **vault_auth_backend** - Kubernetes auth method
2. **vault_kubernetes_auth_backend_config** - Connection configuration
3. **vault_kubernetes_auth_backend_role** - Service account roles

## Troubleshooting

### Check Workspace Status
```bash
kubectl describe workspace.tf.upbound.io <workspace-name>
```

### Check Secret Exists
```bash
kubectl get secret vault-credentials -o yaml
```

### Validate Terraform Execution
```bash
kubectl logs -l app.kubernetes.io/name=provider-terraform
```

### Common Issues

1. **Secret not found**: Ensure `vault-credentials` secret exists in the correct namespace
2. **Invalid token**: Verify the Vault token has sufficient permissions  # pragma: allowlist secret
3. **TLS errors**: Set `skip_tls_verify: true` for self-signed certificates

## Advanced Configuration

### Custom ProviderConfig

You can specify a custom Terraform ProviderConfig for different environments:

```yaml
apiVersion: config.stuttgart-things.com/v1alpha1
kind: VaultK8sAuth
metadata:
  name: vault-auth-production
spec:
  cluster_name: "prod-cluster"
  vault_addr: "https://vault-prod.example.com:8200"
  providerConfigRef: "production-terraform-config"  # Custom ProviderConfig
  k8s_auths: [...]
```

Create a custom ProviderConfig with different state backend or configuration:

```yaml
apiVersion: tf.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: production-terraform-config
spec:
  configuration: |
    terraform {
      backend "kubernetes" {
        secret_suffix    = "providerconfig-production"
        namespace        = "terraform-system"
        in_cluster_config = true
      }
    }
```

### Custom Secret Name/Namespace

You can customize the secret reference in the composition:

```yaml
varFiles:
  - source: SecretKey
    secretKeyRef:
      namespace: vault-system
      name: custom-vault-creds
      key: terraform.tfvars.json
    format: JSON
```

### Multiple Vault Environments

Create separate secrets for different environments:

```bash
# Development
kubectl create secret generic vault-dev-credentials \
  --from-literal='terraform.tfvars.json={"vault_token":"hvs.dev-token"}' \
  --namespace default

# Production
kubectl create secret generic vault-prod-credentials \
  --from-literal='terraform.tfvars.json={"vault_token":"hvs.prod-token"}' \
  --namespace production
```

## Testing

Test the configuration rendering:

```bash
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml --include-function-results
```

---

**Security Note**: Never commit actual Vault tokens to Git. Always use Kubernetes Secrets for credential management.