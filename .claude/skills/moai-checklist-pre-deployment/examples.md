# Pre-Deployment Checklist - Automation Examples

This file contains working automation script examples for pre-deployment validation.

## Table of Contents

1. [Basic Validation Scripts](#basic-validation-scripts)
2. [Advanced Multi-Phase Validation](#advanced-multi-phase-validation)
3. [Platform-Specific Scripts](#platform-specific-scripts)
4. [CI/CD Integration Examples](#cicd-integration-examples)

---

## Basic Validation Scripts

### Quick File Check

```bash
#!/bin/bash
# quick-file-check.sh
# Fast validation of core files before deployment

echo "Checking core files..."

CORE_FILES=(
    "forms-interface/index.html"
    "forms-interface/script.js"
    "forms-interface/styles.css"
)

ALL_EXIST=true
for file in "${CORE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file"
    else
        echo "✗ $file NOT FOUND"
        ALL_EXIST=false
    fi
done

if [ "$ALL_EXIST" = true ]; then
    echo "All files present. Ready to proceed."
    exit 0
else
    echo "Missing files detected. Deployment blocked."
    exit 1
fi
```

### Permission Fix Script

```bash
#!/bin/bash
# fix-permissions.sh
# Automatically fix execution permissions for deployment scripts

echo "Fixing script permissions..."

SCRIPTS=(
    "deploy-and-restart.sh"
    "setup-raspberry-pi.sh"
)

FIXED_COUNT=0
for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo "✓ $script already executable"
        else
            chmod +x "$script"
            echo "✓ Fixed: $script"
            ((FIXED_COUNT++))
        fi
    else
        echo "⚠ $script not found"
    fi
done

echo "Total permissions fixed: $FIXED_COUNT"
exit 0
```

### Network Connectivity Test

```bash
#!/bin/bash
# test-network.sh
# Verify network connectivity before deployment

echo "Testing network connectivity..."

# Test GitHub connectivity
if ping -c 1 -W 2 github.com &> /dev/null; then
    echo "✓ GitHub reachable"
else
    echo "✗ GitHub unreachable"
    exit 1
fi

# Test git remote access
if git ls-remote origin &> /dev/null; then
    echo "✓ Git remote accessible"
else
    echo "✗ Git remote inaccessible"
    exit 1
fi

# Test DNS resolution
if nslookup github.com &> /dev/null; then
    echo "✓ DNS resolution working"
else
    echo "✗ DNS resolution failed"
    exit 1
fi

echo "All network tests passed."
exit 0
```

---

## Advanced Multi-Phase Validation

### Complete Pre-Deployment Pipeline

```bash
#!/bin/bash
# pre-deploy-pipeline.sh
# Complete validation pipeline with rollback capability

set -e
set -u

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Phase tracking
PHASE=1

log_phase() {
    echo -e "\n${GREEN}=== Phase $PHASE: $1 ===${NC}"
    ((PHASE++))
}

log_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# Phase 1: File Validation
log_phase "File Existence Validation"
if ! ./scripts/pre-flight-check.sh; then
    log_error "File validation failed"
    exit 1
fi

# Phase 2: Git Status Check
log_phase "Git Status Validation"
if ! git diff --quiet || ! git diff --cached --quiet; then
    log_warning "Uncommitted changes detected"
    read -p "Stash changes and continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git stash push -u -m "auto-stash-$(date +%Y%m%d_%H%M%S)"
    else
        log_error "Deployment aborted by user"
        exit 1
    fi
fi

# Phase 3: Network Verification
log_phase "Network Connectivity"
if ! ping -c 1 github.com &> /dev/null; then
    log_error "Cannot reach GitHub"
    exit 1
fi

# Phase 4: Deployment Execution
log_phase "Deployment Execution"
if ! sudo ./deploy-and-restart.sh; then
    log_error "Deployment failed"
    read -p "Attempt rollback? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_phase "Rollback Execution"
        LATEST_BACKUP=$(ls -dt /var/www/html/forms.backup.* 2>/dev/null | head -1)
        if [ -n "$LATEST_BACKUP" ]; then
            sudo rm /var/www/html/forms
            sudo ln -sf "$LATEST_BACKUP" /var/www/html/forms
            echo "Rollback complete"
        else
            log_error "No backup found for rollback"
            exit 1
        fi
    else
        exit 1
    fi
fi

# Phase 5: Post-Deployment Verification
log_phase "Post-Deployment Verification"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/forms/index.html)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Deployment successful (HTTP $HTTP_CODE)"
else
    log_error "Deployment verification failed (HTTP $HTTP_CODE)"
    exit 1
fi

echo -e "\n${GREEN}=== All Phases Complete ===${NC}"
exit 0
```

### Staged Deployment with Validation

```bash
#!/bin/bash
# staged-deployment.sh
# Deploy with validation at each stage

deploy_stage() {
    local stage_name=$1
    local stage_command=$2

    echo "Executing stage: $stage_name"

    if eval "$stage_command"; then
        echo "✓ Stage passed: $stage_name"
        return 0
    else
        echo "✗ Stage failed: $stage_name"
        return 1
    fi
}

# Define deployment stages
declare -a STAGES=(
    "Pre-flight validation:./scripts/pre-flight-check.sh"
    "Git synchronization:git fetch origin main && git reset --hard origin/main"
    "Permission fix:chmod +x deploy-and-restart.sh"
    "Deployment execution:sudo ./deploy-and-restart.sh"
    "HTTP verification:curl -f http://localhost/forms/index.html"
)

# Execute stages sequentially
for stage in "${STAGES[@]}"; do
    IFS=':' read -r name command <<< "$stage"

    if ! deploy_stage "$name" "$command"; then
        echo "Deployment failed at stage: $name"
        echo "All previous stages completed successfully"
        exit 1
    fi
done

echo "All deployment stages completed successfully"
exit 0
```

---

## Platform-Specific Scripts

### Windows Pre-Commit Validation (PowerShell)

```powershell
# pre-commit-validation.ps1
# Windows-side validation before committing changes

Write-Host "=== Pre-Commit Validation ===" -ForegroundColor Cyan

# Check 1: Core file existence
Write-Host "`nChecking core files..." -ForegroundColor Yellow
$files = @(
    "forms-interface/index.html",
    "forms-interface/script.js",
    "forms-interface/styles.css"
)

$allExist = $true
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "✓ $file" -ForegroundColor Green
    } else {
        Write-Host "✗ $file NOT FOUND" -ForegroundColor Red
        $allExist = $false
    }
}

if (-not $allExist) {
    Write-Host "`nValidation failed: Missing files" -ForegroundColor Red
    exit 1
}

# Check 2: Git status
Write-Host "`nChecking git status..." -ForegroundColor Yellow
$status = git status --porcelain
if ($status) {
    Write-Host "Uncommitted changes:" -ForegroundColor Yellow
    Write-Host $status
    $confirm = Read-Host "`nProceed with commit? (y/n)"
    if ($confirm -ne 'y') {
        Write-Host "Commit cancelled" -ForegroundColor Yellow
        exit 1
    }
}

# Check 3: Cache version
Write-Host "`nChecking cache version..." -ForegroundColor Yellow
if (Test-Path "forms-interface/index.html") {
    $version = Select-String -Path "forms-interface/index.html" -Pattern 'script\.js\?v=' |
               Select-Object -First 1
    Write-Host "Cache version: $version" -ForegroundColor Green
}

Write-Host "`n✓ All validations passed" -ForegroundColor Green
exit 0
```

### Raspberry Pi Deployment Script (Bash)

```bash
#!/bin/bash
# raspberry-pi-deploy.sh
# Complete deployment automation for Raspberry Pi

set -e

echo "=== Raspberry Pi Deployment ==="

# Step 1: Pull latest changes
echo "Pulling latest changes..."
if ! git pull origin main; then
    echo "Git pull failed, attempting stash + reset..."
    git stash push -u -m "auto-stash-$(date +%Y%m%d_%H%M%S)"
    git fetch origin main
    git reset --hard origin/main
fi

# Step 2: Run pre-flight checks
echo "Running pre-flight checks..."
if ! ./scripts/pre-flight-check.sh; then
    echo "Pre-flight checks failed. Deployment aborted."
    exit 1
fi

# Step 3: Fix permissions
echo "Fixing permissions..."
chmod +x deploy-and-restart.sh

# Step 4: Execute deployment
echo "Executing deployment..."
if ! sudo ./deploy-and-restart.sh; then
    echo "Deployment failed. Check logs for details."
    tail -n 50 $HOME/mcp-agent-deploy.log
    exit 1
fi

# Step 5: Verify deployment
echo "Verifying deployment..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/forms/index.html)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Deployment successful (HTTP $HTTP_CODE)"
else
    echo "✗ Deployment verification failed (HTTP $HTTP_CODE)"
    exit 1
fi

# Step 6: Report version
VERSION=$(grep -oP 'script\.js\?v=\K[0-9.]+' /var/www/html/forms/index.html)
echo "Deployed version: $VERSION"

echo "=== Deployment Complete ==="
exit 0
```

---

## CI/CD Integration Examples

### Git Pre-Commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit
# Automatically run validation before commit

echo "Running pre-commit validation..."

# Run pre-flight checks
if [ -f "./scripts/pre-flight-check.sh" ]; then
    ./scripts/pre-flight-check.sh
    if [ $? -ne 0 ]; then
        echo "Commit blocked: Pre-deployment checks failed"
        exit 1
    fi
else
    echo "Warning: pre-flight-check.sh not found"
fi

# Check for filename mismatches
if find forms-interface -name "style.css" | grep -q .; then
    echo "Commit blocked: Found style.css (should be styles.css)"
    exit 1
fi

echo "Pre-commit validation passed"
exit 0
```

### Git Pre-Push Hook

```bash
#!/bin/bash
# .git/hooks/pre-push
# Validate before pushing to remote

echo "Running pre-push validation..."

# Ensure all files are committed
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Push blocked: Uncommitted changes detected"
    echo "Please commit or stash changes first"
    exit 1
fi

# Verify cache version is set
if ! grep -q 'script\.js?v=' forms-interface/index.html; then
    echo "Warning: Cache version parameter not found in index.html"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Pre-push validation passed"
exit 0
```

### GitHub Actions Workflow

```yaml
# .github/workflows/deployment-validation.yml
name: Deployment Validation

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  validate-deployment:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Validate file structure
      run: |
        echo "Checking core files..."
        test -f forms-interface/index.html || exit 1
        test -f forms-interface/script.js || exit 1
        test -f forms-interface/styles.css || exit 1
        echo "✓ All core files present"

    - name: Check filename consistency
      run: |
        if find forms-interface -name "style.css" | grep -q .; then
          echo "✗ Found style.css (should be styles.css)"
          exit 1
        fi
        echo "✓ Filename consistency verified"

    - name: Validate HTML references
      run: |
        if grep -q "style\.css" forms-interface/index.html; then
          echo "✗ Found style.css reference in HTML"
          exit 1
        fi
        echo "✓ HTML references validated"

    - name: Check cache version
      run: |
        if ! grep -q 'script\.js?v=' forms-interface/index.html; then
          echo "Warning: No cache version parameter found"
        fi
        VERSION=$(grep -oP 'script\.js\?v=\K[0-9.]+' forms-interface/index.html)
        echo "Cache version: $VERSION"

    - name: Validate script syntax
      run: |
        bash -n deploy-and-restart.sh
        bash -n scripts/pre-flight-check.sh
        echo "✓ Script syntax validated"
```

### Jenkins Pipeline Example

```groovy
// Jenkinsfile
pipeline {
    agent any

    stages {
        stage('Pre-Deployment Validation') {
            steps {
                sh '''
                    echo "Running pre-flight checks..."
                    ./scripts/pre-flight-check.sh
                '''
            }
        }

        stage('File Structure Check') {
            steps {
                sh '''
                    echo "Validating file structure..."
                    test -f forms-interface/index.html
                    test -f forms-interface/script.js
                    test -f forms-interface/styles.css
                '''
            }
        }

        stage('Filename Consistency') {
            steps {
                sh '''
                    if find forms-interface -name "style.css" | grep -q .; then
                        echo "ERROR: Found style.css (should be styles.css)"
                        exit 1
                    fi
                '''
            }
        }

        stage('Deployment') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    echo "Deploying to production..."
                    chmod +x deploy-and-restart.sh
                    sudo ./deploy-and-restart.sh
                '''
            }
        }

        stage('Post-Deployment Verification') {
            steps {
                sh '''
                    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/forms/index.html)
                    if [ "$HTTP_CODE" != "200" ]; then
                        echo "Deployment verification failed (HTTP $HTTP_CODE)"
                        exit 1
                    fi
                    echo "Deployment verified successfully"
                '''
            }
        }
    }

    post {
        failure {
            emailext (
                subject: "Deployment Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Deployment failed. Check console output for details.",
                to: "dev-team@example.com"
            )
        }
        success {
            echo "Deployment completed successfully"
        }
    }
}
```

---

## Usage Examples

### Basic Usage

```bash
# Run pre-flight check before deployment
./scripts/pre-flight-check.sh

# Deploy only if checks pass
./scripts/pre-flight-check.sh && sudo ./deploy-and-restart.sh
```

### Advanced Usage

```bash
# Run with explicit error handling
set -e
./scripts/pre-flight-check.sh
sudo ./deploy-and-restart.sh
./scripts/post-deploy-check.sh

# Run in pipeline mode
bash pre-deploy-pipeline.sh

# Run staged deployment
bash staged-deployment.sh
```

### CI/CD Integration

```bash
# Git hooks (install manually)
cp .git/hooks/pre-commit .git/hooks/pre-commit.backup
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
./scripts/pre-flight-check.sh || exit 1
EOF
chmod +x .git/hooks/pre-commit

# Or use staged deployment script in CI pipeline
bash staged-deployment.sh
```

---

## Troubleshooting Examples

### Debug Mode

```bash
# Run with verbose output
bash -x ./scripts/pre-flight-check.sh

# Check which shell is executing
echo $SHELL

# Verify script line endings
file ./scripts/pre-flight-check.sh
# Should say: ASCII text executable
# If says: CRLF line terminators, run: dos2unix pre-flight-check.sh
```

### Manual Rollback

```bash
# Find latest backup
ls -lt /var/www/html/forms.backup.*

# Rollback to specific backup
sudo rm /var/www/html/forms
sudo ln -s /var/www/html/forms.backup.20260128_123456 /var/www/html/forms

# Verify rollback
curl -I http://localhost/forms/index.html
```

### Log Analysis

```bash
# View deployment logs
tail -f $HOME/mcp-agent-deploy.log

# Search for errors
grep -i "error\|fail\|permission denied" $HOME/mcp-agent-deploy.log

# Extract last 50 lines on failure
tail -n 50 $HOME/mcp-agent-deploy.log
```

---

For more information, see:
- SKILL.md - Main skill documentation
- reference.md - External resources and documentation
- docs/PRE_DEPLOYMENT_CHECKLIST.md - Complete checklist
- docs/DEVELOPMENT_METHODOLOGY.md - Development methodology guide
