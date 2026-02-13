# Testing Strategy

## Local Testing with crossplane render

Local rendering is the fastest way to validate compositions before deploying to a cluster.

### Prerequisites

- Crossplane CLI (`crossplane` binary)
- Docker (for function runtime)

### Basic Render

```bash
crossplane render examples/<name>.yaml \
  compositions/<name>.yaml \
  examples/functions.yaml \
  --include-function-results
```

### Expected Output

A successful render produces:

- Clean YAML manifests for each managed resource
- Correct `apiVersion` and `kind` (e.g. `helm.m.crossplane.io/v1beta1 Release`)
- Proper metadata (annotations with resource name, labels)
- Function results confirming readiness detection

### Common Render Errors

| Error | Cause | Fix |
|---|---|---|
| `compositeTypeRef.kind does not match XR's kind` | Example uses claim kind | Change to XR kind (`X<Kind>`) |
| `unknown Function "<name>"` | Function name mismatch | Align `functionRef.name` with `functions.yaml` |
| `cannot unmarshal` | YAML syntax error in template | Check Go template indentation and quoting |

### Testing Multiple Scenarios

Create variant example files to test different configurations:

```bash
# Test with minimal spec (defaults only)
crossplane render examples/<name>-minimal.yaml \
  compositions/<name>.yaml \
  examples/functions.yaml

# Test with all fields specified
crossplane render examples/<name>-full.yaml \
  compositions/<name>.yaml \
  examples/functions.yaml
```

## Cluster Testing

After local validation, deploy to a test cluster.

### Deploy

```bash
# Install the configuration package
kubectl apply -f examples/configuration.yaml

# Wait for package to be healthy
kubectl wait --for=condition=Healthy configuration/<name> --timeout=120s

# Install functions
kubectl apply -f examples/functions.yaml

# Apply a claim
kubectl apply -f examples/<name>.yaml
```

### Monitor

```bash
# Watch composite resource status
kubectl get x<plural> -w

# Detailed status with conditions
kubectl describe x<kind> <name>

# Check managed resources created by the composition
kubectl get managed

# Check Helm releases specifically
kubectl get releases
```

### Cleanup

```bash
kubectl delete -f examples/<name>.yaml
```

## Debug Commands

```bash
# Check function pods are running
kubectl get functions

# Function logs
kubectl logs -n crossplane-system deployment/function-go-templating

# Crossplane core logs
kubectl logs -n crossplane-system deployment/crossplane -f

# Composition status
kubectl get compositions
kubectl describe composition <name>

# Detailed XR events
kubectl get events --field-selector involvedObject.name=<xr-name>
```
