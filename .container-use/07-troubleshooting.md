# Troubleshooting

## Common Issues

### Issue: KCL module not found
```
Error: failed to pull OCI artifact: not found
```
**Solution**:
- Verify OCI path in composition
- Check module is published: `kcl mod metadata oci://ghcr.io/stuttgart-things/xplane-{resource}`
- Ensure version tag exists

### Issue: XRD validation failed
```
Error: spec.names.kind is immutable
```
**Solution**: Delete and recreate XRD (only in development)
```bash
kubectl delete xrd x{resources}.github.stuttgart-things.com
kubectl apply -f apis/definition.yaml
```

### Issue: Composition not selecting claims
```
Condition: Ready, Status: False, Reason: CompositeResourceNotReady
```
**Solution**: Check composition selector matches XRD
```bash
kubectl get composition xplane-{resource} -o yaml
kubectl get xrd x{resources}.github.stuttgart-things.com -o yaml
```

## Debug Commands

```bash
# Check function status
kubectl get functions
kubectl logs -n crossplane-system deployment/function-kcl

# Check composition status
kubectl get compositions
kubectl describe composition xplane-{resource}

# Check composite resource
kubectl get x{resources} -o wide
kubectl describe x{resource} {name}

# Check managed resources
kubectl get managed

# Crossplane logs
kubectl logs -n crossplane-system deployment/crossplane -f
```
