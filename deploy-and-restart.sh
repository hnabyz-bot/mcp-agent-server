#!/bin/bash
# Complete Deployment Script for forms-interface
# This script handles git pull, deployment, cache busting, and service restart

set -e  # Exit on error

echo "==================================="
echo "Forms Interface Auto-Deployment"
echo "==================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project directory
PROJECT_DIR="$(pwd)"
FORMS_DIR="$PROJECT_DIR/forms-interface"

# ========================================
# Step 1: Git Pull
# ========================================
echo -e "${BLUE}Step 1: Pulling latest changes...${NC}"
git pull origin main
echo -e "${GREEN}✓ Git pull completed${NC}"
echo ""

# ========================================
# Step 2: Read current version (NO modification)
# ========================================
echo -e "${BLUE}Step 2: Reading cache version...${NC}"

# Read current version from index.html
CURRENT_VERSION=$(grep -oP 'script\.js\?v=\K[0-9.]+(?=["<])' forms-interface/index.html 2>/dev/null || echo "1.0.0")

echo -e "${GREEN}✓ Current cache version: ${CURRENT_VERSION}${NC}"
echo -e "${YELLOW}Note: Version is managed on Windows, not modified here${NC}"
echo ""

# ========================================
# Step 3: Detect web server
# ========================================
echo -e "${BLUE}Step 3: Detecting web server...${NC}"

WEB_SERVER=""
DOC_ROOT=""

if command -v nginx &> /dev/null || systemctl is-active --quiet nginx; then
    WEB_SERVER="nginx"
    DOC_ROOT="/var/www/html"
    echo -e "${GREEN}✓ Detected: nginx${NC}"
elif command -v apache2 &> /dev/null || systemctl is-active --quiet apache2; then
    WEB_SERVER="apache"
    DOC_ROOT="/var/www/html"
    echo -e "${GREEN}✓ Detected: Apache${NC}"
else
    echo -e "${YELLOW}⚠ No standard web server detected${NC}"
    echo "Please specify deployment directory:"
    read -p "Path: " DOC_ROOT
    WEB_SERVER="custom"
fi

echo ""

# ========================================
# Step 4: Deploy
# ========================================
echo -e "${BLUE}Step 4: Deploying to ${DOC_ROOT}...${NC}"

# Backup existing deployment
if [ -d "${DOC_ROOT}/forms" ]; then
    BACKUP_DIR="${DOC_ROOT}/forms.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}Backing up existing deployment...${NC}"
    sudo mv "${DOC_ROOT}/forms" "$BACKUP_DIR"
fi

# Create symbolic link
echo -e "${YELLOW}Creating symbolic link...${NC}"
sudo ln -sf "$FORMS_DIR" "${DOC_ROOT}/forms"

# Set permissions
echo -e "${YELLOW}Setting permissions...${NC}"
sudo chown -R www-data:www-data "$FORMS_DIR"
sudo chmod -R 755 "$FORMS_DIR"

echo -e "${GREEN}✓ Deployment completed${NC}"
echo ""

# ========================================
# Step 5: Restart services
# ========================================
echo -e "${BLUE}Step 5: Restarting web server...${NC}"

case $WEB_SERVER in
    nginx)
        sudo systemctl restart nginx
        echo -e "${GREEN}✓ nginx restarted${NC}"
        ;;
    apache)
        sudo systemctl restart apache2
        echo -e "${GREEN}✓ Apache restarted${NC}"
        ;;
    custom)
        echo -e "${YELLOW}⚠ Custom deployment - please restart web server manually${NC}"
        ;;
esac

echo ""

# ========================================
# Step 6: Verify deployment
# ========================================
echo -e "${BLUE}Step 6: Verifying deployment...${NC}"

# Check if symbolic link exists
if [ -L "${DOC_ROOT}/forms" ]; then
    echo -e "${GREEN}✓ Symbolic link exists${NC}"
else
    echo -e "${RED}✗ Symbolic link not found${NC}"
    exit 1
fi

# Check if script.js exists
if [ -f "${DOC_ROOT}/forms/script.js" ]; then
    echo -e "${GREEN}✓ script.js found${NC}"
else
    echo -e "${RED}✗ script.js not found${NC}"
    exit 1
fi

# Check email field in script.js
if grep -q "formData.append('email'" "${DOC_ROOT}/forms/script.js"; then
    echo -e "${GREEN}✓ Email field present in script.js${NC}"
else
    echo -e "${RED}✗ Email field missing from script.js${NC}"
    exit 1
fi

# Check cache version in index.html
if grep -q "script.js?v=${CURRENT_VERSION}" "${DOC_ROOT}/forms/index.html"; then
    echo -e "${GREEN}✓ Cache version ${CURRENT_VERSION} verified in index.html${NC}"
else
    echo -e "${RED}✗ Cache version mismatch${NC}"
    echo -e "${YELLOW}Expected: ${CURRENT_VERSION}${NC}"
    exit 1
fi

echo ""

# ========================================
# Step 7: Display deployment summary
# ========================================
echo -e "${BLUE}Step 7: Deployment complete!${NC}"
echo -e "${YELLOW}Note: Version was already updated on Windows before git push${NC}"
echo ""

# ========================================
# Complete
# ========================================
echo -e "${GREEN}==================================="
echo "Deployment completed successfully!"
echo "===================================${NC}"
echo ""
echo "Deployment Summary:"
echo "  Cache Version: ${CURRENT_VERSION}"
echo "  Web Server: ${WEB_SERVER}"
echo "  Deployment Path: ${DOC_ROOT}/forms"
echo ""
echo "Access URLs:"
echo "  → http://localhost/forms"
echo "  → https://forms.abyz-lab.work"
echo ""
echo -e "${YELLOW}Important: Clear browser cache to see changes!${NC}"
echo "  Windows/Linux: Ctrl + Shift + R"
echo "  Mac: Cmd + Shift + R"
echo "  Or use Incognito/Private mode"
echo ""
