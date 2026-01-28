# Cross-platform Validation Checklist

Comprehensive validation checklists for cross-platform development across all deployment phases.

## Pre-commit Validation (Windows Development Environment)

### File Verification

**File Existence:**
- [ ] All referenced files exist (verify with `ls`)
- [ ] Filenames match exactly (case-sensitive check)
- [ ] No hardcoded path separators (use `path.join` or `pathlib`)
- [ ] Shell scripts have LF line endings (not CRLF)

**Commands:**
```bash
# List actual files
ls -la forms-interface/
ls -la forms-interface/*.html forms-interface/*.js forms-interface/*.css

# Check case sensitivity
find . -name "*.css" -o -name "*.js" -o -name "*.html"

# Check for hardcoded separators
grep -r '\\\\' --include="*.py" --include="*.js" .

# Check line endings
file *.sh
```

### Git Status

**Repository State:**
- [ ] All changes committed
- [ ] No uncommitted changes (`git status --porcelain`)
- [ ] Execute bits set on `.sh` files (`git update-index --chmod=+x`)
- [ ] `.gitattributes` configured for line endings

**Commands:**
```bash
# Check git status
git status --porcelain

# Set execute bits
git update-index --chmod=+x script.sh
git commit -m "Set execute bit"

# Verify .gitattributes
cat .gitattributes
# Should contain: *.sh text eol=lf
```

### Code Review

**Platform Compatibility:**
- [ ] No platform-specific assumptions
- [ ] Error handling for missing files
- [ ] Defensive permission checks
- [ ] Cross-platform path construction

**Checklist:**
- [ ] Python uses `pathlib` or `os.path.join`
- [ ] Node.js uses `path.join()`
- [ ] Bash uses forward slashes (works on both)
- [ ] File existence checks before operations
- [ ] Permission checks before execute
- [ ] Error handling for cross-platform issues

## Pre-deploy Validation (Linux Deployment Environment)

### Environment Check

**File System:**
- [ ] All required files exist (`ls -la forms-interface/`)
- [ ] Filenames match code references (case-sensitive)
- [ ] Scripts have execute permissions (`ls -la *.sh`)
- [ ] Line endings are LF (not CRLF) for shell scripts

**Commands:**
```bash
# Verify files exist
ls -la forms-interface/*.html
ls -la forms-interface/*.js
ls -la forms-interface/*.css

# Check filename consistency
ls -la forms-interface/*.css
grep -n "\.css" forms-interface/index.html

# Check script permissions
ls -la *.sh
chmod +x deploy-and-restart.sh

# Check line endings
file *.sh
# Should NOT contain "CRLF"
```

**Permissions:**
- [ ] Deployment directory writable
- [ ] Can create symlinks in target location
- [ ] Sudo privileges available if needed
- [ ] Log directory writable

**Commands:**
```bash
# Check write permissions
test -w /var/www/html && echo "Writable" || echo "Not writable"

# Check symlink creation
ln -sf /tmp/test_link ~/test_link && rm ~/test_link && echo "Can create symlinks" || echo "Cannot create symlinks"

# Check sudo
sudo -v && echo "Has sudo" || echo "No sudo"

# Check log directory
test -w /var/log || echo "Using $HOME for logs"
```

### Network Check

**Connectivity:**
- [ ] GitHub reachable (`ping -c 2 github.com`)
- [ ] Git remote accessible (`git ls-remote origin`)
- [ ] Required external services accessible
- [ ] DNS resolution working

**Commands:**
```bash
# Test GitHub
ping -c 2 github.com

# Verify git remote
git ls-remote origin

# Test DNS
nslookup github.com

# Test HTTP/HTTPS
curl -I https://github.com
```

### Server Status

**Web Server:**
- [ ] Web server running (`systemctl status nginx`)
- [ ] Configuration valid (`nginx -t`)
- [ ] Log directory writable
- [ ] Required ports listening

**Commands:**
```bash
# Check nginx
sudo systemctl status nginx
sudo nginx -t

# Check ports
netstat -tlnp | grep :80
netstat -tlnp | grep :443

# Check logs
sudo tail -f /var/log/nginx/error.log
```

### Pre-deploy Script

