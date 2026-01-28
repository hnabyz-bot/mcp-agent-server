# Integration Patterns

Integration patterns for pre-deployment validation with development workflows.

## Works Well With

### Complementary Skills
- **moai-workflow-ddd** - Domain-driven development methodology for deployment planning
- **moai-platform-devops** - DevOps platform integration patterns
- **moai-foundation-quality** - TRUST 5 quality validation framework
- **moai-pattern-cross-platform** - Cross-platform development patterns

### Related Documentation
- `docs/PRE_DEPLOYMENT_CHECKLIST.md` - Complete pre-deployment checklist
- `docs/DEVELOPMENT_METHODOLOGY.md` - Development methodology and failure analysis
- `scripts/pre-flight-check.sh` - Automated validation script
- `scripts/deploy-and-restart.sh` - Main deployment script with rollback

## Integration Patterns by Workflow

### With DDD Workflow

**Plan Phase:**
- Define deployment validation requirements
- Identify cross-platform considerations
- Document success criteria

**Run Phase:**
- Execute deployment with validation checks
- Run pre-flight checks before deployment
- Verify post-deployment success

**Sync Phase:**
- Document deployment outcomes
- Record lessons learned
- Update checklists based on findings

### With Quality Gates

**Pre-deployment:**
1. Run validation checks
2. Verify all mandatory checks pass
3. Block deployment if critical failures detected

**Deployment:**
1. Execute only if all checks pass
2. Monitor deployment execution
3. Auto-rollback on failure

**Post-deployment:**
1. Verify deployment success criteria
2. Record any issues and resolutions
3. Update quality metrics

### With CI/CD Pipelines

**GitHub Actions Integration:**
```yaml
name: Deployment Pipeline
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Pre-deployment Validation
        run: ./scripts/pre-flight-check.sh

      - name: Deploy
        if: success()
        run: ./scripts/deploy-and-restart.sh

      - name: Post-deployment Verification
        if: success()
        run: ./scripts/post-deploy-check.sh
```

**Jenkins Pipeline Integration:**
```groovy
pipeline {
    agent any
    stages {
        stage('Pre-deployment') {
            steps {
                sh './scripts/pre-flight-check.sh'
            }
        }
        stage('Deploy') {
            steps {
                sh './scripts/deploy-and-restart.sh'
            }
        }
        stage('Post-deployment') {
            steps {
                sh './scripts/post-deploy-check.sh'
            }
        }
    }
    post {
        failure {
            mail to: 'team@example.com',
                 subject: 'Deployment Failed',
                 body: 'Check deployment logs for details.'
        }
    }
}
```

### With Git Hooks

**Pre-commit Hook:**
```bash
#!/bin/bash
# .git/hooks/pre-commit
./scripts/pre-flight-check.sh || {
    echo "❌ Pre-deployment checks failed. Commit blocked."
    echo "Fix issues and try again."
    exit 1
}
```

**Pre-push Hook:**
```bash
#!/bin/bash
# .git/hooks/pre-push
echo "🔍 Running pre-push validation..."
./scripts/pre-flight-check.sh || {
    echo "❌ Validation failed. Push blocked."
    exit 1
}
echo "✅ All checks passed. Proceeding with push."
```

**Post-merge Hook:**
```bash
#!/bin/bash
# .git/hooks/post-merge
echo "🔄 Restoring execution permissions..."
chmod +x deploy-and-restart.sh
chmod +x setup-raspberry-pi.sh
echo "✅ Permissions restored."
```

## Deployment Workflow Integration

### Complete Deployment Pipeline

```
┌─────────────────────────────────────────┐
│     Windows Development Environment     │
└─────────────────────────────────────────┘
                  ↓
        1. Code Changes
                  ↓
        2. Pre-commit Validation
           - File existence checks
           - Filename consistency
           - Git status verification
                  ↓
        3. Git Commit
                  ↓
        4. windows-deploy.bat
           - Increment cache version
           - Push to GitHub
                  ↓
┌─────────────────────────────────────────┐
│         GitHub Remote Repository        │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│    Raspberry Pi Deployment Environment  │
└─────────────────────────────────────────┘
                  ↓
        5. git pull
                  ↓
        6. Pre-deploy Validation
           - Run pre-flight-check.sh
           - Verify all checks pass
                  ↓
        7. Deploy
           - sudo ./deploy-and-restart.sh
           - Automatic rollback on failure
                  ↓
        8. Post-deploy Verification
           - HTTP access tests
           - File permissions check
           - Cache version confirmation
                  ↓
        9. Browser Validation
           - Manual verification
           - Cache refresh if needed
                  ↓
        ✅ Deployment Complete
```

## Error Recovery Integration

### Automatic Error Recovery
1. Pre-flight check detects issues → Block deployment
2. Deployment script fails → Auto-rollback to previous version
3. Post-deploy check fails → Manual rollback with diagnostics

### Manual Error Recovery
1. Identify failure point from logs
2. Run diagnostic pre-flight check
3. Apply fix based on failure pattern
4. Re-run validation
5. Retry deployment

## Documentation Updates

### After Each Deployment
1. Record deployment outcome in session log
2. Document any new failure patterns discovered
3. Update checklists if new issues found
4. Share lessons learned with team

### Continuous Improvement
1. Review deployment logs weekly
2. Identify recurring issues
3. Update automation scripts to prevent recurrence
4. Refine checklists based on actual failures
