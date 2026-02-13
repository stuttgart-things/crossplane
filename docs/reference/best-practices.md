# Best Practices

## API Design

1. **Keep APIs simple** — Start with minimal required fields, add more as needed
2. **Use sensible defaults** — Reduce user configuration burden; a minimal claim should work
3. **Semantic naming** — Field names should be self-explanatory (`deploymentNamespace`, not `ns`)
4. **Document fields** — Add `description` to every field in the XRD schema
5. **Group related fields** — Use nested objects (e.g. `targetCluster.name`, `tokenSecret.key`)

## Composition Design

1. **Single responsibility** — One composition per resource type or deployment
2. **Idempotent operations** — Templates should produce the same output for the same input
3. **Deterministic naming** — Use `setResourceNameAnnotation` with predictable names
4. **Always include auto-ready** — Add `function-auto-ready` as the final pipeline step
5. **Report status** — Include a status resource at the end of every Go template

## Go Template Guidelines

1. **Extract variables early** — Define all `$spec` lookups at the top of the template
2. **Always provide defaults** — Use `| default "value"` for every variable
3. **Keep templates readable** — Use whitespace trimming (`{{-` / `-}}`) consistently
4. **One resource per YAML document** — Separate resources with `---`
5. **Use comments for complex logic** — Explain non-obvious template expressions

```gotemplate
{{- /* Good: extract and default at the top */ -}}
{{- $spec := .observed.composite.resource.spec -}}
{{- $provider := $spec.targetCluster.name | default "in-cluster" -}}
{{- $namespace := $spec.deploymentNamespace | default "default" -}}
{{- $version := $spec.version | default "1.0.0" -}}
```

## Testing

1. **Test locally first** — Use `crossplane render` before deploying to a cluster
2. **Multiple scenarios** — Test with different parameter combinations
3. **Minimal claims** — Verify that defaults work with a claim containing only required fields
4. **Validate output** — Check rendered YAML for correct resource types, names, and values

## File Organization

1. **One XRD per configuration** — Keep each configuration focused on a single resource type
2. **Compositions in `compositions/`** — Not in `apis/`
3. **Examples must use XR kind** — Not the claim kind (required for `crossplane render`)
4. **Include a README** — With the render command for quick validation

## Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Configuration directory | lowercase, hyphenated | `github-controller` |
| XRD metadata name | `x<plural>.resources.stuttgart-things.com` | `xgithubcontrollers.resources.stuttgart-things.com` |
| Composition name | lowercase, hyphenated | `github-controller` |
| Composition file | `compositions/<name>.yaml` | `compositions/github-controller.yaml` |
| Pipeline step (deploy) | `deploy-<name>` | `deploy-github-controller` |
| Pipeline step (ready) | `automatically-detect-ready-composed-resources` | — |
| Example XR file | `examples/<name>.yaml` | `examples/github-controller.yaml` |
