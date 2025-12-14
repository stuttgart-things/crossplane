# CROSSPLANE/K8S/VCLUSTER

## GET KUBECONFIG

```bash
# EXAMPLE
kubectl get secret vcluster-k3s-tink5-connection \
-n crossplane-system \
-o jsonpath='{.data.kubeconfig}' | base64 -d > vcluster-k3s-tink5.kubeconfig
```
