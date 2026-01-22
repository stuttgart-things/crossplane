# Harbor Project

Crossplane composition for managing Harbor projects using OpenTofu/Terraform.

## Prerequisites

- Crossplane installed
- `function-go-templating` and `function-auto-ready` functions installed

### Install OpenTofu Provider

```bash
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1beta1
kind: DeploymentRuntimeConfig
metadata:
  name: opentofu
spec:
  deploymentTemplate:
    spec:
      selector: {}
      template:
        spec:
          containers:
            - name: package-runtime
              args:
                - -d
                - --poll=5m
                - --max-reconcile-rate=10
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-opentofu
spec:
  package: xpkg.upbound.io/upbound/provider-opentofu:v1.0.3
  runtimeConfigRef:
    name: opentofu
EOF
```

### Configure ClusterProviderConfig

```bash
kubectl apply -f - <<EOF
apiVersion: opentofu.m.upbound.io/v1beta1
kind: ClusterProviderConfig
metadata:
  name: default
spec:
  configuration: |
    terraform {
      backend "kubernetes" {
        secret_suffix     = "providerconfig-default"
        namespace         = "crossplane-system"
        in_cluster_config = true
      }
    }
EOF
```

Or apply the example files:

```bash
kubectl apply -f examples/deployment-runtime-config.yaml
kubectl apply -f examples/provider.yaml
kubectl apply -f examples/cluster-provider-config.yaml
```

## Usage

### 1. Create the credentials secret

Create a Kubernetes secret containing Harbor credentials:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: harbor-credentials
  namespace: crossplane-system
type: Opaque
stringData:
  credentials.tfvars: |
    harbor_username = "admin"
    harbor_password = "your-password-here"
EOF
```

Or apply the example secret (update the password first):

```bash
kubectl apply -f examples/secret.yaml
```

### 2. Apply the XRD and Composition

```bash
kubectl apply -f apis/
```

### 3. Create a HarborProject claim

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: HarborProject
metadata:
  name: demo-project
  namespace: default
spec:
  harborURL: https://harbor.example.com
  projectName: my-project
  storageQuota: -1  # -1 = unlimited
  providerConfigRef: default
  credentialsSecretRef:
    name: harbor-credentials
    namespace: crossplane-system
```

```bash
kubectl apply -f examples/claim.yaml
```

## Configuration

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `harborURL` | string | yes | - | Harbor base URL |
| `projectName` | string | yes | - | Name of the Harbor project to create |
| `harborInsecure` | boolean | no | false | Allow insecure TLS connections |
| `storageQuota` | number | no | -1 | Storage quota in bytes (-1 = unlimited) |
| `providerConfigRef` | string | no | default | ProviderConfig for OpenTofu |
| `credentialsSecretRef.name` | string | yes | - | Name of the secret containing credentials |
| `credentialsSecretRef.namespace` | string | yes | - | Namespace of the secret |

## Credentials Secret Format

The secret must contain a `credentials.tfvars` key with HCL-formatted variables:

```hcl
harbor_username = "admin"
harbor_password = "your-password"
```

## Debugging

Render the composition locally:

```bash
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml --include-function-results
```

Trace the resource:

```bash
crossplane beta trace harborproject demo-project -n default
```
