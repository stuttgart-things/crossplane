# Creating a New Helm v2 Crossplane Configuration

This guide shows how to create a new Crossplane configuration package that deploys a Helm chart using the v2 format with `function-go-templating`.

## Directory structure

Create the following layout:

```
configurations/apps/<name>/
  apis/
    definition.yaml
  compositions/
    <name>.yaml
  examples/
    <name>.yaml
    functions.yaml
    provider-config.yaml
    configuration.yaml
  crossplane.yaml
```

```bash
APP=my-app
mkdir -p configurations/apps/${APP}/{apis,compositions,examples}
```

## 1. Define the XRD (`apis/definition.yaml`)

The XRD declares the custom resource schema users will interact with.

```yaml
---
apiVersion: apiextensions.crossplane.io/v2
kind: CompositeResourceDefinition
metadata:
  name: x<plural>.resources.stuttgart-things.com
spec:
  group: resources.stuttgart-things.com
  defaultCompositeDeletePolicy: Foreground
  scope: Namespaced
  names:
    kind: X<Kind>
    plural: x<plural>
    singular: x<singular>
  claimNames:
    kind: <Kind>
    plural: <plural>
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          description: <description>
          properties:
            spec:
              type: object
              properties:
                targetCluster:
                  type: object
                  required:
                    - name
                  properties:
                    name:
                      type: string
                      default: in-cluster
                      description: Name of the ProviderConfig / ClusterProviderConfig
                    scope:
                      type: string
                      enum:
                        - Namespaced
                        - Cluster
                      default: Namespaced
                      description: |
                        Whether to use ProviderConfig (Namespaced)
                        or ClusterProviderConfig (Cluster)
                deploymentNamespace:
                  type: string
                  default: default
                  description: target namespace for the Helm release
                version:
                  type: string
                  default: "1.0.0"
                  description: Helm chart version
                # Add app-specific fields here
              required:
                - targetCluster
            status:
              type: object
              properties:
                installed:
                  type: boolean
                  description: Whether the app is installed
```

### Guidelines

- Always include `targetCluster` with `name` and `scope` for multi-cluster support
- Use sensible defaults so a minimal claim works out of the box
- Keep `required` fields to the minimum necessary
- Add a `status` block so the composition can report state

## 2. Write the Composition (`compositions/<name>.yaml`)

The composition uses an inline Go template to render Helm Release resources.

```yaml
---
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: <name>
  labels:
    crossplane.io/xrd: x<plural>.resources.stuttgart-things.com
spec:
  compositeTypeRef:
    apiVersion: resources.stuttgart-things.com/v1alpha1
    kind: X<Kind>
  mode: Pipeline
  pipeline:
    - step: deploy-<name>
      functionRef:
        name: function-go-templating
      input:
        apiVersion: gotemplating.fn.crossplane.io/v1beta1
        kind: GoTemplate
        source: Inline
        inline:
          template: |
            {{- $spec := .observed.composite.resource.spec -}}

            {{- $scope := $spec.targetCluster.scope | default "Namespaced" -}}
            {{- $pcKind := "ProviderConfig" -}}
            {{- if eq $scope "Cluster" -}}
            {{- $pcKind = "ClusterProviderConfig" -}}
            {{- end -}}

            {{- $provider := $spec.targetCluster.name | default "in-cluster" -}}
            {{- $namespace := $spec.deploymentNamespace | default "default" -}}
            {{- $version := $spec.version | default "1.0.0" -}}
            ---
            apiVersion: helm.m.crossplane.io/v1beta1
            kind: Release
            metadata:
              annotations:
                {{ setResourceNameAnnotation "<name>" }}
              labels:
                app.kubernetes.io/name: <name>
                app.kubernetes.io/managed-by: crossplane
            spec:
              providerConfigRef:
                name: {{ $provider }}
                kind: {{ $pcKind }}

              forProvider:
                namespace: {{ $namespace }}

                chart:
                  name: <chart-name>
                  repository: <chart-repo-url>
                  version: {{ $version }}

                wait: true

            ---
            apiVersion: resources.stuttgart-things.com/v1alpha1
            kind: X<Kind>
            status:
              installed: true

    - step: automatically-detect-ready-composed-resources
      functionRef:
        name: crossplane-contrib-function-auto-ready
```

### Template patterns

**Reading spec fields:**

```gotemplate
{{- $spec := .observed.composite.resource.spec -}}
{{- $value := $spec.myField | default "fallback" -}}
```

**ProviderConfig scope selection (include in every composition):**

```gotemplate
{{- $scope := $spec.targetCluster.scope | default "Namespaced" -}}
{{- $pcKind := "ProviderConfig" -}}
{{- if eq $scope "Cluster" -}}
{{- $pcKind = "ClusterProviderConfig" -}}
{{- end -}}
```

**Resource naming with `setResourceNameAnnotation`:**

```gotemplate
metadata:
  annotations:
    {{ setResourceNameAnnotation "my-release" }}
```

For dynamic names using spec fields:

```gotemplate
{{- $releaseName := printf "app-%s-%s" $spec.repository $provider -}}
{{ setResourceNameAnnotation $releaseName }}
```

**Helm values from spec:**

```gotemplate
values:
  replicaCount: {{ $spec.replicas | default 1 }}
  image:
    tag: {{ $spec.imageTag | default "latest" }}
```

**Secret references in Helm set:**

```gotemplate
set:
  - name: secret.token
    valueFrom:
      secretKeyRef:
        name: {{ $spec.tokenSecret.name }}
        namespace: {{ $spec.tokenSecret.namespace }}
        key: {{ $spec.tokenSecret.key }}
```

**Status output (always include at the end):**

```gotemplate
---
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: X<Kind>
status:
  installed: true
```

## 3. Package metadata (`crossplane.yaml`)

```yaml
---
apiVersion: meta.pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: <name>
  annotations:
    meta.crossplane.io/maintainer: <email>
    meta.crossplane.io/source: https://github.com/stuttgart-things/crossplane
    meta.crossplane.io/license: Apache-2.0
    meta.crossplane.io/description: |
      deploys <name> with crossplane
    meta.crossplane.io/readme: |
      deploys <name> with crossplane
spec:
  crossplane:
    version: ">=2.13.0"
  dependsOn:
    - provider: xpkg.upbound.io/crossplane-contrib/provider-helm
      version: ">=v0.19.0"
```

## 4. Example files

### `examples/functions.yaml`

```yaml
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
  name: crossplane-contrib-function-auto-ready
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-auto-ready:v0.6.0
```

### `examples/provider-config.yaml`

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

### `examples/<name>.yaml`

Use the **XR kind** (not the claim kind) so `crossplane render` works:

```yaml
---
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: X<Kind>
metadata:
  name: test
spec:
  targetCluster:
    name: in-cluster
    scope: Namespaced
  version: "1.0.0"
```

### `examples/configuration.yaml`

```yaml
---
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: <name>
spec:
  package: ghcr.io/stuttgart-things/crossplane/<name>:v0.1.0
```

## 5. Validate

Run `crossplane render` to verify the template produces valid output:

```bash
crossplane render examples/<name>.yaml \
  compositions/<name>.yaml \
  examples/functions.yaml \
  --include-function-results
```

Expected output includes:

- A `helm.m.crossplane.io/v1beta1` Release resource with your chart configuration
- A function result from `function-auto-ready`

## Quick-start template

Copy an existing working configuration as a starting point:

```bash
cp -r configurations/apps/github-controller configurations/apps/<new-app>
```

Then search-and-replace the kind names, chart details, and app-specific fields.
