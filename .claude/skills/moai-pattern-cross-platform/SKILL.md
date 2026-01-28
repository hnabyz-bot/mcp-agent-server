---
name: moai-pattern-cross-platform
description: Handle Windows ↔ Linux filesystem differences for cross-platform development. Use when developing across Windows and Linux, dealing with file operations, deployment scripts, or environment-specific code. Covers case sensitivity, path separators, line endings, permissions, and symlinks.
version: 1.0.0
category: pattern
modularized: true
user-invocable: false
status: active
updated: 2026-01-28
tags: ["cross-platform", "windows", "linux", "filesystem", "deployment", "portability"]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
related-skills: moai-checklist-pre-deployment, moai-workflow-ddd, moai-foundation-quality
triggers:
  keywords: ["windows", "linux", "cross-platform", "filesystem", "case-sensitive", "path", "environment", "portability"]
  phases: ["plan", "run"]
  agents: ["expert-backend", "expert-devops", "expert-frontend"]
progressive_disclosure:
  enabled: true
  level1_tokens: 100
  level2_tokens: 5000
---

# Cross-platform Development Patterns

Handle Windows ↔ Linux filesystem differences and environment-specific challenges in cross-platform development.

---

## Quick Reference (30 seconds)

### Critical Platform Differences

**File System:**
- **Case Sensitivity:** Windows case-insensitive, Linux case-sensitive
- **Path Separators:** Windows backslash `\`, Linux forward slash `/`
- **Line Endings:** Windows CRLF `\r\n`, Linux LF `\n`

**Permissions:**
- **Executables:** Windows extension-based, Linux execute bit `chmod +x`
- **Symlinks:** Different creation and behavior patterns

### Immediate Action Items

**Before Committing:**
```bash
# Verify actual filenames (case-sensitive)
ls -la path/to/files/
git status --porcelain
```

**Before Deploying:**
```bash
# Check executable permissions
ls -la *.sh
chmod +x deploy-and-restart.sh

# Verify file references match actual names
grep -r "filename" --include="*.{sh,html,js,py}"
```

### Common Failure Patterns

| Pattern | Symptom | Quick Fix |
|---------|---------|-----------|
| Case mismatch | `No such file or directory` | Use `ls -la` to verify exact case |
| Lost permissions | `Permission denied` | Run `chmod +x script.sh` after git pull |
| Path issues | Script fails on one platform | Use `pathlib` (Python) or `path.join` (Node.js) |
| Line ending errors | Scripts fail to execute | Run `dos2unix script.sh` on Linux |

---

## Implementation Guide (5 minutes)

### File System Differences

#### Case Sensitivity

**Problem:** Windows treats `style.css` and `styles.css` as the same file. Linux treats them as different files.

**Detection:**
```bash
# On Linux: List actual filenames with exact case
ls -la forms-interface/

# Search code for references (case-sensitive)
grep -r "style\.css" --include="*.{html,js,sh,md}"
```

**Prevention:**
```bash
# 1. Always verify filenames before referencing
REAL_FILE=$(ls -la *.css | awk '{print $9}')

# 2. Use defensive file existence checks
if [ -f "forms-interface/styles.css" ]; then
    chmod 444 "forms-interface/styles.css"
else
    echo "ERROR: styles.css not found"
    exit 1
fi
```

**Python Solution:**
```python
import os

def find_file_ci(directory, filename):
    """Find file with case-insensitive matching"""
    for file in os.listdir(directory):
        if file.lower() == filename.lower():
            return os.path.join(directory, file)
    return None

# Example: styles.css vs style.css
css_file = find_file_ci("forms-interface", "styles.css")
if css_file:
    print(f"Found: {css_file}")
```

#### Path Separators

**Problem:** Windows uses `\`, Linux uses `/`. Hardcoding paths breaks cross-platform compatibility.

**Node.js Solution:**
```javascript
const path = require('path');

// WRONG: Hardcoded separators
const filePath = 'forms-interface\\styles.css';

// CORRECT: Use path module
const filePath = path.join('forms-interface', 'styles.css');

// Path normalization (handles both separators)
const normalized = path.normalize('forms-interface\\styles.css');
```

**Python Solution:**
```python
from pathlib import Path

// WRONG: Hardcoded separators
file_path = "forms-interface\\styles.css"

// CORRECT: Use pathlib
file_path = Path("forms-interface") / "styles.css"

// Cross-platform path operations
file_path.exists()
file_path.is_file()
```

**Bash Solution:**
```bash
# Use $HOME instead of ~ in scripts
DEPLOY_DIR="$HOME/workspace/mcp-agent-server"

# Use ${VAR} for safe path expansion
SCRIPT_DIR="${0%/*}"  # Directory of this script
```

### Line Endings

**Problem:** Windows uses CRLF (`\r\n`), Linux uses LF (`\n`). This causes script execution failures on Linux.

**Detection:**
```bash
# Check file format
file script.sh
# Output: script.sh: ASCII text, with CRLF line terminators

