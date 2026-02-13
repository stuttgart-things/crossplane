# Combined Configurations (Composition of Compositions)

## Purpose

A combined configuration orchestrates multiple existing Crossplane composites behind a single, simple API. Instead of re-implementing logic, it:

- Reuses existing XRDs as building blocks
- Composes them via a Pipeline Composition
- Acts as a thin orchestration layer
- Aggregates status into a single parent resource

This pattern is ideal for:

- Virtual machines (disk + cloud-init + networking)
- Applications (app + database + backup)
- Platforms (cluster + ingress + monitoring)

## When to Use

Use this pattern when **all** of the following are true:

- You already have stable base composites
- Each base composite is useful on its own
- You want a better user experience (fewer claims)
- You need ordering, dependency awareness, or aggregation

**Do not** use this pattern if:

- The logic belongs in a single resource
- The sub-resources are tightly coupled and never reused
- You can solve the problem with a single composition

## Architecture

```
┌───────────────────────────┐
│     Combined Claim        │
│   (single user API)       │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│   Combined Composition    │
│       (Pipeline)          │
├──────────┬────────────────┤
│          │                │
▼          ▼                ▼
Base       Base          (future)
Composite  Composite      Base
A          B              Composite
```

The combined composition does **not** create managed resources directly. It creates other composite resources, which in turn create managed resources.

## Step 1: Base Composites (Building Blocks)

Before creating a combined configuration, you need working base composites. Each has:

- Its own XRD
- Its own Composition
- Its own lifecycle and status

These are treated as black boxes by the combined configuration.

## Step 2: Combined XRD (Facade API)

The combined XRD defines the public API. Key principles:

- Group related fields by sub-resource
- Reuse field names from base composites
- Add defaults aggressively
- Expose only what users need

```yaml
spec:
  properties:
    targetCluster:
      type: object
      properties:
        name:
          type: string
        scope:
          type: string

    volume:
      type: object
      required: [pvcName, storageClassName]
      properties:
        pvcName:
          type: string
        storageClassName:
          type: string
        storage:
          type: string
          default: 10Gi

    cloudInit:
      type: object
      required: [vmName, hostname]
      properties:
        vmName:
          type: string
        hostname:
          type: string
        domain:
          type: string
          default: local
```

### Status Aggregation

The combined XRD should aggregate child readiness:

```yaml
status:
  type: object
  properties:
    volume:
      type: object
      properties:
        ready:
          type: boolean
    cloudInit:
      type: object
      properties:
        ready:
          type: boolean
```

This gives users one place to check readiness.

## Step 3: Pipeline Composition

Each child composite is created in its own pipeline step using go-templating:

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: combined-vm
spec:
  compositeTypeRef:
    apiVersion: resources.stuttgart-things.com/v1alpha1
    kind: XCombinedVM
  mode: Pipeline
  pipeline:
    - step: create-volume
      functionRef:
        name: function-go-templating
      input:
        apiVersion: gotemplating.fn.crossplane.io/v1beta1
        kind: GoTemplate
        source: Inline
        inline:
          template: |
            {{- $spec := .observed.composite.resource.spec -}}
            ---
            apiVersion: resources.stuttgart-things.com/v1alpha1
            kind: XVolumeClaim
            metadata:
              annotations:
                {{ setResourceNameAnnotation "volume" }}
            spec:
              targetCluster:
                name: {{ $spec.targetCluster.name }}
                scope: {{ $spec.targetCluster.scope | default "Namespaced" }}
              pvcName: {{ $spec.volume.pvcName }}
              storageClassName: {{ $spec.volume.storageClassName }}
              storage: {{ $spec.volume.storage | default "10Gi" }}

    - step: create-cloud-init
      functionRef:
        name: function-go-templating
      input:
        apiVersion: gotemplating.fn.crossplane.io/v1beta1
        kind: GoTemplate
        source: Inline
        inline:
          template: |
            {{- $spec := .observed.composite.resource.spec -}}
            ---
            apiVersion: resources.stuttgart-things.com/v1alpha1
            kind: XCloudInit
            metadata:
              annotations:
                {{ setResourceNameAnnotation "cloud-init" }}
            spec:
              targetCluster:
                name: {{ $spec.targetCluster.name }}
                scope: {{ $spec.targetCluster.scope | default "Namespaced" }}
              vmName: {{ $spec.cloudInit.vmName }}
              hostname: {{ $spec.cloudInit.hostname }}
              domain: {{ $spec.cloudInit.domain | default "local" }}

    - step: automatically-detect-ready-composed-resources
      functionRef:
        name: crossplane-contrib-function-auto-ready
```

## Minimal Claim Experience

A well-designed combined configuration allows very small claims:

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: CombinedVM
metadata:
  name: minimal-vm
  namespace: crossplane-system
spec:
  targetCluster:
    name: in-cluster
  volume:
    pvcName: minimal-vm-disk
    storageClassName: longhorn
  cloudInit:
    vmName: minimal-vm
    hostname: minimal
```

This works because defaults live in the XRD and logic lives in base composites.

## Design Rules

### DO

- Use Pipeline mode
- Keep steps small and focused
- Aggregate status explicitly
- Treat child composites as black boxes
- Prefer defaults in XRD over template logic
- Name steps by intent (`create-volume`, not `step-1`)

### DO NOT

- Duplicate logic from base composites
- Create managed resources directly in a combined composition
- Pass secrets via claims
- Overload one step with multiple concerns
- Hide behavior in complex template expressions

## Mental Model

A combined configuration is not a new implementation. It is an **orchestration contract**.

If done correctly:

- Base composites remain reusable
- Claims remain simple
- The platform evolves without breaking users
