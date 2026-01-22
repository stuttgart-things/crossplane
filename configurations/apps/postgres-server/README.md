# Postgres Server (Crossplane Dev)

A concise Crossplane configuration for a `PostgresServer` claim: it includes the XRD (CompositeResourceDefinition), a Composition (e.g., via provider-helm), and an example claim.

## Overview
- XRD/Definition: apis/definition.yaml
- Composition: apis/composition.yaml
- Claim example: examples/claim.yaml
- Functions/Pipeline: examples/functions.yaml
- Configuration metadata: crossplane.yaml

## Prerequisites
- Crossplane installed on the target cluster
- provider-helm and (if used) provider-kubernetes installed and configured
- kubectl access to the Crossplane cluster
- Namespace for database workloads, e.g., postgres

## Quickstart
1. Render locally (validate pipeline):
```bash
crossplane render examples/claim.yaml \
  apis/composition.yaml \
  examples/functions.yaml \
  --include-function-results
```

2. Create the app credentials Secret in the target namespace (make sure your claim uses the same namespace):
```bash
kubectl -n postgres apply -f - <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: postgres-app-credentials
type: Opaque
stringData:
  postgres-password: supersecret
EOF
```

3. Apply the claim:
```bash
kubectl apply -f examples/claim.yaml
```

4. Verify Helm release (via provider-helm):
```bash
kubectl get releases.helm.m.crossplane.io -A
kubectl describe releases.helm.m.crossplane.io my-postgres-d499897318cc
```

5. Inspect Crossplane resources:
```bash
kubectl get composite -A | grep -i postgres
kubectl get xr -A | grep -i postgres
kubectl get claim -A | grep -i PostgresServer
```

## Troubleshooting
- Namespace mismatch: Ensure the claim uses the same namespace as your Secrets/workloads (e.g., postgres).
- Missing Secret: postgres-app-credentials must exist before provisioning (or be optional in the chart/composition).
- Helm CRD ownership conflicts: Stale CRDs/owner annotations can cause conflicts; remove/update safely.
- Provider config: provider-helm must have access to the target cluster/namespace.

## Cleanup
```bash
kubectl delete -f examples/claim.yaml
kubectl -n postgres delete secret postgres-app-credentials
```
