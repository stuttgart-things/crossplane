# ANSIBLE-RUN

## DEV

```bash
crossplane render examples/claim.yaml \
apis/composition.yaml \
examples/functions.yaml \
--include-function-results
```

## RENDER KCL

```bash
kcl run oci://ghcr.io/stuttgart-things/kcl-tekton-pr --tag 0.4.2 -D params='{
  "oxr": {
    "spec": {
      "pipelineRunName": "run-ansible-test1",
      "namespace": "tekton-ci",
      "ansibleCredentialsSecretName": "ansible-credentials",
      "ansiblePlaybooks": [
        "sthings.baseos.setup"
      ],
      "ansibleVarsFile": [
        "manage_filesystem+-true",
        "update_packages+-true",
        "ansible_become+-true",
        "ansible_become_method+-sudo"
      ],
      "ansibleVarsInventory": [
        "all+[\"10.31.102.107\"]"
      ],
      "wrapInCrossplane": true,
      "crossplaneObjectName": "run-ansible-test",
      "crossplaneNamespace": "default",
      "crossplaneProviderConfig": "dev"
    }
  }
}' --format yaml
```
