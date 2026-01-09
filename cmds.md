# COMMANDS/TROUBLESHOOTING

<details><summary><b>HELM RELEASES</b></summary>

```bash
kubectl get releases.helm.m.crossplane.io -A
kubectl get releases.helm.crossplane.io -A
```

</details>

<details><summary><b>DEBUG CROSSPLANE PROVIDER</b></summary>

```bash
# Get provider pods in crossplane-system
kubectl get pods -n crossplane-system

# Check installed providers
kubectl get providers

# Find provider service accounts
kubectl get sa -n crossplane-system | grep provider

# Check provider revision pods
kubectl get pods -n crossplane-system -l pkg.crossplane.io/revision

# Get all service accounts with their pods
kubectl get pods -n crossplane-system -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.serviceAccountName}{"\n"}{end}'

### Quick fix: Grant permissions to all service accounts in crossplane-system
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: provider-kubernetes-admin
subjects:
  - kind: ServiceAccount
    name: crossplane-contrib-provider-kubernetes-0be7cab050e9
    namespace: crossplane-system
  - kind: ServiceAccount
    name: crossplane-contrib-provider-helm-9a0591f0f59e
    namespace: crossplane-system
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
```

</details>

<details><summary><b>CREATE KCL SCHEMAS FROM XRD</b></summary>

```bash
# APPLY AGAINST K8S
kubectl apply -f ./definition.yaml
# READ CRD
kubectl get crd volumeclaims.resources.stuttgart-things.com -o yaml > /tmp/generated-crd-vc.yaml
# CREATE SCHEMA w/ KCL
kcl import -m crd /tmp/generated-crd-vc.yaml -o /tmp/schema
```

</details>
