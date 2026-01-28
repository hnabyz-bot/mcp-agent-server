#!/bin/bash
# Pre-flight Check Script
# Purpose: Automated validation before deployment
# Usage: ./scripts/pre-flight-check.sh

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
echo "Pre-deployment Checklist"
echo "==================================="
echo ""

# ========================================
# Phase 1: File Existence Validation
# ========================================
echo -e "${BLUE}Phase 1: File Existence${NC}"
echo ""

CORE_FILES=(
    "forms-interface/index.html"
    "forms-interface/script.js"
    "forms-interface/styles.css"
)

for file in "${CORE_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_pass "$file exists"
    else
        log_fail "$file" "File not found"
    fi
done

# ========================================
# Phase 2: Filename Consistency
# ========================================
echo ""
echo -e "${BLUE}Phase 2: Filename Consistency${NC}"
echo ""

# Check for style.css (should be styles.css)
if [ -f "forms-interface/style.css" ]; then
    log_fail "forms-interface/style.css" "Should be styles.css (plural)"
fi

# Check for styles.css (correct)
if [ -f "forms-interface/styles.css" ]; then
    log_pass "Correct filename: styles.css"
fi

# Verify no unexpected CSS files
CSS_COUNT=$(find forms-interface -maxdepth 1 -name "*.css" 2>/dev/null | wc -l)
if [ "$CSS_COUNT" -eq 1 ]; then
    log_pass "Only one CSS file found"
else
    log_warn "Found $CSS_COUNT CSS files (expected 1)"
fi

# ========================================
# Phase 3: Script Permissions
# ========================================
echo ""
echo -e "${BLUE}Phase 3: Script Permissions${NC}"
echo ""

DEPLOYMENT_SCRIPTS=(
    "deploy-and-restart.sh"
    "setup-raspberry-pi.sh"
)

for script in "${DEPLOYMENT_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            log_pass "$script is executable"
        else
            log_warn "$script is NOT executable"
            chmod +x "$script"
            log_info "Fixed: chmod +x $script"
        fi
    else
        log_warn "$script not found (may not exist yet)"
    fi
done

# ========================================
# Phase 4: Network Connectivity
# ========================================
echo ""
echo -e "${BLUE}Phase 4: Network Connectivity${NC}"
echo ""

if ping -c 1 -W 2 github.com &> /dev/null; then
    log_pass "GitHub is reachable"
else
    log_fail "GitHub" "Cannot reach github.com"
fi

# Check git remote access
if git ls-remote origin &> /dev/null; then
    log_pass "Git remote accessible"
else
    log_fail "Git remote" "Cannot access remote repository"
fi

# ========================================
# Phase 5: Git Status
# ========================================
echo ""
echo -e "${BLUE}Phase 5: Git Status${NC}"
echo ""

if git rev-parse --git-dir > /dev/null 2>&1; then
    log_pass "Git repository detected"

    # Check for uncommitted changes
    if git diff --quiet && git diff --cached --quiet; then
        log_pass "Working directory is clean"
    else
        CHANGED_FILES=$(git status --porcelain | wc -l)
        log_warn "$CHANGED_FILES uncommitted changes detected"
        log_info "Consider: git stash push -u -m 'auto-stash-before-deploy'"
    fi

    # Check if branch is up to date
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u} 2>/dev/null)
    if [ -n "$REMOTE" ]; then
        if [ "$LOCAL" = "$REMOTE" ]; then
            log_pass "Branch is up to date with origin"
        else
            log_warn "Local differs from origin"
            log_info "Consider: git fetch origin && git reset --hard origin/main"
        fi
    else
        log_warn "No upstream branch configured"
    fi
else
    log_fail "Git" "Not a git repository"
fi

# ========================================
# Phase 6: Cache Version
# ========================================
echo ""
echo -e "${BLUE}Phase 6: Cache Version${NC}"
echo ""

if [ -f "forms-interface/index.html" ]; then
    CURRENT_VERSION=$(grep -oP 'script\.js\?v=\K[0-9.]+' forms-interface/index.html 2>/dev/null || echo "0.0.0")

    if [ "$CURRENT_VERSION" != "0.0.0" ]; then
        log_pass "Cache version: $CURRENT_VERSION"
    else
        log_warn "Could not parse cache version"
    fi

    # Verify script.js?v= exists
    if grep -q 'script\.js?v=' forms-interface/index.html; then
        log_pass "Cache version parameter present"
    else
        log_fail "Cache version" "script.js?v= parameter not found"
    fi
else
    log_fail "Cache version" "forms-interface/index.html not found"
fi

# ========================================
# Phase 7: Web Server Status
# ========================================
echo ""
echo -e "${BLUE}Phase 7: Web Server Status${NC}"
echo ""

if command -v systemctl &> /dev/null; then
    if systemctl is-active --quiet nginx; then
        log_pass "nginx is running"
    else
        log_warn "nginx is not running"
    fi

    # Test nginx configuration
    if nginx -t 2>&1 | grep -q "successful"; then
        log_pass "nginx configuration is valid"
    else
        log_warn "nginx configuration has issues"
    fi
else
    log_info "systemctl not available (not running on Raspberry Pi?)"
fi

# ========================================
# Phase 8: Disk Space
# ========================================
echo ""
echo -e "${BLUE}Phase 8: Disk Space${NC}"
echo ""

DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 90 ]; then
    log_pass "Disk usage: ${DISK_USAGE}%"
else
    log_warn "Disk usage high: ${DISK_USAGE}%"
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
    echo -e "${GREEN}All critical checks passed!${NC}"
    if [ $WARN -eq 0 ]; then
        echo -e "${GREEN}Ready to deploy.${NC}"
        exit 0
    else
        echo -e "${YELLOW}Review warnings before proceeding.${NC}"
        exit 0
    fi
else
    echo -e "${RED}Deployment blocked by failures.${NC}"
    echo ""
    echo "Please resolve the failures above before deploying."
    exit 1
fi
