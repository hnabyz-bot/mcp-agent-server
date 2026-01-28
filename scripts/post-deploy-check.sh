#!/bin/bash
# Post-deployment Verification Script
# Purpose: Automated verification after deployment
# Usage: ./scripts/post-deploy-check.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0
WARN=0

# Configuration
DEPLOY_LINK="/var/www/html/forms"
FORMS_DIR="$HOME/workspace/mcp-agent-server/forms-interface"

# Helper functions
log_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((PASS++))
}

log_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    echo -e "  ${YELLOW}Reason: $2${NC}"
    ((FAIL++))
}

log_warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
    ((WARN++))
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo "==================================="
echo "Post-deployment Verification"
echo "==================================="
echo ""

# ========================================
# Phase 1: Symbolic Link Verification
# ========================================
echo -e "${BLUE}Phase 1: Symbolic Link${NC}"
echo ""

if [ -L "$DEPLOY_LINK" ]; then
    log_pass "Symbolic link exists"

    LINK_TARGET=$(readlink -f "$DEPLOY_LINK")
    log_info "Link target: $LINK_TARGET"

    if [ -d "$LINK_TARGET" ]; then
        log_pass "Link target directory exists"
    else
        log_fail "Link target" "Directory does not exist: $LINK_TARGET"
    fi
else
    log_fail "Symbolic link" "Link does not exist: $DEPLOY_LINK"
fi

# ========================================
# Phase 2: File Accessibility
# ========================================
echo ""
echo -e "${BLUE}Phase 2: File Accessibility${NC}"
echo ""

REQUIRED_FILES=(
    "$DEPLOY_LINK/index.html"
    "$DEPLOY_LINK/script.js"
    "$DEPLOY_LINK/styles.css"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_pass "$(basename $file) accessible"
    else
        log_fail "$(basename $file)" "File not found at: $file"
    fi
done

# ========================================
# Phase 3: HTTP Access Test
# ========================================
echo ""
echo -e "${BLUE}Phase 3: HTTP Access${NC}"
echo ""

if command -v curl &> /dev/null; then
    # Test local access
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/forms/index.html 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ]; then
        log_pass "Local HTTP access: 200 OK"
    else
        log_fail "Local HTTP" "Received HTTP $HTTP_CODE"
    fi

    # Test script.js
    SCRIPT_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/forms/script.js 2>/dev/null)
    if [ "$SCRIPT_HTTP_CODE" = "200" ]; then
        log_pass "script.js accessible: 200 OK"
    else
        log_fail "script.js HTTP" "Received HTTP $SCRIPT_HTTP_CODE"
    fi

    # Test styles.css
    CSS_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/forms/styles.css 2>/dev/null)
    if [ "$CSS_HTTP_CODE" = "200" ]; then
        log_pass "styles.css accessible: 200 OK"
    else
        log_fail "styles.css HTTP" "Received HTTP $CSS_HTTP_CODE"
    fi
else
    log_warn "curl not available for HTTP testing"
fi

# ========================================
# Phase 4: Cache Version Verification
# ========================================
echo ""
echo -e "${BLUE}Phase 4: Cache Version${NC}"
echo ""

if [ -f "$DEPLOY_LINK/index.html" ]; then
    DEPLOYED_VERSION=$(grep -oP 'script\.js\?v=\K[0-9.]+' "$DEPLOY_LINK/index.html" 2>/dev/null || echo "0.0.0")

    if [ "$DEPLOYED_VERSION" != "0.0.0" ]; then
        log_pass "Deployed version: $DEPLOYED_VERSION"

        # Compare with source version
        if [ -f "$FORMS_DIR/index.html" ]; then
            SOURCE_VERSION=$(grep -oP 'script\.js\?v=\K[0-9.]+' "$FORMS_DIR/index.html" 2>/dev/null || echo "0.0.0")
            if [ "$DEPLOYED_VERSION" = "$SOURCE_VERSION" ]; then
                log_pass "Version matches source: $SOURCE_VERSION"
            else
                log_warn "Version mismatch (deployed: $DEPLOYED_VERSION, source: $SOURCE_VERSION)"
            fi
        fi
    else
        log_warn "Could not parse cache version"
    fi
else
    log_fail "Cache version" "index.html not found at: $DEPLOY_LINK/index.html"
fi

# ========================================
# Phase 5: File Permissions
# ========================================
echo ""
echo -e "${BLUE}Phase 5: File Permissions${NC}"
echo ""

CORE_FILES=(
    "$FORMS_DIR/index.html"
    "$FORMS_DIR/script.js"
    "$FORMS_DIR/styles.css"
)

for file in "${CORE_FILES[@]}"; do
    if [ -f "$file" ]; then
        PERM=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%A" "$file")

        if [ "$PERM" = "444" ]; then
            log_pass "$(basename $file) is read-only (444)"
        elif [ "$PERM" = "644" ]; then
            log_warn "$(basename $file) is writable (644, should be 444)"
        else
            log_warn "$(basename $file) permissions: $PERM (expected 444)"
        fi
    fi
