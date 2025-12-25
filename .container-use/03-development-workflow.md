# Development Workflow

## Phase 1: Design

1. **Define the API contract** in `apis/definition.yaml`
   - What resources will users create?
   - What parameters are required vs optional?
   - What's the user experience?

2. **Plan the KCL module structure**
   - What managed resources are needed?
   - How do parameters transform to resources?
   - What connection secrets are exposed?

## Phase 2: Implementation

1. **Create the KCL module** (separate repository/module)
   ```
   xplane-{resource}/
   ├── main.k          # Primary composition logic
   ├── kcl.mod         # Module dependencies
   └── README.md       # Module documentation
   ```

2. **Package and publish** to OCI registry
   ```bash
   kcl mod push oci://ghcr.io/stuttgart-things/xplane-{resource}:{version}
   ```

3. **Create the Crossplane configuration**
   - Write XRD in `apis/definition.yaml`
   - Write Composition in `apis/composition.yaml`
   - Write Configuration in `crossplane.yaml`
   - Create example in `examples/claim.yaml`
   - Add functions in `examples/functions.yaml`

## Phase 3: Testing

1. **Local testing** with crossplane CLI:
   ```bash
   # Test basic rendering
   crossplane render examples/claim.yaml \
                      apis/composition.yaml \
                      examples/functions.yaml

   # Verify output
   # - Check resource count
   # - Validate resource types
   # - Inspect generated manifests
   ```

2. **Integration testing** in cluster:
   ```bash
   # Install configuration
   kubectl apply -f crossplane.yaml
   kubectl apply -f apis/

   # Deploy claim
   kubectl apply -f examples/claim.yaml

   # Monitor status
   kubectl get x{resources} -w
   kubectl describe x{resource} {name}
   ```

3. **Validation checklist**:
   - [ ] XRD installs successfully
   - [ ] Composition references correct XRD
   - [ ] KCL module resolves from OCI registry
   - [ ] Claim creates expected resources
   - [ ] Connection secrets are generated (if applicable)
   - [ ] Resources reach ready state
   - [ ] No errors in crossplane logs

## Phase 4: Documentation

1. **README.md** must include:
   - Overview and features
   - Architecture diagram
   - Installation instructions
   - Configuration options table
   - Usage examples
   - Troubleshooting section

2. **Inline documentation**:
   - Comment complex XRD fields
   - Document composition pipeline steps
   - Explain parameter defaults
