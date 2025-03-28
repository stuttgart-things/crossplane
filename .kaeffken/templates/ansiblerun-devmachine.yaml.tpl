---
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: AnsibleRun
metadata:
  name: {{ .targets }}-{{ .provisioning }}
  namespace: crossplane-system
spec:
  pipelineRunName: {{ .targets }}-{{ .provisioning }}
  createInventory: "true"
  inventory:
    - "all+[\"{{ .ip }}\"]"
  playbooks:
    - "sthings.baseos.prepare_env"
    - "sthings.baseos.setup"
    #- "sthings.container.tools"
    #- "sthings.container.docker"
    #- "sthings.container.nerdctl"
    #- "sthings.base_os.binaries"
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
    - send_to_homerun+-true
  gitRepoUrl: https://github.com/stuttgart-things/ansible.git
  gitRevision: main
  providerRef:
    name: in-cluster
  vaultSecretName: vault # pragma: allowlist secret
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
    - https://github.com/stuttgart-things/ansible/releases/download/sthings-container-25.4.1154/sthings-container-25.4.1154.tar.gz
    - https://github.com/stuttgart-things/ansible/releases/download/sthings-baseos-25.4.1100/sthings-baseos-25.4.1100.tar.gz
