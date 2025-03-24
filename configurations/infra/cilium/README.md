# CILIUM

## CLAIM

```bash
kubectl apply -f - <<EOF
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: Cilium
metadata:
  name: kind-sthings
  namespace: crossplane-system
spec:
  clusterName: kind-sthings
  version: 1.17.2
  values:
    kubeProxyReplacement: true
    routingMode: "native"
    ipv4NativeRoutingCIDR: "10.244.0.0/16"
    k8sServiceHost: stuttgart-things-control-plane # CHECK FOR NAME OF CONTROL PLANE NODE
    k8sServicePort: 6443
    l2announcements:
      enabled: true
      leaseDuration: "3s"
      leaseRenewDeadline: "1s"
      leaseRetryPeriod: "500ms"
    devices: ["eth0", "net0"]
    externalIPs:
      enabled: true
    autoDirectNodeRoutes: true
    operator:
      replicas: 2
EOF
```

## CONFIGURATION (KUBECONFIG)

```bash
CLUSTER_NAME=kind-sthings

kubectl -n crossplane-system create secret generic ${CLUSTER_NAME} --from-file=/home/sthings/.kube/${CLUSTER_NAME}

kubectl apply -f - <<EOF
apiVersion: helm.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: ${CLUSTER_NAME}
spec:
  credentials:
    source: Secret
    secretRef:
      name: ${CLUSTER_NAME}
      namespace: crossplane-system
      key: ${CLUSTER_NAME}
EOF
```
