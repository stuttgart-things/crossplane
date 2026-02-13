# Troubleshooting

## Local Render Issues

### compositeTypeRef.kind does not match XR's kind

```
crossplane: error: composition's compositeTypeRef.kind (XMyApp) does not match XR's kind (MyApp)
```

**Cause:** The example file uses the claim kind instead of the XR kind.

**Fix:** Change `kind: MyApp` to `kind: XMyApp` in the example file. `crossplane render` requires the composite resource (XR) kind.

### Unknown Function

```
crossplane: error: cannot run pipeline step "deploy-app": unknown Function "my-function" - does it exist in your Functions file?
```

**Cause:** The `functionRef.name` in the composition doesn't match the `metadata.name` in `functions.yaml`.

**Fix:** Ensure names match exactly between composition and functions file:

```yaml
# In compositions/<name>.yaml
functionRef:
  name: function-go-templating    # must match

# In examples/functions.yaml
metadata:
  name: function-go-templating    # must match
```

### Template Rendering Errors

```
crossplane: error: cannot render: template: ...: unexpected EOF
```

**Cause:** Go template syntax error (unclosed braces, missing end, bad indentation).

**Fix:** Check for:

- Matching `{{ if }}` / `{{ end }}` blocks
- Proper brace syntax `{{-` vs `{{`
- Correct YAML indentation inside the template string

## Cluster Issues

### XRD Validation Failed

```
Error: spec.names.kind is immutable
```

**Cause:** Trying to change the kind name on an existing XRD.

**Fix:** Delete and recreate the XRD (development only):

```bash
kubectl delete xrd x<plural>.resources.stuttgart-things.com
kubectl apply -f apis/definition.yaml
```

### Composition Not Selecting Claims

```
Condition: Ready, Status: False, Reason: CompositeResourceNotReady
```

**Cause:** Composition's `compositeTypeRef` doesn't match the XRD.

**Fix:** Verify the composition references the correct API version and kind:

```bash
kubectl get composition <name> -o yaml | grep -A2 compositeTypeRef
kubectl get xrd <name> -o yaml | grep -A2 'names:'
```

### Managed Resource Not Created

**Cause:** The composition pipeline may be failing silently.

**Fix:** Check in this order:

```bash
# 1. Check XR status and conditions
kubectl describe x<kind> <name>

# 2. Check composition events
kubectl get events --field-selector involvedObject.kind=<XKind>

# 3. Check function logs
kubectl logs -n crossplane-system deployment/function-go-templating

# 4. Check crossplane logs
kubectl logs -n crossplane-system deployment/crossplane
```

### Helm Release Stuck

```
Condition: Ready, Status: False, Reason: ReconcileError
```

**Cause:** The Helm chart deployment failed (bad values, missing secrets, chart not found).

**Fix:**

```bash
# Check the Release resource for details
kubectl describe release <release-name>

# Check Helm provider logs
kubectl logs -n crossplane-system deployment/provider-helm -f
```

## Quick Diagnostic Checklist

1. **Local render works?** → Run `crossplane render` first
2. **Functions installed?** → `kubectl get functions`
3. **Configuration healthy?** → `kubectl get configurations`
4. **XRD established?** → `kubectl get xrd`
5. **Composition available?** → `kubectl get compositions`
6. **XR has conditions?** → `kubectl describe x<kind> <name>`
7. **Managed resources exist?** → `kubectl get managed`