# Show line endings
cat -A script.sh
# CRLF shows as ^M$ (Ctrl-M + $)
# LF shows as $ only
```

**Prevention in Git:**
```bash
# .gitattributes (recommended for all projects)
* text=auto
*.sh text eol=lf
*.py text eol=lf
*.js text eol=lf
*.html text eol=lf
*.css text eol=lf
*.bat text eol=crlf
*.ps1 text eol=crlf
```

**Fix Existing Files:**
```bash
# Convert CRLF to LF (Linux scripts)
dos2unix script.sh
# Or using sed
sed -i 's/\r$//' script.sh

# Convert LF to CRLF (Windows scripts)
unix2dos script.bat
```

### Executable Permissions

**Problem:** Git does not preserve execute bits on Windows. After `git pull` on Linux, scripts lose execute permissions.

**Detection:**
```bash
# Check script permissions
ls -la *.sh
# Expected: -rwxr-xr-x (755)
# Problem: -rw-r--r-- (644)
```

**Prevention in Deployment Scripts:**
```bash
#!/bin/bash
# deploy-and-restart.sh

# Defensive: Always check and fix permissions
if [ ! -x "$0" ]; then
    echo "This script is not executable. Fixing..."
    chmod +x "$0"
    echo "Please run the script again."
    exit 1
fi

# Or auto-fix and continue
for script in *.sh; do
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        echo "Adding execute permission to $script"
        chmod +x "$script"
    fi
done
```

**Git Configuration:**
```bash
# Tell Git to remember execute bits
git config core.filemode false  # Windows: ignore permission changes
git config core.filemode true   # Linux: track permissions

# Manually set execute bit (from any OS)
git update-index --chmod=+x deploy-and-restart.sh
git commit -m "Set execute bit on deployment script"
```

### Symlinks

**Problem:** Windows and Linux handle symbolic links differently. Git symlink behavior varies.

**Detection:**
```bash
# Check if file is symlink
ls -la /var/www/html/forms
# Output: lrwxrwxrwx ... /var/www/html/forms -> /home/user/project

# Read link target
readlink -f /var/www/html/forms
```

**Cross-platform Symlink Creation:**
```bash
#!/bin/bash
# deploy-and-restart.sh

DEPLOY_DIR="/home/user/project/forms-interface"
DEPLOY_LINK="/var/www/html/forms"

# Check if link already exists
if [ -L "$DEPLOY_LINK" ]; then
    echo "Removing existing symlink..."
    rm "$DEPLOY_LINK"
fi

# Create new symlink
ln -sf "$DEPLOY_DIR" "$DEPLOY_LINK"

# Verify
if [ -L "$DEPLOY_LINK" ]; then
    echo "✓ Symlink created: $DEPLOY_LINK -> $DEPLOY_DIR"
else
    echo "✗ Failed to create symlink"
    exit 1
fi
```

**Python Solution (platform-independent):**
```python
import os
import platform

def create_symlink(source, target):
    """Create symlink with platform-specific handling"""
    try:
        os.symlink(source, target)
        print(f"Created symlink: {target} -> {source}")
    except OSError as e:
        if platform.system() == 'Windows':
            # Windows requires Developer Mode or Admin privileges
            print(f"Symlink creation failed: {e}")
            print("Enable Developer Mode or run as Administrator")
        raise
```

---

## Quick Decision Guide

**When developing across Windows and Linux:**
- Always verify filenames with `ls -la` before referencing
- Use cross-platform path libraries (`pathlib`, `path.join`)
- Configure `.gitattributes` for line endings
- Set execute bits with `git update-index --chmod=+x`
- Test on target platform before deployment

**When deployment fails:**
1. Check for case sensitivity mismatches
2. Verify script permissions (`ls -la *.sh`)
3. Check line endings (`file script.sh`)
4. Validate path construction
5. Run pre-deployment validation script

**For CI/CD:**
- Test on multiple platforms (Windows, Linux, macOS)
- Validate line endings and permissions in pipeline
- Use platform-agnostic path construction
- Run pre-flight checks before deployment

---

## Works Well With

**Complementary Skills:**
- moai-checklist-pre-deployment - Automated pre-flight checks before deployment
- moai-workflow-ddd - Domain-driven development with cross-platform considerations
- moai-foundation-quality - Quality gates including cross-platform validation
- moai-pattern-devops - DevOps best practices for cross-platform CI/CD

**Related Documentation:**
- docs/DEVELOPMENT_METHODOLOGY.md - Development methodology and failure analysis
- docs/PRE_DEPLOYMENT_CHECKLIST.md - Complete pre-deployment checklist
- scripts/pre-flight-check.sh - Automated validation script

---

## Module Index

Detailed implementation guides are available in modular references:

- **Failure Patterns:** modules/failure-patterns.md - Comprehensive failure pattern analysis with systematic prevention
- **Best Practices:** modules/best-practices.md - Development workflow, defensive programming, platform detection
- **Validation Checklist:** modules/validation-checklist.md - Pre-commit, pre-deploy, and post-deploy checklists

Each module provides deep-dive technical content for specific cross-platform challenges.
