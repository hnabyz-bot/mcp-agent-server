# Pre-Deployment Checklist - Reference Documentation

This file provides comprehensive reference documentation for pre-deployment validation and deployment automation.

## Table of Contents

1. [External Resources](#external-resources)
2. [Related Project Documentation](#related-project-documentation)
3. [Technical Specifications](#technical-specifications)
4. [Troubleshooting Guide](#troubleshooting-guide)
5. [Best Practices](#best-practices)

---

## External Resources

### Cross-Platform Development

**Windows-Linux Filesystem Differences:**
- Case Sensitivity: Windows is case-insensitive, Linux is case-sensitive
- Path Separators: Windows uses backslash `\`, Linux uses forward slash `/`
- Line Endings: Windows uses CRLF (`\r\n`), Linux uses LF (`\n`)
- File Permissions: Windows uses ACLs, Linux uses octal permissions (chmod)

**Git Configuration for Cross-Platform:**
```bash
# Configure Git to handle line endings correctly
git config --global core.autocrlf input  # Linux/Mac
git config --global core.autocrlf true   # Windows

# Check current configuration
git config --get core.autocrlf

# Normalize line endings in repository
git add --renormalize .
```

**Common File Naming Pitfalls:**
- `style.css` vs `styles.css` - Pluralization matters on Linux
- `Script.js` vs `script.js` - Capitalization matters on Linux
- Always verify filenames with `ls -la` before referencing in code

### Bash Scripting Best Practices

**Shebang Standards:**
```bash
#!/bin/bash           # Preferred for bash-specific features
#!/usr/bin/env bash   # More portable across different Unix systems
#!/bin/sh             # POSIX-compliant scripts (most portable)
```

**Error Handling Patterns:**
```bash
# Exit immediately on error
set -e

# Exit on undefined variable
set -u

# Pipe failure exits entire pipeline
set -o pipefail

# Combine all three (recommended for production scripts)
set -euo pipefail
```

**Trap Signals for Cleanup:**
```bash
# Trap errors and execute cleanup
trap 'cleanup_on_error' ERR

cleanup_on_error() {
    local exit_code=$?
    echo "Script failed with exit code: $exit_code"
    # Cleanup logic here
    exit $exit_code
}

# Trap script exit (always executes)
trap 'final_cleanup' EXIT

# Trap interrupt signal (Ctrl+C)
trap 'interrupted' INT
```

**Color Output Standards:**
```bash
# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Success${NC}"
echo -e "${RED}Error${NC}"
echo -e "${YELLOW}Warning${NC}"
```

### Nginx Configuration

**Basic Nginx Commands:**
```bash
# Check nginx status
sudo systemctl status nginx

# Start/stop/restart nginx
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx

# Test nginx configuration
sudo nginx -t

# Reload nginx without downtime
sudo nginx -s reload

# View nginx error log
sudo tail -f /var/log/nginx/error.log

# View nginx access log
sudo tail -f /var/log/nginx/access.log
```

**Common Nginx Issues:**
- Permission denied on static files: Check file permissions (`chmod 644`)
- 404 Not Found: Check symbolic link target exists
- 502 Bad Gateway: Backend service not running
- Connection refused: Check nginx is listening on correct port

### Git Workflow Patterns

**Safe Update Pattern (Stash + Reset):**
```bash
# Stash local changes with descriptive message
git stash push -u -m "auto-stash-$(date +%Y%m%d_%H%M%S)"

# Fetch latest from remote
git fetch origin main

# Hard reset to remote (avoid merge conflicts)
git reset --hard origin/main

# List stashes if needed
git stash list

# Apply specific stash
git stash apply stash@{0}
```

**Merge vs Rebase:**
```bash
# Merge (preserves history, creates merge commit)
git merge origin/main

# Rebase (linear history, rewrites commits)
git rebase origin/main

# For deployment automation, prefer reset --hard for consistency
git fetch origin main
git reset --hard origin/main
```

**Git Hooks Reference:**
- `pre-commit`: Runs before commit is created
- `pre-push`: Runs before push to remote
- `post-merge`: Runs after successful merge
- `post-checkout`: Runs after checkout

### Linux Permissions

**Permission Numeric Codes:**
```bash
# Read, Write, Execute
# 4 (read), 2 (write), 1 (execute)

# Common permissions
644 = rw-r--r-- (owner: rw, group: r, others: r)  # Files
755 = rwxr-xr-x (owner: rwx, group: rx, others: rx)  # Scripts/Directories
444 = r--r--r-- (read-only for all)  # Immutable files
777 = rwxrwxrwx (all permissions)  # Avoid using!

# Symbolic representation
chmod +x file.sh     # Add execute for all
chmod -x file.sh     # Remove execute for all
chmod u+x file.sh    # Add execute for owner only
chmod go-wx file.sh  # Remove write/execute for group/others
```

**Symbolic Links:**
```bash
# Create symbolic link
ln -s /path/to/target /path/to/link

# View symbolic link
ls -la /path/to/link

# Show link target
readlink -f /path/to/link

# Remove link (does not affect target)
rm /path/to/link
```

---

## Related Project Documentation

### Core Documentation Files

**docs/PRE_DEPLOYMENT_CHECKLIST.md**
- Complete pre-deployment checklist for Windows and Raspberry Pi
- Common failure patterns and resolution steps
- Problem-solving guide for deployment issues
- Best practices for cross-platform development

**docs/DEVELOPMENT_METHODOLOGY.md**
- Development methodology improvement guide
- Failure pattern analysis (5 common patterns)
- Root cause analysis for deployment issues
- Validation process documentation (Pre-commit, Pre-deploy, Post-deploy)
- Workflow improvements and Git best practices

**docs/DEPLOYMENT_GUIDE.md**
- Comprehensive deployment guide for Raspberry Pi
- Step-by-step setup instructions
- Troubleshooting section (6.11: Problem Resolution History)
- Integration with Cloudflare Tunnel

### Automation Scripts

**scripts/pre-flight-check.sh**
- Automated validation script with 8 validation phases
- Color-coded output (pass/warn/fail)
- Auto-fix capabilities for common issues
- Exit codes for integration (0 = success, 1 = failure)

**scripts/deploy-and-restart.sh**
- Main deployment script with automatic rollback
- Backup management (keeps latest 5 backups)
- Service restart automation
- Error trapping and rollback on failure

**scripts/post-deploy-check.sh**
- Post-deployment verification script
- HTTP access testing
- Symbolic link validation
- Deployed version confirmation

**windows-deploy.bat**
- Windows-side deployment automation
- Cache version increment
- Git commit and push automation

---

## Technical Specifications

### File Structure Requirements

**Core Files (Required):**
```
forms-interface/
├── index.html          # Main HTML file with cache version parameter
├── script.js           # Application logic
└── styles.css          # Stylesheet (NOT style.css)
```

**Deployment Scripts (Required):**
```
./
├── deploy-and-restart.sh      # Main deployment script (Raspberry Pi)
├── setup-raspberry-pi.sh      # Initial setup script
├── windows-deploy.bat         # Windows deployment helper
└── scripts/
    ├── pre-flight-check.sh    # Pre-deployment validation
    └── post-deploy-check.sh   # Post-deployment verification
```

**Required Permissions:**
```bash
# Core files (read-only for deployment)
444 (r--r--r--) for forms-interface/*

# Deployment scripts (executable)
755 (rwxr-xr-x) for *.sh

# Log files (writable)
644 (rw-r--r--) for *.log
```

### HTTP Cache Versioning

**Cache Busting Strategy:**
```html
<!-- In index.html -->
<link rel="stylesheet" href="styles.css">
<script src="script.js?v=1.0.5"></script>  <!-- Version parameter -->
```

**Version Increment Process:**
1. Update version number in `windows-deploy.bat`
2. Run `windows-deploy.bat` to increment version
3. Commit and push changes
4. Pull and deploy on Raspberry Pi
5. Verify version updated in deployed files

**Version Format:**
- Semantic versioning: `MAJOR.MINOR.PATCH` (e.g., `1.0.5`)
- Increment PATCH for bug fixes
- Increment MINOR for new features
- Increment MAJOR for breaking changes

### Nginx Configuration

**Symbolic Link Structure:**
```bash
# Link location
/var/www/html/forms -> /home/raspi/workspace/mcp-agent-server/forms-interface

# Why symbolic link?
# - Easy rollback (just change link target)
# - Zero-downtime updates (atomic link change)
# - Backup management (keep multiple versions)
```

**Backup Pattern:**
```bash
# Backup directory format
/var/www/html/forms.backup.YYYYMMDD_HHMMSS

# Example
/var/www/html/forms.backup.20260128_143022

# Automated backup management
deploy-and-restart.sh creates backup before updating
Keeps latest 5 backups, removes older ones
```

### Git Workflow Standards

**Branch Strategy:**
```bash
main        # Production branch (deployed to Raspberry Pi)
develop     # Development branch (integration testing)
feature/*   # Feature branches (feature development)
hotfix/*    # Hotfix branches (urgent production fixes)
```

**Commit Message Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation change
- `style`: Code style change (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance task

**Example:**
```
feat(deployment): Add automated pre-flight validation

- Implement pre-flight-check.sh with 8 validation phases
- Add auto-fix capabilities for common issues
- Integrate with deployment workflow

Closes #123
```

---

## Troubleshooting Guide

### Common Error Messages

**Error: `chmod: cannot access 'style.css': No such file or directory`**
- **Cause:** Filename mismatch (actual file is `styles.css`)
- **Solution:** Verify actual filename with `ls -la forms-interface/*.css`, update all references
- **Prevention:** Use `pre-flight-check.sh` before deployment

**Error: `sudo-rs: cannot execute 'deploy-and-restart.sh': Permission denied`**
- **Cause:** Execution permission lost after git pull
- **Solution:** Run `chmod +x deploy-and-restart.sh`
- **Prevention:** Add permission fix to deployment script

**Error: `Your local changes to the following files would be overwritten by merge`**
- **Cause:** Local uncommitted changes conflict with incoming changes
- **Solution:** Use stash + reset pattern instead of pull
- **Prevention:** Always commit or stash changes before pulling

**Error: `thread 'main' panicked at src/exec/use_pty/monitor.rs`**
- **Cause:** sudo-rs execution refusal
- **Solution:** Fix permissions first, then retry: `chmod +x deploy-and-restart.sh`
- **Alternative:** Use `sudo -s bash -c './deploy-and-restart.sh'`

### Debug Mode

**Enable Bash Debug Output:**
```bash
# Run script with debug output
bash -x ./scripts/pre-flight-check.sh

# Run specific function in debug mode
bash -x -c 'source ./scripts/pre-flight-check.sh && check_files'
```

**Check Script Line Endings:**
```bash
# View file encoding and line endings
file ./scripts/pre-flight-check.sh

# Expected output: ASCII text executable
# If shows CRLF, convert to LF:
dos2unix ./scripts/pre-flight-check.sh
# Or using sed:
sed -i 's/\r$//' ./scripts/pre-flight-check.sh
```

**Verify Shell Environment:**
```bash
# Check current shell
echo $SHELL

# Check bash version
bash --version

# Verify bash is installed
which bash

# Test script syntax
bash -n ./scripts/pre-flight-check.sh
```

### Log Analysis

**Deployment Log Location:**
```bash
# Main deployment log
$HOME/mcp-agent-deploy.log

# Nginx error log
/var/log/nginx/error.log

# Nginx access log
/var/log/nginx/access.log

# System journal
sudo journalctl -u nginx -f
```

**Search for Errors:**
```bash
# Search for errors in deployment log
grep -i "error\|fail\|permission denied" $HOME/mcp-agent-deploy.log

# View last 50 lines of deployment log
tail -n 50 $HOME/mcp-agent-deploy.log

# Follow deployment log in real-time
tail -f $HOME/mcp-agent-deploy.log

# Extract specific error patterns
grep -A 5 -B 5 "Permission denied" $HOME/mcp-agent-deploy.log
```

### Network Troubleshooting

**Test GitHub Connectivity:**
```bash
# Ping GitHub
ping -c 3 github.com

# Test DNS resolution
nslookup github.com

# Test HTTPS connection
curl -I https://github.com

# Test git protocol
git ls-remote origin
```

**Test Local HTTP Server:**
```bash
# Test HTTP response
curl -I http://localhost/forms/index.html

# Test with verbose output
curl -v http://localhost/forms/index.html

# Test specific file
curl -I http://localhost/forms/script.js

# Test external access (via Cloudflare Tunnel)
curl -I https://forms.abyz-lab.work
```

**Check Port Availability:**
```bash
# Check if port is listening
sudo netstat -tlnp | grep :80

# Alternative using ss
sudo ss -tlnp | grep :80

# Check nginx is listening
sudo lsof -i :80

# Test port connectivity
nc -zv localhost 80
```

---

## Best Practices

### Development Workflow

**Before Making Changes:**
1. Pull latest changes from repository
2. Run pre-flight check to establish baseline
3. Create feature branch for new work
4. Verify local environment is clean

**During Development:**
1. Make incremental changes
2. Test changes locally before committing
3. Write descriptive commit messages
4. Run pre-flight check before commit

**Before Deployment:**
1. Ensure all tests pass
2. Run complete pre-flight checklist
3. Verify cache version incremented (if needed)
4. Create backup of current deployment

**After Deployment:**
1. Run post-deployment verification
2. Test in browser (including cache refresh)
3. Monitor logs for errors
4. Document any issues encountered

### Deployment Safety

**Atomic Deployment Pattern:**
```bash
# 1. Create backup
BACKUP_DIR="/var/www/html/forms.backup.$(date +%Y%m%d_%H%M%S)"
cp -r /var/www/html/forms "$BACKUP_DIR"

# 2. Deploy to new location
# ... deployment steps ...

# 3. Update symlink atomically
ln -sf /new/location /var/www/forms.new
mv -T /var/www/forms.new /var/www/forms

# 4. Verify deployment
if ! curl -f http://localhost/forms/index.html; then
    # Rollback on failure
    ln -sf "$BACKUP_DIR" /var/www/html/forms
    exit 1
fi
```

**Rollback Readiness:**
- Always keep last 5 backups
- Test rollback procedure regularly
- Document rollback steps
- Monitor alerts after deployment

### Automation Principles

**Validation First:**
- Validate before modifying
- Check prerequisites before executing
- Fail fast on critical errors
- Provide clear error messages

**Idempotency:**
- Scripts should be safe to run multiple times
- Check before creating (don't duplicate)
- Use `set -e` for error handling
- Clean up on failure

**Observability:**
- Log all important actions
- Use color-coded output
- Provide progress indicators
- Generate summary reports

### Security Considerations

**File Permissions:**
- Use minimal required permissions
- Set sensitive files to read-only (444)
- Restrict script execution (755, not 777)
- Never hardcode credentials in scripts

**Input Validation:**
- Validate all user input
- Sanitize filenames before use
- Quote variables to prevent globbing
- Use `set -u` to catch undefined variables

**Secrets Management:**
- Store secrets in environment variables
- Never commit secrets to git
- Use `.env` files with `.gitignore`
- Rotate credentials regularly

---

## Additional Resources

### Learning Materials

**Bash Scripting:**
- [Bash Guide for Beginners](https://tldp.org/LDP/Bash-Beginners-Guide/html/)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)
- [ShellCheck](https://www.shellcheck.net/) - Bash script linter

**Git Workflow:**
- [Git Workflow Guide](https://www.atlassian.com/git/tutorials/comparing-workflows)
- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
- [Semantic Versioning](https://semver.org/)

**Nginx Configuration:**
- [Nginx Beginner's Guide](https://nginx.org/en/docs/beginners_guide.html)
- [Nginx Admin Guide](https://nginx.org/en/docs/admin_guide.html)
- [Nginx Troubleshooting](https://nginx.org/en/docs/debugging_log.html)

### Cross-Platform Development

**Filesystem Considerations:**
- Always verify filenames on both platforms
- Use `ls -la` to check actual filenames
- Be aware of case sensitivity differences
- Test on target platform before deployment

**Line Ending Handling:**
- Configure Git to handle line endings automatically
- Use `.gitattributes` for specific file types
- Normalize line endings before committing
- Test scripts on both platforms

### Monitoring and Logging

**Log Management:**
- Rotate logs regularly
- Compress old logs
- Monitor log file sizes
- Archive important logs

**Alerting:**
- Set up alerts for deployment failures
- Monitor error rates
- Track deployment frequency
- Measure deployment success rate

---

For implementation examples, see:
- examples.md - Working automation script examples
- SKILL.md - Main skill documentation and usage guide
