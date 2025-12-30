# stuttart-things/crossplane

crossplane configurations, apis and examples

## DEV KIND CLUSTER DEPLOYMENT & CONFIGURATION OF CROSSPLANE

<details><summary><b>CREATE KIND CLUSTER</b></summary>

```bash
export TASK_X_REMOTE_TASKFILES=1
task --taskfile https://raw.githubusercontent.com/stuttgart-things/tasks/refs/heads/main/kubernetes/kind.yaml create-kind-cluster

export KUBECONFIG=/home/sthings/.kube/<CLUSTER-NAME>
task --taskfile https://raw.githubusercontent.com/stuttgart-things/tasks/refs/heads/main/kubernetes/crds.yaml kubectl-kustomize #apply+cilium
task --taskfile https://raw.githubusercontent.com/stuttgart-things/tasks/refs/heads/main/kubernetes/helm.yaml helmfile-operation #apply+cilium
```

</details>

<details><summary><b>CROSSPLANE DEPLOYMENT w/ DAGGER/HELMFILE</b></summary>

```bash
kubectl apply --server-side -k https://github.com/stuttgart-things/helm/cicd/crds/crossplane

# BY TASKFILE
export TASK_X_REMOTE_TASKFILES=1
task --taskfile https://raw.githubusercontent.com/stuttgart-things/tasks/refs/heads/main/kubernetes/helm.yaml helmfile-operation #apply+crossplane
```

```bash
# OR BY DIRECT DAGGER CALL
dagger call -m github.com/stuttgart-things/dagger/helm@v0.57.0 helmfile-operation \
  --helmfile-ref "git::https://github.com/stuttgart-things/helm.git@cicd/crossplane.yaml.gotmpl" \
  --operation apply \
  --state-values "version=2.1.3" \
  --kube-config file:///home/sthings/.kube/config \
  --progress plain -vv
```

</details>

<details><summary><b>CROSSPLANE DEPLOYMENT w/ DAGGER/HELMFILE</b></summary>

```bash
kubectl apply -k https://github.com/stuttgart-things/helm/cicd/crds/tekton
```

```bash
# DEPLOY OPENEBS w/ DAGGER
dagger call -m github.com/stuttgart-things/dagger/helm@v0.57.0 \
  helmfile-operation \
  --helmfile-ref "git::https://github.com/stuttgart-things/helm.git@infra/openebs.yaml.gotmpl" \
  --operation apply \
  --state-values "namespace=openebs-system,profile=localpv,openebs_volumesnapshots_enabled=false,openebs_csi_node_init_containers_enabled=false,openebs_local_lvm_enabled=false,openebs_local_zfs_enabled=false,openebs_replicated_mayastor_enabled=false" \
  --kube-config file://~/.kube/config \
  --progress plain -vv
```

```bash
# DEPLOY TEKTON w/ DAGGER
dagger call -m github.com/stuttgart-things/dagger/helm@v0.57.0 \
  helmfile-operation \
  --helmfile-ref "git::https://github.com/stuttgart-things/helm.git@cicd/tekton.yaml.gotmpl" \
  --operation apply \
  --state-values "namespace=tekton-operator,pipelineNamespace=tekton-pipelines,version=0.77.5" \
  --kube-config file://~/.kube/config \
  --progress plain -vv
```

</details>

<details><summary><b>ADD LOCAL CLUSTER AS KUBERNETES PROVIDER (FILEBASED)</b></summary>

```bash
NAMESPACE="crossplane-system"
KUBECONFIG_DIR="$HOME/.kube"

# Select kubeconfig file
KUBECONFIG_FILE=$(ls -1 "$KUBECONFIG_DIR" \
  | gum choose --header "Select kubeconfig file")

KUBECONFIG_PATH="$KUBECONFIG_DIR/$KUBECONFIG_FILE"

# Secret name
SECRET_NAME=$(gum input \
  --prompt "Secret name: " \
  --value "dev")

# Create or update secret (idempotent)
kubectl -n "$NAMESPACE" create secret generic "$SECRET_NAME" \
  --from-file=config="$KUBECONFIG_PATH" \
  --dry-run=client -o yaml \
  | kubectl apply -f -
```

```bash
NAMESPACE="crossplane-system"

CONFIG_NAME=$(gum input \
  --prompt "ClusterProviderConfig name: " \
  --value "dev")

SECRET_NAME=$(kubectl get secret -n "$NAMESPACE" \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' \
  | gum choose --header "Select secret")

SECRET_KEY=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" \
  -o json \
  | jq -r '.data | keys[]' \
  | gum choose --header "Select key from secret '$SECRET_NAME'")

if ! gum confirm "Apply ClusterProviderConfig '$CONFIG_NAME' using $SECRET_NAME:$SECRET_KEY?"; then
  echo "Aborted."
  exit 0
fi

kubectl apply -f - <<EOF
apiVersion: kubernetes.m.crossplane.io/v1alpha1
kind: ClusterProviderConfig
metadata:
  name: $CONFIG_NAME
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: $NAMESPACE
      name: $SECRET_NAME
      key: $SECRET_KEY
EOF
```

</details>

<details><summary><b>APPLY CROSSPLANE PACKAGES</b></summary>

```bash
# BY TASKFILE
export TASK_X_REMOTE_TASKFILES=1
task --taskfile https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/Taskfile.yaml apply-crossplane-packages
```

</details>

<details><summary><b>APPLY CROSSPLANE PACKAGES</b></summary>

```bash
# BY TASKFILE
export TASK_X_REMOTE_TASKFILES=1
task --taskfile https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/Taskfile.yaml apply-crossplane-packages
```

</details>


## CONFIGURATIONS

<details><summary><b>ANSIBLE-RUN</b></summary>

* [SEE-HOW-TO-USE](configurations/ansible-run/README.md)

* INSTALL

```bash
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: ansible-run
spec:
  package: ghcr.io/stuttgart-things/crossplane/ansible-run:11.0.0
EOF
```

</details>


## DEVELOPMENT

### Quick Start

```bash
# Setup standardized development environment
source .container-use/container-use.sh
cu-setup

# Access development environment
container-use checkout crossplane-development

# Test existing configurations
cu-test-vcluster
cu-test-ansible-run
cu-test-all
```

### Development Standards

This repository follows structured development specifications:

- 📋 **[Development Specification](.container-use/specs/crossplane-configuration-development.md)** - Complete development workflow
- 🛠️ **[Configuration Template](.container-use/specs/configuration-template.md)** - Standardized template for new configurations
- � **[Container-Use Workflow](docs/container-use-workflow.md)** - Environment merge and workflow automation
- �📚 **[Specifications Index](.container-use/specs/README.md)** - Overview of all specifications

### Workflow Automation

Standardized tasks for environment management:

```bash
# Interactive environment merge
task merge-environment

# Direct environment merge
task merge-environment-auto ENV_ID=your-env-id

# Pull request workflow
task merge-environment-pr

# View all available tasks
task do
```
- 🚀 **[Container-Use Setup](.container-use/README.md)** - Standardized development environment

### Quick Specification Access

```bash
# Load helper functions
source .container-use/container-use.sh

# View specifications
cu-spec                           # Show available specs
cu-new my-config apps            # Create new config with guidance
```

### Available Tasks

```bash
task: Available tasks for this project:
* branch:                    Create branch from main
* check:                     Run pre-commit hooks
* commit:                    Commit + push code into branch
* do:                        Select a task to run
* pr:                        Create pull request into main
* run-pre-commit-hook:       Run the pre-commit hook script to replace .example.com with .example.com
* xplane-push:               Push crossplane package
```
