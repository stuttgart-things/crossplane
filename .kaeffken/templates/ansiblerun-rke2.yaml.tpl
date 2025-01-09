---
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: AnsibleRun
metadata:
  name: rke2-homerun-int
  namespace: crossplane-system
spec:
  pipelineRunName: rke2-homerun-int3
  createInventory: "false"
  varsFile: cmtlMl9jbmk6IGNpbGl1bQpkaXNhYmxlX3JrZTJfY29tcG9uZW50czoKICAtIHJrZTItaW5ncmVzcy1uZ2lueAogIC0gcmtlLXNuYXBzaG90LWNvbnRyb2xsZXIKY2x1c3Rlcl9zZXR1cDogbXVsdGlub2RlICNzaW5nbGVub2RlCnJrZTJfY25pOiBjaWxpdW0KdmFsdWVzX2NpbGl1bTogfAogIC0tLQogIGt1YmVQcm94eVJlcGxhY2VtZW50OiB0cnVlCiAgazhzU2VydmljZUhvc3Q6IDEyNy4wLjAuMQogIGs4c1NlcnZpY2VQb3J0OiA2NDQzCiAgY25pOgogICAgY2hhaW5pbmdNb2RlOiAibm9uZSIKCmhlbG1DaGFydENvbmZpZzoKICBjaWxpdW06CiAgICBuYW1lOiBya2UyLWNpbGl1bQogICAgbmFtZXNwYWNlOiBrdWJlLXN5c3RlbQogICAgcmVsZWFzZV92YWx1ZXM6ICJ7eyB2YWx1ZXNfY2lsaXVtIH19Ig==
  inventoryFile: W2luaXRpYWxfbWFzdGVyX25vZGVdCmhvbWVydW4taW50LmxhYnVsLnN2YS5kZQoKW2FkZGl0aW9uYWxfbWFzdGVyX25vZGVzXQpob21lcnVuLWludC0yLmxhYnVsLnN2YS5kZQpob21lcnVuLWludC0zLmxhYnVsLnN2YS5kZQo=
  inventory:
    - "all+[\"{{ .ip }}\"]"
  playbooks:
    - "plays/prepare-env.yaml"
    - "sthings.deploy_rke.rke2"
  ansibleVarsFile:
    - cluster_setup+-multinode
    - rke_state+-present #absent
    - rke_version+-2
    - rke2_k8s_version+-1.30.5
    - rke2_airgapped_installation+-true
    - rke2_release_kind+-rke2r1 #rke2r2
  gitRepoUrl: https://github.com/stuttgart-things/ansible.git
  gitRevision: main
  providerRef:
    name: in-cluster
  vaultSecretName: vault # pragma: allowlist secret
  pipelineNamespace: tekton-pipelines
  workingImage: ghcr.io/stuttgart-things/sthings-ansible:11.0.0
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
  roles:
    - "https://github.com/stuttgart-things/install-requirements.git,2024.05.11"
    - "https://github.com/stuttgart-things/manage-filesystem.git,2024.05.15"