done

# Check directory permissions
if [ -d "$FORMS_DIR" ]; then
    DIR_PERM=$(stat -c "%a" "$FORMS_DIR" 2>/dev/null || stat -f "%A" "$FORMS_DIR")
    if [ "$DIR_PERM" = "755" ]; then
        log_pass "Directory permissions: 755"
    else
        log_warn "Directory permissions: $DIR_PERM (expected 755)"
    fi
fi

# ========================================
# Phase 6: Content Verification
# ========================================
echo ""
echo -e "${BLUE}Phase 6: Content Verification${NC}"
echo ""

if [ -f "$DEPLOY_LINK/script.js" ]; then
    # Check for email field (example)
    if grep -q "formData.append('email'" "$DEPLOY_LINK/script.js" 2>/dev/null; then
        log_pass "Email field present in script.js"
    else
        log_info "Email field check skipped (field may not exist in current version)"
    fi

    # Check for form submission handler
    if grep -q "addEventListener('submit'" "$DEPLOY_LINK/script.js" 2>/dev/null; then
        log_pass "Form submit handler present"
    else
        log_warn "Form submit handler not found"
    fi
fi

# ========================================
# Phase 7: External Access Test
# ========================================
echo ""
echo -e "${BLUE}Phase 7: External Access${NC}"
echo ""

EXTERNAL_URL="https://forms.abyz-lab.work"

if command -v curl &> /dev/null; then
    EXTERNAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$EXTERNAL_URL" 2>/dev/null)

    if [ "$EXTERNAL_CODE" = "200" ]; then
        log_pass "External access successful: 200 OK"
    elif [ "$EXTERNAL_CODE" = "000" ]; then
        log_warn "External access timeout (Cloudflare Tunnel may be down)"
    else
        log_warn "External access returned HTTP $EXTERNAL_CODE"
    fi
else
    log_info "curl not available for external testing"
fi

# ========================================
# Phase 8: Backup Verification
# ========================================
echo ""
echo -e "${BLUE}Phase 8: Backup Verification${NC}"
echo ""

BACKUP_COUNT=$(ls -d /var/www/html/forms.backup.* 2>/dev/null | wc -l)

if [ "$BACKUP_COUNT" -gt 0 ]; then
    log_pass "Backup directories found: $BACKUP_COUNT"

    # Check if too many backups
    if [ "$BACKUP_COUNT" -gt 5 ]; then
        log_warn "Too many backups ($BACKUP_COUNT). Consider cleaning up old ones."
    fi

    # Show latest backup
    LATEST_BACKUP=$(ls -dt /var/www/html/forms.backup.* 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        log_info "Latest backup: $(basename $LATEST_BACKUP)"
    fi
else
    log_warn "No backup directories found"
fi

# ========================================
# Phase 9: Web Server Status
# ========================================
echo ""
echo -e "${BLUE}Phase 9: Web Server Status${NC}"
echo ""

if command -v systemctl &> /dev/null; then
    if systemctl is-active --quiet nginx; then
        log_pass "nginx is running"
    else
        log_fail "nginx" "nginx is not running"
    fi

    # Check nginx error log (recent errors)
    if [ -f "/var/log/nginx/error.log" ]; then
        RECENT_ERRORS=$(tail -10 /var/log/nginx/error.log 2>/dev/null | grep -i "error" | wc -l)
        if [ "$RECENT_ERRORS" -eq 0 ]; then
            log_pass "No recent errors in nginx log"
        else
            log_warn "Found $RECENT_ERRORS recent errors in nginx log"
        fi
    fi
fi

# ========================================
# Summary
# ========================================
echo ""
echo "==================================="
echo "Summary"
echo "==================================="
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${YELLOW}Warnings: $WARN${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo "Total: $((PASS + WARN + FAIL))"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}===================================${NC}"
    echo -e "${GREEN}Deployment verification PASSED${NC}"
    echo -e "${GREEN}===================================${NC}"

    if [ $WARN -eq 0 ]; then
        echo ""
        echo -e "${GREEN}All checks passed successfully!${NC}"
        echo "Your deployment is ready for production use."
    else
        echo ""
        echo -e "${YELLOW}Deployment passed with warnings.${NC}"
        echo "Review warnings above for potential improvements."
    fi

    exit 0
else
    echo -e "${RED}===================================${NC}"
    echo -e "${RED}Deployment verification FAILED${NC}"
    echo -e "${RED}===================================${NC}"
    echo ""
    echo "Critical failures detected:"
    echo "1. Review failures above"
    echo "2. Check deployment logs: tail -f $HOME/mcp-agent-deploy.log"
    echo "3. Consider rollback if necessary"
    exit 1
fi
