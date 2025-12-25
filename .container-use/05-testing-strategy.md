# Testing Strategy

## Local Testing (Recommended)

**Prerequisites**:
- Crossplane CLI v1.20.0+
- Docker (for KCL function runtime)

**Commands**:
```bash
# Basic render test
crossplane render examples/claim.yaml \
                   apis/composition.yaml \
                   examples/functions.yaml

# Verbose output
crossplane render examples/claim.yaml \
                   apis/composition.yaml \
                   examples/functions.yaml \
                   --verbose

# Multiple claim tests
for claim in examples/*.yaml; do
  echo "Testing $claim..."
  crossplane render $claim apis/composition.yaml examples/functions.yaml
done
```

**Expected Output**:
- Clean YAML manifests
- Correct resource types
- Proper metadata and labels
- Valid resource counts

## Cluster Testing

```bash
# Deploy to test cluster
kubectl apply -f crossplane.yaml
kubectl wait --for=condition=Healthy configuration/configuration-{resource}

# Apply resources
kubectl apply -f apis/
kubectl apply -f examples/claim.yaml

# Monitor
kubectl get x{resources} -w
kubectl describe x{resource} {name}

# Cleanup
kubectl delete -f examples/claim.yaml
kubectl delete -f apis/
```
