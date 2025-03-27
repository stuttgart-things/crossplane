# stuttgart-things/crossplane/ansible-run

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
EOF
```

```bash
SA=$(kubectl -n crossplane-system get sa -o name | grep provider-kubernetes | sed -e 's|serviceaccount\/|crossplane-system:|g')
kubectl create clusterrolebinding provider-kubernetes-admin-binding --clusterrole cluster-admin --serviceaccount="${SA}"
```

</details>

<details><summary><b>CONFIGURE EXTERNAL-CLUSTER PROVIDER</b></summary>

```bash
kubectl -n crossplane-system create secret generic kind-helm-dev --from-file=/home/sthings/.kube/kind-helm-dev
```

```bash
kubectl apply -f - <<EOF
---
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: kind-helm-dev
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: kind-helm-dev
      key: kind-helm-dev
EOF
```

</details>


## ANSIBLERUN CLAIM EXAMPLE

<details><summary><b>PRE-DEFINED INVENTORY</b></summary>

```bash
kubectl apply -f - <<EOF
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: AnsibleRun
metadata:
  name: baseos-k3s-sprechstunde13
  namespace: crossplane-system
spec:
  pipelineRunName: baseos-k3s-sprechstunde13
  createInventory: "false"
  inventoryFile: W2luaXRpYWxfbWFzdGVyX25vZGVdCmszcy1zcHJlY2hzdHVuZGUubGFidWwuc3ZhLmRlCgpbYWRkaXRpb25hbF9tYXN0ZXJfbm9kZXNdCg==
  playbooks:
    - "ansible/playbooks/prepare-env.yaml"
    - "ansible/playbooks/base-os.yaml"
  ansibleVarsFile:
    - manage_filesystem+-true
    - update_packages+-true
    - install_requirements+-true
    - install_motd+-true
    - username+-sthings
    - lvm_home_sizing+-'15%'
    - lvm_root_sizing+-'35%'
    - lvm_var_sizing+-'50%'
    - send_to_msteams+-true
    - reboot_all+-false
  gitRepoUrl: https://github.com/stuttgart-things/stuttgart-things.git
  gitRevision: main
  providerRef:
    name: in-cluster
  vaultSecretName: vault
  pipelineNamespace: tekton-pipelines
  workingImage: ghcr.io/stuttgart-things/sthings-ansible:11.0.0
  roles:
    - "https://github.com/stuttgart-things/install-requirements.git,2024.05.11"
    - "https://github.com/stuttgart-things/manage-filesystem.git,2024.05.15"
  collections:
    - community.crypto:2.22.3
    - community.general:10.1.0
    - ansible.posix:2.0.0
    - kubernetes.core:5.0.0
    - community.docker:4.1.0
    - community.vmware:5.2.0
    - awx.awx:24.6.1
    - community.hashi_vault:6.2.0
    - ansible.netcommon:7.1.0
    - https://artifacts.homerun-dev.sthings-vsphere.labul.sva.de/ansible-collections/sthings-container-24.612.59.tar.gz
    - https://artifacts.homerun-dev.sthings-vsphere.labul.sva.de/ansible-collections/sthings-deploy_rke-24.2843.39.tar.gz
    - https://github.com/stuttgart-things/stuttgart-things/releases/download/0.0.86/sthings-awx-0.0.86.tar.gz
    - https://artifacts.homerun-dev.sthings-vsphere.labul.sva.de/ansible-collections/sthings-base_os-24.21.29.tar.gz
EOT
```

</details>


<details><summary><b>TO BE CREATED INVENTORY</b></summary>

```bash
kubectl apply -f - <<EOF
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: AnsibleRun
metadata:
  name: baseos-k3s-sprechstunde12
  namespace: crossplane-system
spec:
  pipelineRunName: baseos-k3s-sprechstunde12
  inventory:
   - "all+[\"k3s-sprechstunde.labul.sva.de\"]"
  createInventory: "true"
  #inventoryFile: W2luaXRpYWxfbWFzdGVyX25vZGVdCjEwLjMxLjEwMy40MwoKW2FkZGl0aW9uYWxfbWFzdGVyX25vZGVzXQo=
  playbooks:
    - "ansible/playbooks/prepare-env.yaml"
    - "ansible/playbooks/base-os.yaml"
  ansibleVarsFile:
    - manage_filesystem+-true
    - update_packages+-true
    - install_requirements+-true
    - install_motd+-true
    - username+-sthings
    - lvm_home_sizing+-'15%'
    - lvm_root_sizing+-'35%'
    - lvm_var_sizing+-'50%'
    - send_to_msteams+-true
    - reboot_all+-false
  gitRepoUrl: https://github.com/stuttgart-things/stuttgart-things.git
  gitRevision: main
  providerRef:
    name: in-cluster
  vaultSecretName: vault
  pipelineNamespace: tekton-pipelines
  workingImage: ghcr.io/stuttgart-things/sthings-ansible:11.0.0
  roles:
    - "https://github.com/stuttgart-things/install-requirements.git,2024.05.11"
    - "https://github.com/stuttgart-things/manage-filesystem.git,2024.05.15"
  collections:
    - community.crypto:2.22.3
    - community.general:10.1.0
    - ansible.posix:2.0.0
    - kubernetes.core:5.0.0
    - community.docker:4.1.0
    - community.vmware:5.2.0
    - awx.awx:24.6.1
    - community.hashi_vault:6.2.0
    - ansible.netcommon:7.1.0
    - https://artifacts.homerun-dev.sthings-vsphere.labul.sva.de/ansible-collections/sthings-container-24.612.59.tar.gz
    - https://artifacts.homerun-dev.sthings-vsphere.labul.sva.de/ansible-collections/sthings-deploy_rke-24.2843.39.tar.gz
    - https://github.com/stuttgart-things/stuttgart-things/releases/download/0.0.86/sthings-awx-0.0.86.tar.gz
    - https://artifacts.homerun-dev.sthings-vsphere.labul.sva.de/ansible-collections/sthings-base_os-24.21.29.tar.gz
EOT
```

</details>
