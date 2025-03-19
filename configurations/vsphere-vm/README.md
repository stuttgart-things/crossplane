# stuttgart-things/crossplane/vsphere-vm

## CONFIGURATION

<details><summary><b>CONFIGURE IN-CLUSTER PROVIDER</b></summary>

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

```bash
SA=$(kubectl -n crossplane-system get sa -o name | grep provider-kubernetes | sed -e 's|serviceaccount\/|crossplane-system:|g')
kubectl create clusterrolebinding provider-kubernetes-admin-binding --clusterrole cluster-admin --serviceaccount="${SA}"
```

</details>

<details><summary><b>CREATE TFVARS AS SECRET</b></summary>

```bash
# CREATE terraform.tfvars
cat <<EOF > terraform.tfvars
vsphere_user = "<USER>"
vsphere_password = "<PASSWORD>"
vm_ssh_user = "<SSH_USER>"
vm_ssh_password = "<SSH_PASSWORD>"
EOF
```

```bash
# CREATE SECRET
kubectl create secret generic vsphere-tfvars --from-file=terraform.tfvars
```

</details>

## VSPHERE-VM CLAIM EXAMPLE
