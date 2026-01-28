# Automation Scripts

Detailed automation script integration for pre-deployment validation.

## Pre-Flight Check Script Integration

The automated validation script at `scripts/pre-flight-check.sh` provides comprehensive checks across 8 phases:

1. File Existence (3 core files)
2. Filename Consistency (styles.css validation)
3. Script Permissions (auto-fix capability)
4. Network Connectivity (GitHub and git remote)
5. Git Status (clean working directory)
6. Cache Version (parameter presence)
7. Web Server Status (nginx)
8. Disk Space (usage threshold)

**Usage:**
```bash
# Run from project root
./scripts/pre-flight-check.sh

# Exit codes:
# 0 = All checks passed (ready to deploy)
# 1 = Critical failures (deployment blocked)
```

## Integration with Deployment Workflow

**Option 1: Manual Execution**
```bash
./scripts/pre-flight-check.sh && sudo ./deploy-and-restart.sh
```

**Option 2: Add to Deploy Script**
Add at beginning of deploy-and-restart.sh:
```bash
./scripts/pre-flight-check.sh || exit 1
```

## Custom Validation Scripts

Create project-specific validation by extending the base script:

```bash
#!/bin/bash
# custom-pre-deploy-check.sh

# Source base validation
source ./scripts/pre-flight-check.sh

# Add custom checks
echo "Running custom validations..."

# Example: Check environment variables
if [ -z "$API_ENDPOINT" ]; then
    echo "✗ FAIL: API_ENDPOINT not set"
    exit 1
fi

# Example: Verify configuration files
if [ ! -f "config/production.json" ]; then
    echo "✗ FAIL: Production config missing"
    exit 1
fi

echo "Custom validations passed!"
```

## Git Hooks Integration

### Pre-commit Hook (`.git/hooks/pre-commit`)
```bash
#!/bin/bash
# Run pre-flight checks before commit
./scripts/pre-flight-check.sh
if [ $? -ne 0 ]; then
    echo "Commit blocked: Pre-deployment checks failed"
    exit 1
fi
```

### Pre-push Hook (`.git/hooks/pre-push`)
```bash
#!/bin/bash
# Validate before pushing to remote
echo "Running pre-push validation..."
./scripts/pre-flight-check.sh
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Pre-deployment Validation
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run pre-flight checks
        run: ./scripts/pre-flight-check.sh
```

### Jenkins Pipeline Example
```groovy
pipeline {
    agent any
    stages {
        stage('Pre-deployment Validation') {
            steps {
                sh './scripts/pre-flight-check.sh'
            }
        }
    }
}
```
