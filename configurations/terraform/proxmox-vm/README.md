# stuttgart-things/crossplane/proxmox-vm

## CONFIGURATION

<details><summary><b>CONFIGURE IN-CLUSTER PROVIDER</b></summary>

```bash
kubectl apply -f - <<EOF
---
apiVersion: tf.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: proxmox-vm
spec:
  configuration: |
    terraform {
      backend "kubernetes" {
        secret_suffix     = "proxmox-vm-tfstate" # pragma: allowlist secret
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
kubectl create secret generic proxmox-tfvars --from-literal=terraform.tfvars="$(cat <<EOF
pve_api_url=""
pve_api_user="terraform@pve"
pve_api_password=""
pve_api_tls_verify = true
vm_ssh_user="sthings"
vm_ssh_password=""
EOF
)"
```

</details>
