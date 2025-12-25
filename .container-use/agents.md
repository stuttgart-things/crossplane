# Crossplane Configuration Agents

## Overview

This document defines the standard structure and patterns for creating Crossplane configuration modules at Stuttgart-Things. Each configuration acts as an autonomous agent that provisions and manages infrastructure resources through declarative APIs.

---

## Table of Contents

1. **[Core Concepts & Architecture](01-core-concepts.md)** - Principles and folder structure
2. **[Component Specifications](02-component-specifications.md)** - XRD, Composition, and examples
3. **[Development Workflow](03-development-workflow.md)** - Design, implementation, testing, documentation
4. **[KCL Module Integration](04-kcl-module-integration.md)** - OCI registry and module patterns
5. **[Testing Strategy](05-testing-strategy.md)** - Local and cluster testing
6. **[Common Patterns](06-common-patterns.md)** - Reusable patterns and examples
7. **[Troubleshooting](07-troubleshooting.md)** - Common issues and debug commands
8. **[Best Practices](08-best-practices.md)** - Design and implementation guidelines
9. **[Module Registry & References](09-references.md)** - Available modules and links
10. **[Combined Configurations](10-combined-configurations.md)** - Composition of compositions pattern
11. **[Decisions](11-decisions.md)** - Design decisions and rationale
12. **[Standards](12-standards.md)** - Standards and conventions
13. **[Tasks](13-tasks.md)** - Tasks and workflows

---

## Quick Start

To create a new Crossplane configuration:

1. Start with **[Core Concepts](01-core-concepts.md)** to understand the structure
2. Follow **[Component Specifications](02-component-specifications.md)** to create your files
3. Use **[Development Workflow](03-development-workflow.md)** for the implementation phases
4. Apply **[Best Practices](08-best-practices.md)** throughout
5. Test with **[Testing Strategy](05-testing-strategy.md)**
6. Refer to **[Common Patterns](06-common-patterns.md)** for reusable solutions
7. Check **[Troubleshooting](07-troubleshooting.md)** if issues arise

---

## Module Types

### Single Resource Configuration

A configuration that provides a single composite resource type:

- Use when one resource logically groups related managed resources
- Examples: VCluster, Database, VM

### Combined Configuration (Composition of Compositions)

A configuration that orchestrates multiple existing composites:

- Use when a higher-level resource should compose lower-level resources
- Examples: HarvesterVM (combines VolumeClaim + CloudInit)
- See **[Combined Configurations](10-combined-configurations.md)** for detailed guide

---

## Contributing

Please follow the guidelines in **[Module Registry & References](09-references.md)** when contributing new configurations.

For detailed implementation guidance, see **[Development Workflow](03-development-workflow.md)**.