```bash
#!/bin/bash
# pre-deploy-validation.sh

echo "=== Pre-deployment Validation ==="

# 1. File existence
echo "Checking files..."
MISSING=0
for file in forms-interface/index.html forms-interface/script.js forms-interface/styles.css; do
    if [ -f "$file" ]; then
        echo "✓ $file"
    else
        echo "✗ $file NOT FOUND"
        MISSING=1
    fi
done

if [ $MISSING -eq 1 ]; then
    echo "FAIL: Missing files"
    exit 1
fi

# 2. Filename consistency
echo ""
echo "Checking filename consistency..."
ACTUAL=$(ls forms-interface/*.css | xargs -n1 basename)
REFERENCED=$(grep -o '[a-zA-Z_-]*\.css' forms-interface/index.html)
if [ "$ACTUAL" != "$REFERENCED" ]; then
    echo "FAIL: Filename mismatch"
    echo "Actual: $ACTUAL"
    echo "Referenced: $REFERENCED"
    exit 1
fi
echo "✓ Filenames consistent"

# 3. Script permissions
echo ""
echo "Checking script permissions..."
if [ -x "deploy-and-restart.sh" ]; then
    echo "✓ deploy-and-restart.sh is executable"
else
    echo "FAIL: deploy-and-restart.sh not executable"
    chmod +x deploy-and-restart.sh
    echo "✓ Fixed permissions"
fi

# 4. Line endings
echo ""
echo "Checking line endings..."
CRLF_COUNT=$(file *.sh | grep -c CRLF)
if [ $CRLF_COUNT -gt 0 ]; then
    echo "FAIL: CRLF detected in shell scripts"
    file *.sh | grep CRLF
    exit 1
fi
echo "✓ Line endings correct"

# 5. Network
echo ""
echo "Checking network..."
if ping -c 1 -W 2 github.com > /dev/null 2>&1; then
    echo "✓ GitHub reachable"
else
    echo "FAIL: Cannot reach GitHub"
    exit 1
fi

# 6. Git remote
echo ""
echo "Checking git remote..."
if git ls-remote origin > /dev/null 2>&1; then
    echo "✓ Git remote accessible"
else
    echo "FAIL: Cannot access git remote"
    exit 1
fi

# 7. Web server
echo ""
echo "Checking web server..."
if systemctl is-active --quiet nginx; then
    echo "✓ nginx is running"
else
    echo "⚠ nginx is not running"
fi

echo ""
echo "=== All validations passed! ==="
```

## Post-deploy Validation

### File Verification

**Deployment Success:**
- [ ] Symlink created correctly (`ls -la /var/www/html/forms`)
- [ ] All files accessible via HTTP (`curl -I http://localhost/forms/`)
- [ ] Permissions correct (read-only for static files)
- [ ] No CRLF in deployed scripts

**Commands:**
```bash
# Check symlink
ls -la /var/www/html/forms
readlink -f /var/www/html/forms

# Test HTTP access
curl -I http://localhost/forms/index.html
curl -I http://localhost/forms/script.js
curl -I http://localhost/forms/styles.css

# Check permissions
ls -la forms-interface/
# Should be 444 (read-only)

# Check for CRLF
file /var/www/html/forms/script.sh 2>/dev/null || echo "Not a script file"
```

### Functional Check

**Application Functionality:**
- [ ] Website loads in browser
- [ ] No console errors (F12 developer tools)
- [ ] Cache version incremented correctly
- [ ] External access works (if applicable)
- [ ] All features working as expected

**Manual Testing:**
```bash
# 1. Local access
curl -s http://localhost/forms/ | head -20

# 2. External access
curl -s https://forms.abyz-lab.work | head -20

# 3. Cache version
grep -oP 'script\.js\?v=\K[0-9.]+' /var/www/html/forms/index.html

# 4. Browser test
# Open in browser:
# - http://localhost/forms (local)
# - https://forms.abyz-lab.work (external)
# Check F12 console for errors
# Hard refresh: Ctrl+Shift+R
```

### Rollback Readiness

**Rollback Verification:**
- [ ] Backup created before deployment
- [ ] Rollback script tested
- [ ] Previous version accessible
- [ ] Rollback documented

**Commands:**
```bash
# Check backup
ls -dt /var/www/html/forms.backup.* | head -1

# Test rollback (dry-run)
# LATEST_BACKUP=$(ls -dt /var/www/html/forms.backup.* | head -1)
# sudo ln -sf "$LATEST_BACKUP" /var/www/html/forms.test
# curl -I http://localhost/forms.test/index.html
# sudo rm /var/www/html/forms.test
```

## Continuous Monitoring

### Health Checks

**Automated Monitoring:**
- [ ] HTTP endpoint monitoring
- [ ] SSL certificate expiry check
- [ ] Disk space monitoring
- [ ] Process monitoring
- [ ] Log error monitoring

**Health Check Script:**
```bash
#!/bin/bash
# health-check.sh

# 1. HTTP check
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/forms/)
if [ "$HTTP_CODE" != "200" ]; then
    echo "FAIL: HTTP $HTTP_CODE"
    exit 1
fi

# 2. Process check
if ! systemctl is-active --quiet nginx; then
    echo "FAIL: nginx not running"
    exit 1
fi

# 3. Disk space
DISK_USAGE=$(df /var/www | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    echo "WARN: Disk usage at ${DISK_USAGE}%"
fi

# 4. SSL check (if applicable)
if [ -f "/etc/letsencrypt/live/forms.abyz-lab.work/cert.pem" ]; then
    EXPIRY=$(openssl x509 -enddate -noout -in /etc/letsencrypt/live/forms.abyz-lab.work/cert.pem | cut -d= -f2)
    EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
    CURRENT_EPOCH=$(date +%s)
    DAYS_LEFT=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))
    if [ $DAYS_LEFT -lt 30 ]; then
        echo "WARN: SSL expires in $DAYS_LEFT days"
    fi
fi

echo "OK: All health checks passed"
```
