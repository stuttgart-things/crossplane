# Best Practices

## API Design

1. **Keep APIs Simple**: Start with minimal required fields
2. **Use Sensible Defaults**: Reduce user configuration burden
3. **Semantic Naming**: Field names should be self-explanatory
4. **Documentation**: Comment every field in XRD schema

## Composition Design

1. **Single Responsibility**: One composition per resource type
2. **Idempotent Operations**: Ensure safe re-application
3. **Error Handling**: Use appropriate conditions and status
4. **Resource Naming**: Predictable, deterministic names

## KCL Module Design

1. **Pure Functions**: No side effects in transformations
2. **Validation**: Validate inputs early
3. **Defaults**: Provide sensible default values
4. **Modularity**: Break complex logic into functions

## Testing

1. **Test Locally First**: Use `crossplane render` before cluster testing
2. **Multiple Scenarios**: Test with different parameter combinations
3. **Edge Cases**: Test minimum, maximum, and invalid values
4. **Integration Tests**: Verify actual resource creation in cluster

## Documentation

1. **README Template**: Use consistent structure across modules
2. **Usage Examples**: Provide complete, working examples
3. **Troubleshooting**: Document common issues and solutions
4. **Architecture Diagrams**: Visual representation of resource flow
