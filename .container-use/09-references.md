# Module Registry & References

## Module Registry

Stuttgart-Things maintains KCL modules at:

```
ghcr.io/stuttgart-things/xplane-{module}:{version}
```

**Available Modules**:
- `xplane-vcluster`: VCluster deployment with connection secrets
- `xplane-vm`: Virtual machine provisioning
- `xplane-database`: Database instance management
- *(Add your modules here)*

## References

- **Crossplane Documentation**: https://docs.crossplane.io
- **KCL Language Guide**: https://kcl-lang.io/docs
- **Stuttgart-Things GitHub**: https://github.com/stuttgart-things
- **OCI Registry**: https://github.com/orgs/stuttgart-things/packages

## Contribution Guidelines

1. **Fork** the repository
2. **Create** a feature branch
3. **Test** locally with `crossplane render`
4. **Document** all changes in README.md
5. **Submit** pull request with clear description

## Version History

- **v1.0.0** (2024-12): Initial agent specification for Crossplane configurations
- **v1.1.0** (2025-01): Added KCL function patterns and testing guidelines
