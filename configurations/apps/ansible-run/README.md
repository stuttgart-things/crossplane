# ANSIBLE-RUN

## DEV

```bash
crossplane render examples/claim.yaml \
apis/composition.yaml \
examples/functions.yaml \
--include-function-results
```

## PREREQUISITES

### Create Namespace

```bash
kubectl create namespace tekton-ci
```

### Create ClusterProviderConfig

```bash
kubectl apply -f - <<EOF
---
apiVersion: kubernetes.m.crossplane.io/v1alpha1
kind: ClusterProviderConfig
metadata:
  name: dev
spec:
  credentials:
    source: InjectedIdentity
EOF
```

### Grant RBAC for Provider-Kubernetes

The provider-kubernetes service account needs permissions to manage Tekton resources.
Adjust the service account name to match your cluster's provider-kubernetes revision.

```bash
kubectl apply -f - <<EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: provider-kubernetes-tekton
rules:
- apiGroups: ["tekton.dev"]
  resources: ["pipelineruns", "pipelines", "tasks", "taskruns"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["persistentvolumeclaims", "secrets", "serviceaccounts"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: provider-kubernetes-tekton
subjects:
- kind: ServiceAccount
  name: <provider-kubernetes-service-account>
  namespace: crossplane-system
roleRef:
  kind: ClusterRole
  name: provider-kubernetes-tekton
  apiGroup: rbac.authorization.k8s.io
EOF
```

To find the correct service account name:

```bash
kubectl get sa -n crossplane-system | grep provider-kubernetes
```

### Create Secret

```bash
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: ansible-credentials
  namespace: tekton-ci
type: Opaque
stringData:
  ANSIBLE_USER: sthings
  ANSIBLE_PASSWORD: ""
EOF
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
