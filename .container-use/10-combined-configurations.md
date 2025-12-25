# Combined Configurations (Composition of Compositions)

## Purpose

A combined configuration (also called a composite-of-composites) is used when a higher-level resource should orchestrate multiple existing Crossplane composites behind a single, simple API.

Instead of re-implementing logic, the combined configuration:

- Reuses existing XRDs
- Composes them via a Pipeline Composition
- Acts as a thin orchestration layer
- Aggregates status into a single parent resource

This pattern is ideal for:

- Virtual machines (disk + cloud-init + networking)
- Applications (app + database + backup)
- Platforms (cluster + ingress + monitoring)

## When to Use a Combined Configuration

Use this pattern when all of the following are true:

- You already have stable base composites
- Each base composite is useful on its own
- You want a better user experience (fewer claims)
- You need ordering, dependency awareness, or aggregation

Do not use this pattern if:

- The logic belongs in a single resource
- The sub-resources are tightly coupled and never reused
- You can solve the problem with a single KCL module

## Architecture Overview

```
┌───────────────────────┐
│   HarvesterVM Claim   │
└─────────┬─────────────┘
          │
          ▼
┌────────────────────────────┐
│  HarvesterVM Composition   │
│        (Pipeline)          │
├───────────────┬────────────┤
│               │            │
▼               ▼            ▼
VolumeClaim   CloudInit   (future)
 Composite     Composite     VM
```

The combined composition does not create managed resources directly. It creates other composite resources, which in turn create managed resources.

## Step 1: Base Composites (Building Blocks)

Before creating a combined configuration, you must have working base composites.

Example base composites:

- VolumeClaim
- CloudInit

Each has:

- Its own XRD
- Its own Composition
- Its own lifecycle
- Its own status

These are treated as black boxes by the combined configuration.

## Step 2: Combined XRD (Facade API)

The combined XRD defines the public API users interact with.

Key principles:

- Group related fields
- Reuse field names from base composites
- Add defaults aggressively
- Expose only what users need

### Example: Combined XRD Schema (Excerpt)

```yaml
spec:
  providerConfigRef:
    type: string
    description: Provider used by all child composites

  volume:
    type: object
    required:
      - pvcName
      - storageClassName
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
    required:
      - vmName
      - hostname
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
  volume:
    ready: boolean
    pvcName: string
  cloudInit:
    ready: boolean
    secretName: string
```

This gives users one place to check readiness.

## Step 3: Pipeline Composition (Orchestration Layer)

Combined configurations MUST use Pipeline mode.

Each child composite is created in its own pipeline step.

### Composition Skeleton

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: harvester-vm
spec:
  compositeTypeRef:
    apiVersion: resources.stuttgart-things.com/v1alpha1
    kind: HarvesterVM
  mode: Pipeline
  pipeline: []
```

## Step 4: One Pipeline Step per Child Composite

### Step A: Create VolumeClaim

```yaml
- step: create-volume-claim
  functionRef:
    name: function-patch-and-transform
  input:
    apiVersion: pt.fn.crossplane.io/v1beta1
    kind: Resources
    resources:
      - name: volume
        base:
          apiVersion: resources.stuttgart-things.com/v1alpha1
          kind: VolumeClaim
        patches:
          - fromFieldPath: spec.providerConfigRef
            toFieldPath: spec.providerConfigRef
            type: FromCompositeFieldPath

          - fromFieldPath: spec.volume.pvcName
            toFieldPath: spec.pvcName
            type: FromCompositeFieldPath

          - fromFieldPath: spec.volume.storageClassName
            toFieldPath: spec.storageClassName
            type: FromCompositeFieldPath

          - fromFieldPath: status.ready
            toFieldPath: status.volume.ready
            type: ToCompositeFieldPath
```

This step:

- Creates a VolumeClaim composite
- Passes only relevant fields
- Pushes readiness back to the parent

### Step B: Create CloudInit

```yaml
- step: create-cloud-init
  functionRef:
    name: function-patch-and-transform
  input:
    apiVersion: pt.fn.crossplane.io/v1beta1
    kind: Resources
    resources:
      - name: cloud-init
        base:
          apiVersion: resources.stuttgart-things.com/v1alpha1
          kind: CloudInit
        patches:
          - fromFieldPath: spec.providerConfigRef
            toFieldPath: spec.providerConfigRef
            type: FromCompositeFieldPath

          - fromFieldPath: spec.cloudInit.vmName
            toFieldPath: spec.vmName
            type: FromCompositeFieldPath

          - fromFieldPath: spec.cloudInit.hostname
            toFieldPath: spec.hostname
            type: FromCompositeFieldPath

          - fromFieldPath: status.secretName
            toFieldPath: status.cloudInit.secretName
            type: ToCompositeFieldPath

          - fromFieldPath: status.ready
            toFieldPath: status.cloudInit.ready
            type: ToCompositeFieldPath
```

## Step 5: Minimal Claim Experience

A well-designed combined configuration allows very small claims:

```yaml
apiVersion: resources.stuttgart-things.com/v1alpha1
kind: HarvesterVM
metadata:
  name: minimal-vm
spec:
  providerConfigRef: kubernetes-provider
  volume:
    pvcName: minimal-vm-disk
    storageClassName: longhorn
  cloudInit:
    vmName: minimal-vm
    hostname: minimal
```

This works because:

- Defaults live in the XRD
- Logic lives in base composites
- The combined composition only wires things together

## Design Rules for Combined Configurations

### DO

- Use Pipeline mode
- Keep steps small and focused
- Aggregate status explicitly
- Treat child composites as black boxes
- Prefer defaults in XRD over transforms
- Name steps by intent

### DO NOT

- Duplicate logic from base composites
- Create managed resources directly
- Pass secrets via claims
- Overload one step with multiple concerns
- Hide behavior in complex transforms

## Mental Model

A combined configuration is not a new implementation. It is an orchestration contract.

If done correctly:

- Base composites remain reusable
- Claims remain simple
- The platform evolves without breaking users

### Next Steps

If you want next, I can:

- Add a decision matrix (single vs combined config)
- Add a diagram-as-code section
- Add naming & versioning rules
- Extract this into a standalone internal guideline

Just say the word 🚀
