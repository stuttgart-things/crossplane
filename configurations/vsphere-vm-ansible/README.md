# stuttgart-things/crossplane/vsphere-vm-ansible

## CONFIGURATION

<details><summary><b>CONFIGURE IN-CLUSTER TERRAFORM PROVIDER</b></summary>

```bash
kubectl apply -f - <<EOF
---
apiVersion: tf.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: vsphere-vm
spec:
  configuration: |
    terraform {
      backend "kubernetes" {
        secret_suffix     = "vsphere-vm-tfstate" # pragma: allowlist secret
        namespace         = "crossplane-system"
        in_cluster_config = true
      }
    }
EOF
```

</details>

<details><summary><b>CONFIGURE IN-CLUSTER KUBERNETES PROVIDER</b></summary>

```bash
kubectl apply -f - <<EOF
---
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: kubernetes-incluster
spec:
  credentials:
    source: InjectedIdentity
EOF
```

```bash
SA=$(kubectl -n crossplane-system get sa -o name | grep provider-kubernetes | sed -e 's|serviceaccount\/|crossplane-system:|g')
kubectl create clusterrolebinding provider-kubernetes-admin-binding --clusterrole cluster-admin --serviceaccount="${SA}"
```

</details>
