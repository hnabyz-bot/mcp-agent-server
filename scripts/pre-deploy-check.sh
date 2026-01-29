#!/bin/bash
# Pre-deployment Check Script
# This script verifies the environment is ready for deployment
# Run this before deploy-forms.sh to prevent deployment failures

set -e

echo "==================================="
echo "Pre-deployment Check"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Check 1: Git status
echo -e "${YELLOW}Check 1: Git status${NC}"
if git diff --quiet && git diff --cached --quiet; then
    echo -e "${GREEN}✓ Git working directory is clean${NC}"
else
    echo -e "${RED}✗ Uncommitted changes detected${NC}"
    echo "  Please commit or stash changes before deployment:"
    echo "  - git commit -m 'Your message'"
    echo "  - or git stash"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 2: File ownership
echo -e "${YELLOW}Check 2: File ownership${NC}"
if [ -d "forms-interface" ]; then
    OWNER=$(stat -c "%U:%G" forms-interface/ 2>/dev/null || stat -f "%Su:%Sg" forms-interface/)
    CURRENT_USER=$(whoami)
    EXPECTED_OWNER="${CURRENT_USER}:${CURRENT_USER}"

    if [ "$OWNER" = "$EXPECTED_OWNER" ]; then
        echo -e "${GREEN}✓ File ownership is correct ($OWNER)${NC}"
    else
        echo -e "${RED}✗ Unexpected ownership: $OWNER${NC}"
        echo "  Expected: $EXPECTED_OWNER"
        echo "  Fix: sudo chown -R $CURRENT_USER:$CURRENT_USER forms-interface/"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${RED}✗ forms-interface directory not found${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 3: Network connectivity
echo -e "${YELLOW}Check 3: Network connectivity${NC}"
if ping -c 1 -W 2 github.com &> /dev/null; then
    echo -e "${GREEN}✓ GitHub is reachable${NC}"
else
    echo -e "${RED}✗ Cannot reach GitHub${NC}"
    echo "  Check your internet connection"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 4: Disk space
echo -e "${YELLOW}Check 4: Disk space${NC}"
AVAILABLE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE" -gt 1 ]; then
    echo -e "${GREEN}✓ Sufficient disk space (${AVAILABLE}G available)${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Low disk space (${AVAILABLE}G available)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check 5: Web server status
echo -e "${YELLOW}Check 5: Web server status${NC}"
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ nginx is running${NC}"
elif systemctl is-active --quiet apache2; then
    echo -e "${GREEN}✓ apache2 is running${NC}"
else
    echo -e "${YELLOW}⚠ Warning: No web server detected${NC}"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Summary
echo "==================================="
echo "Check Summary"
echo "==================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed. Ready to deploy!${NC}"
    echo ""
    echo "Run: sudo ./deploy-forms.sh"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) detected${NC}"
    echo "You can proceed with deployment, but review warnings above."
    echo ""
    echo "Run: sudo ./deploy-forms.sh"
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) detected${NC}"
    echo "Please fix the errors above before deployment."
    exit 1
fi
