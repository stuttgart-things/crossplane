# COMMANDS/TROUBLESHOOTING

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
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
```

</details>
