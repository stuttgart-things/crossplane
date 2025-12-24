# Container-Use Environment Workflow

This document describes the standardized workflow for working with container-use environments and merging changes back to the main branch.

## Available Tasks

### 1. Interactive Environment Merge

```bash
task merge-environment
```

**Features:**
- Lists all available environments
- Interactive environment selection
- Automatic checkout, merge, and push
- Status feedback and logging instructions

**Use case:** When you want to see all environments and choose interactively.

### 2. Direct Environment Merge

```bash
task merge-environment-auto ENV_ID=your-env-id
```

**Features:**
- Direct merge with specified environment ID
- Automated workflow without prompts
- Suitable for scripts and CI/CD

**Use case:** When you know the exact environment ID to merge.

**Example:**
```bash
task merge-environment-auto ENV_ID=darling-ostrich
```

### 3. Pull Request Environment Merge

```bash
task merge-environment-pr
```

**Features:**
- Creates Pull Request instead of direct merge
- Interactive environment selection
- Automated PR title and description
- Includes environment logs in PR body

**Use case:** When you want code review before merging to main.

## Workflow Steps

### Standard Direct Merge Flow:

1. **List and Select Environment:**
   ```bash
   task merge-environment
   ```

2. **Review Changes:**
   - Environment is checked out automatically
   - Git status is displayed
   - Changes are merged to main

3. **Push and Complete:**
   - Changes are pushed to origin/main
   - Success message with logging instructions

### Variable-Based Flow:

1. **Direct Merge:**
   ```bash
   task merge-environment-auto ENV_ID=specific-environment
   ```

2. **Automated Processing:**
   - No prompts or user interaction
   - Perfect for scripts and automation

### Pull Request Flow:

1. **Create PR:**
   ```bash
   task merge-environment-pr
   ```

2. **Review and Merge:**
   - PR is created with environment changes
   - Team can review before merging
   - Standard PR workflow applies

## Environment Management

### View Environment Logs:
```bash
container-use log <env-id>
```

### Checkout Environment:
```bash
container-use checkout <env-id>
```

### List All Environments:
```bash
container-use list
```

## Benefits

✅ **Standardized Process**: Consistent workflow across all projects
✅ **Error Prevention**: Automated checkout and merge steps
✅ **Flexibility**: Interactive, direct, and PR-based options
✅ **Logging**: Clear instructions for environment access
✅ **Automation Ready**: Variable-based tasks for CI/CD integration

## Examples

### Quick Development Workflow:
```bash
# Create environment for feature work
container-use create "Implement new feature"

# Work in environment...
# (make changes, test, commit)

# Merge when ready
task merge-environment-auto ENV_ID=my-feature-env
```

### Team Collaboration Workflow:
```bash
# Create environment for feature
container-use create "Add new API endpoint"

# Work in environment...
# (implement, test, document)

# Create PR for team review
task merge-environment-pr
```

### Automated CI/CD Workflow:
```bash
# In CI/CD pipeline
ENV_ID=$(extract_env_id_from_commit)
task merge-environment-auto ENV_ID=$ENV_ID
```

## Best Practices

1. **Always use descriptive environment titles**
2. **Test thoroughly before merging**
3. **Use PR workflow for significant changes**
4. **Clean up environments after successful merge**
5. **Document complex changes in PR descriptions**

## Troubleshooting

### Environment Not Found:
```bash
container-use list  # Check available environments
```

### Merge Conflicts:
```bash
container-use checkout <env-id>
git status  # Review conflicts
# Resolve conflicts manually
task merge-environment-auto ENV_ID=<env-id>
```

### Failed Push:
```bash
git pull origin main  # Update main branch
task merge-environment-auto ENV_ID=<env-id>  # Retry merge
```
