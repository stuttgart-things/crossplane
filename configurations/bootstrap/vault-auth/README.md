# Vault Kubernetes Authentication (Crossplane v2 + OpenTofu)

Crossplane v2 **namespaced** `VaultK8sAuth` configuration that creates Vault Kubernetes auth backends (plus optional `backend_config`) via the **OpenTofu** provider.

The composition is a thin wrapper around the [`xplane-vault-auth`](https://github.com/stuttgart-things/kcl/tree/main/crossplane/xplane-vault-auth) KCL module (pulled from OCI at render time by `function-kcl`).

- **XR group/kind:** `config.stuttgart-things.com/v1alpha1` / `VaultK8sAuth`
- **Scope:** Namespaced
- **Workspaces generated:** one `opentofu.m.upbound.io/v1beta1` `Workspace` per `k8sAuths` entry

## Install

```bash
# Functions + provider
kubectl apply -f examples/function.yaml
kubectl apply -f opentofu-provider.yaml
kubectl apply -f provider-config.yaml

# XRD + Composition
kubectl apply -f apis/definition.yaml
kubectl apply -f apis/composition.yaml
```

> **Function names.** The composition references `crossplane-contrib-function-kcl` and `crossplane-contrib-function-auto-ready` — the names that `examples/function.yaml` creates and that `crossplane` CLI / `kubectl crossplane install function` produce by default. If your cluster has these installed under different names (e.g. plain `function-kcl`, which some ad-hoc setups use), either rename your installed `Function` resources to match or patch `apis/composition.yaml` in place.

## Use

1. Create the Vault token Secret in the same namespace you'll use for the `VaultK8sAuth`:

   ```bash
   kubectl apply -f examples/vault-secret.yaml
   ```

   (the default Secret name is `vault`, key `terraform.tfvars`, containing `vault_token = "hvs...."`.)

2. Apply a claim:

   ```bash
   kubectl apply -f examples/claim.yaml
   ```

3. Watch the generated Workspaces reconcile:

   ```bash
   kubectl get workspaces.opentofu.m.upbound.io -A
   ```

## Spec

| Field | Required | Default | Notes |
|---|---|---|---|
| `clusterName` | ✅ | — | Prefix for Vault backend paths (`<cluster>-<authName>`). |
| `vaultAddr` | ✅ | — | Vault server URL. |
| `skipTlsVerify` | | `true` | |
| `kubernetesHost` | | `https://kubernetes.default.svc:443` | Used when any `k8sAuths` entry has `backendConfig`. |
| `vaultTokenSecret` | | `vault` | Name of the Secret (same ns) holding `vault_token`. |
| `vaultTokenSecretKey` | | `terraform.tfvars` | |
| `providerConfigName` | | `default` | OpenTofu `(Cluster)ProviderConfig` name. |
| `providerConfigKind` | | `ClusterProviderConfig` | Or `ProviderConfig`. |
| `k8sAuths[]` | ✅ | — | See below. |

### `k8sAuths[]`

| Field | Required | Default |
|---|---|---|
| `name` | ✅ | — |
| `tokenPolicies` | ✅ | — |
| `tokenTtl` | | `3600` |
| `boundServiceAccountNames` | | `["default"]` |
| `boundServiceAccountNamespaces` | | `["default"]` |
| `backendConfig` | | (unset) |

### `backendConfig`

If set, the generated Workspace additionally renders a `vault_kubernetes_auth_backend_config` resource that reads the CA cert and token reviewer JWT from a Kubernetes Secret (typically a ServiceAccount token secret). Requires the OpenTofu provider's in-cluster kube credentials to have read access to that Secret.

| Field | Required | Default |
|---|---|---|
| `secretName` | ✅ | — |
| `secretNamespace` | | XR namespace |
| `caCertKey` | | `ca.crt` |
| `tokenKey` | | `token` |
| `disableIssValidation` | | `true` |
| `disableLocalCaJwt` | | `true` |

#### `backendConfig` prerequisites

The composition's HCL uses the Terraform `kubernetes` provider's `data "kubernetes_secret"` block to read the CA cert and token reviewer JWT at `tofu apply` time. This means:

1. **The referenced Secret must already exist** in the cluster **before** the `VaultK8sAuth` XR is applied. If it's missing, `tofu plan` fails with `Attempt to index null value` (the data source returns a `null` `.data` map for non-existent Secrets rather than erroring out upfront).
2. **It must be a ServiceAccount token Secret** — since Kubernetes 1.24 these are no longer auto-created. You have to make one explicitly:
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: vault-dev
     namespace: default
     annotations:
       kubernetes.io/service-account.name: vault-auth-reviewer
   type: kubernetes.io/service-account-token
   ```
   (plus the `vault-auth-reviewer` ServiceAccount and a `system:auth-delegator` ClusterRoleBinding for the token-review call to succeed).
3. **The opentofu provider's pod SA** needs RBAC to read that Secret via the Kubernetes API (since the TF kubernetes provider uses in-cluster config).

For a minimal smoke test, leave `backendConfig` unset on every entry — the Workspace will still create the Vault auth backend and the role, and you can wire up `kubernetes_host` / `kubernetes_ca_cert` / `token_reviewer_jwt` manually in Vault afterwards.

## Upgrading from the legacy go-templating composition

This configuration replaces a previous `tf.upbound.io/v1beta1` + `function-go-templating` implementation. Breaking changes:

- Provider: `provider-terraform` → `provider-opentofu` (namespaced `opentofu.m.upbound.io/v1beta1`)
- XRD: `apiextensions.crossplane.io/v1` → `v2`, now `scope: Namespaced`
- Fields: all renamed from `snake_case` → `camelCase` (`cluster_name` → `clusterName`, `k8s_auths` → `k8sAuths`, etc.)
- Vault token Secret: previously referenced cross-namespace via `secretRef.namespace`; now must be **co-located** in the XR's namespace, and the format is plain HCL `terraform.tfvars` (was JSON).
- `namespace` field on each auth entry replaced by `boundServiceAccountNamespaces[]`.

See [`examples/claim.yaml`](examples/claim.yaml) for the new shape.
