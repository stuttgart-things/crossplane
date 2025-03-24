

---
apiVersion: v1
kind: Secret
metadata:
  name: tekton-vault
  namespace: crossplane-system
type: Opaque
data:
  approleSecret: ""