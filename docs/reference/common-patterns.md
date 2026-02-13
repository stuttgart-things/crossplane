# Common Patterns

## targetCluster Scope Selection

Every composition should support both `ProviderConfig` (namespaced) and `ClusterProviderConfig` (cluster-scoped) via the `targetCluster.scope` field:

```gotemplate
{{- $scope := $spec.targetCluster.scope | default "Namespaced" -}}
{{- $pcKind := "ProviderConfig" -}}
{{- if eq $scope "Cluster" -}}
{{- $pcKind = "ClusterProviderConfig" -}}
{{- end -}}

{{- $provider := $spec.targetCluster.name | default "in-cluster" -}}

spec:
  providerConfigRef:
    name: {{ $provider }}
    kind: {{ $pcKind }}
```

## Connection Secret Management

When resources need credentials or kubeconfig access, define a secret reference in the XRD:

```yaml
# In XRD schema
spec:
  properties:
    tokenSecret:
      type: object
      required: [name, namespace, key]
      properties:
        name:
          type: string
          default: my-secret
        namespace:
          type: string
          default: crossplane-system
        key:
          type: string
          default: TOKEN
```

Then reference it in the Go template:

```gotemplate
{{- $secretName := $spec.tokenSecret.name | default "my-secret" -}}
{{- $secretNs := $spec.tokenSecret.namespace | default "crossplane-system" -}}
{{- $secretKey := $spec.tokenSecret.key | default "TOKEN" -}}

set:
  - name: config.token
    valueFrom:
      secretKeyRef:
        name: {{ $secretName }}
        namespace: {{ $secretNs }}
        key: {{ $secretKey }}
```

## Helm Values from Spec

Map XRD fields directly into Helm chart values:

```gotemplate
{{- $version := $spec.version | default "1.0.0" -}}
{{- $namespace := $spec.deploymentNamespace | default "default" -}}

forProvider:
  namespace: {{ $namespace }}
  chart:
    name: my-chart
    repository: https://charts.example.com
    version: {{ $version }}
  values:
    replicaCount: {{ $spec.replicas | default 1 }}
    image:
      tag: {{ $spec.imageTag | default "latest" }}
```

## Dynamic Resource Naming

Build resource names from multiple spec fields using `printf`:

```gotemplate
{{- $releaseName := printf "app-%s-%s" $spec.repository $spec.environment -}}

metadata:
  annotations:
    {{ setResourceNameAnnotation $releaseName }}
```

## Status Reporting

Always include a status resource at the end of the Go template to report back to the XR:

```gotemplate
---
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: X<Kind>
status:
  installed: true
```

This updates the XR's `.status` subresource. The status schema must be defined in the XRD.

## Multi-Step Pipelines

For complex compositions, chain multiple function steps:

```yaml
pipeline:
  - step: deploy-core
    functionRef:
      name: function-go-templating
    input:
      apiVersion: gotemplating.fn.crossplane.io/v1beta1
      kind: GoTemplate
      source: Inline
      inline:
        template: |
          # render core resources ...

  - step: deploy-networking
    functionRef:
      name: function-go-templating
    input:
      apiVersion: gotemplating.fn.crossplane.io/v1beta1
      kind: GoTemplate
      source: Inline
      inline:
        template: |
          # render networking resources ...

  - step: automatically-detect-ready-composed-resources
    functionRef:
      name: crossplane-contrib-function-auto-ready
```

## Conditional Resources

Use Go template conditionals to create resources only when needed:

```gotemplate
{{- if $spec.monitoring.enabled }}
---
apiVersion: helm.m.crossplane.io/v1beta1
kind: Release
metadata:
  annotations:
    {{ setResourceNameAnnotation "monitoring" }}
spec:
  # monitoring release config ...
{{- end }}
```

## ProviderConfig Example

For `helm.m.crossplane.io/v1beta1` providers:

```yaml
---
apiVersion: helm.m.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: in-cluster
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: in-cluster
      key: config
```
