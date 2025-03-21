# stuttgart-things/crossplane/vsphere-vm

## CONFIGURATION

<details><summary><b>CONFIGURE IN-CLUSTER PROVIDER</b></summary>

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

<details><summary><b>CREATE TFVARS AS SECRET</b></summary>

```bash
# CREATE SECRET
kubectl create secret generic vsphere-tfvars --from-literal=terraform.tfvars="$(cat <<EOF
vsphere_user = ""
vsphere_password = ""
vm_ssh_user = ""
vm_ssh_password = ""
vsphere_server=""
EOF
)"
```

</details>

## VSPHERE-VM CLAIM EXAMPLE
