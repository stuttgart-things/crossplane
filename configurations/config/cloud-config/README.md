# Cloud Config

## DEV

```bash
crossplane render examples/claim.yaml apis/composition.yaml examples/functions.yaml --include-function-results
```

## CLAIM

```bash
---
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: CloudInit
metadata:
  name: dev2-vm
  namespace: default
spec:
  providerConfigRef: dev
  vmName: dev2
  namespace: default
  hostname: dev2
  domain: example.com
  timezone: UTC
  users:
    - name: ubuntu
      sshAuthorizedKeys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB...
      sudo: "ALL=(ALL) NOPASSWD:ALL"
      groups: sudo,docker
      shell: /bin/bash
      lockPasswd: true
  packages:
    - curl
    - wget
    - git
  runcmd:
    - systemctl enable docker
  packageUpdate: true
```

```bash
---
apiVersion: pkg.crossplane.io/v1beta1
kind: Function
metadata:
  name: function-go-templating
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-go-templating:v0.11.3
---
apiVersion: pkg.crossplane.io/v1beta1
kind: Function
metadata:
  name: function-auto-ready
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-auto-ready:v0.6.0
```
