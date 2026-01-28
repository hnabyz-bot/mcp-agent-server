# Advanced Implementation

Advanced cross-platform patterns and troubleshooting for deployment validation.

## Cross-Platform Development Patterns

### Environment-Specific Validations

**Windows Development Environment:**
- Case-insensitive filesystem can hide filename mismatches
- Use Git Bash for Linux-compatible command validation
- Verify line endings (CRLF vs LF) with `git config core.autocrlf`

**Linux Deployment Environment:**
- Case-sensitive filesystem reveals filename inconsistencies
- Execution permissions must be explicitly set
- systemd-managed services (nginx) require specific commands

### Defensive Programming Techniques

**Always validate before file operations:**
```bash
# Bad: Assume file exists
chmod 444 forms-interface/styles.css

# Good: Check first, then act
if [ -f "forms-interface/styles.css" ]; then
    chmod 444 forms-interface/styles.css"
else
    echo "Error: File not found"
    exit 1
fi
```

**Use explicit error handling:**
```bash
# Enable error exit
set -e

# Trap errors for cleanup
trap 'rollback_on_error' ERR

rollback_on_error() {
    echo "Deployment failed. Rolling back..."
    # Rollback logic here
    exit 1
}
```

## Integration with Deployment Workflows

### Standard Development Workflow
```
Windows Development
    ↓
1. Code changes
2. Pre-commit validation (file checks)
3. Git commit
4. windows-deploy.bat (increment cache version)
    ↓
Git Push to GitHub
    ↓
Raspberry Pi Deployment
    ↓
1. git pull
2. Pre-deploy validation (pre-flight-check.sh)
3. sudo ./deploy-and-restart.sh
4. Post-deploy verification (HTTP tests, browser check)
```

## Troubleshooting Methodology

### Systematic Problem Diagnosis

1. **Identify Failure Point:** Which phase failed? (commit, deploy, post-deploy)
2. **Check Logs:** Review deployment logs for error messages
3. **Validate Environment:** Confirm correct environment (Windows vs Raspberry Pi)
4. **Run Diagnostics:** Execute pre-flight check script
5. **Consult Documentation:** Check PRE_DEPLOYMENT_CHECKLIST.md for known issues
6. **Document Resolution:** Record problem and solution for future reference

### Log Analysis
```bash
# View deployment logs
tail -f $HOME/mcp-agent-deploy.log

# Search for errors in logs
grep -i "error\|fail\|permission denied" $HOME/mcp-agent-deploy.log
```

## Rollback Procedures

### Automatic Rollback
Built into deploy-and-restart.sh:
- Triggered by script failure
- Restores previous backup from `/var/www/html/forms.backup.*`
- Maintains service availability

### Manual Rollback
```bash
# Identify latest backup
LATEST_BACKUP=$(ls -dt /var/www/html/forms.backup.* 2>/dev/null | head -1)

# Verify backup contents
ls -la "$LATEST_BACKUP"

# Execute rollback
sudo rm /var/www/html/forms
sudo ln -sf "$LATEST_BACKUP" /var/www/html/forms

# Confirm rollback
ls -la /var/www/html/forms
curl -I http://localhost/forms/index.html
```

## Quality Gates and Best Practices

### Pre-Deployment Quality Gates

**Mandatory checks (must pass):**
- All core files exist (index.html, script.js, styles.css)
- No filename mismatches (styles.css not style.css)
- Script execution permissions set (chmod +x)
- Network connectivity confirmed (GitHub accessible)
- Git repository clean (no uncommitted changes)

**Recommended checks (warnings):**
- Cache version parameter present
- nginx configuration valid
- Disk space below 90%

### Development Principles

1. **Validation First:** Always validate before deploying
2. **Automated Verification:** Use scripts to eliminate human error
3. **Incremental Deployment:** Deploy in stages with validation between each
4. **Fail Fast:** Stop immediately on critical failures
5. **Document Everything:** Record problems and solutions for knowledge retention

### Success Criteria

Deployment is successful when:
- Pre-flight check: All critical checks pass
- Deployment execution: Script completes without errors
- Post-deploy verification: HTTP 200 responses for all resources
- Browser validation: Changes visible in production
- No rollbacks required within 24 hours
