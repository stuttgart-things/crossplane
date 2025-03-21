# stuttart-things/crossplane

crossplane configurations, apis and examples

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


## DEV

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
