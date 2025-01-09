---
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: AnsibleRun
metadata:
  name: create-pdns-entry-{{ .clusterName }}
  namespace: tekton-pipelines
spec:
  pipelineRunName: create-pdns-entry-{{ .clusterName }}
  createInventory: "true"
  inventory:
    - "all+[\"{{ .targets }}\"]"
  playbooks:
    - "ansible/plays/pdns-ingress-entry.yaml"
  ansibleVarsFile:
    - pdns_url+-{{ .powerDNSInstance }}
    - entry_zone+-{{ .entryZone }}
    - hostname+-{{ .clusterName }}
    - ip_address+-{{ .ipAddress }}
  gitRepoUrl: https://github.com/stuttgart-things/ansible.git
  gitRevision: main
  providerRef:
    name: in-cluster
  vaultSecretName: vault # pragma: allowlist secret
  pipelineNamespace: tekton-pipelines
  workingImage: {{ .ansibleImage }}
  roles:
    - "https://github.com/stuttgart-things/install-configure-powerdns.git"
  collections:
    - community.crypto:2.22.3
    - community.general:10.1.0
