#!/bin/bash
# Complete Deployment Script for forms-interface (Improved Version)
# This script handles git pull, deployment, cache busting, and service restart

set -e  # Exit on error

# ============================================
# Configuration
# ============================================
LOG_FILE="$HOME/mcp-agent-deploy.log"
MAX_BACKUPS=5
FORMS_DIR="$(pwd)/forms-interface"
BACKUP_RETENTION_DAYS=7

# ============================================
# Logging Functions
# ============================================
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }

# ============================================
# Rollback Function
# ============================================
rollback() {
    log_error "Deployment failed. Rolling back..."

    if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
        sudo rm -rf "${DOC_ROOT}/forms" 2>/dev/null || true
        sudo mv "$BACKUP_DIR" "${DOC_ROOT}/forms"
        log_info "Rollback completed from $BACKUP_DIR"

        # Restart web server
        case $WEB_SERVER in
            nginx) sudo systemctl restart nginx ;;
            apache) sudo systemctl restart apache2 ;;
        esac

        log_info "Web server restarted after rollback"
    else
        log_error "No backup found for rollback"
    fi

    exit 1
}

# Trap errors for automatic rollback
trap rollback ERR

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

# ============================================
# Pre-flight Checks
# ============================================
log_info "Starting deployment process..."

# Check network connectivity
log_info "Checking network connectivity..."
if ! ping -c 1 -W 2 github.com &> /dev/null; then
    log_error "Cannot reach GitHub. Please check your internet connection."
    exit 1
fi
log_info "Network connectivity OK"

# Check if we're in the right directory
if [ ! -d "$FORMS_DIR" ]; then
    log_error "forms-interface directory not found!"
    exit 1
fi

# ============================================
# Step 1: Git Pull with Auto-Conflict Resolution
# ============================================
echo -e "${BLUE}Step 1: Pulling latest changes...${NC}"

# Check for local changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${YELLOW}⚠ Local changes detected. Stashing for safe pull...${NC}"

    # Create a timestamped stash
    STASH_NAME="auto-stash-before-pull-$(date +%Y%m%d_%H%M%S)"
    git stash push -u -m "$STASH_NAME"

    log_info "Local changes stashed as: $STASH_NAME"
    echo -e "${GREEN}✓ Local changes stashed${NC}"
    echo -e "${YELLOW}Note: Use 'git stash list' to review stashes${NC}"
    echo -e "${YELLOW}Note: Use 'git stash pop' to restore stashed changes${NC}"
fi

# Fetch and reset to avoid merge conflicts
log_info "Fetching from origin..."
git fetch origin main

log_info "Resetting to origin/main..."
git reset --hard origin/main

log_info "Git pull completed successfully"
echo -e "${GREEN}✓ Git pull completed (no conflicts)${NC}"
echo ""

# ============================================
# Step 2: Read current version (NO modification)
# ============================================
echo -e "${BLUE}Step 2: Reading cache version...${NC}"

# Read current version from index.html
CURRENT_VERSION=$(grep -oP 'script\.js\?v=\K[0-9.]+(?=["<])' forms-interface/index.html 2>/dev/null || echo "1.0.0")

log_info "Current cache version: ${CURRENT_VERSION}"
echo -e "${GREEN}✓ Current cache version: ${CURRENT_VERSION}${NC}"
echo -e "${YELLOW}Note: Version is managed on Windows, not modified here${NC}"
echo ""

# ============================================
# Step 3: Detect web server
# ============================================
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
    echo "Please specify deployment directory [default: /var/www/html]:"
    read -p "Path: " DOC_ROOT_INPUT
    DOC_ROOT=${DOC_ROOT_INPUT:-/var/www/html}
    WEB_SERVER="custom"
fi

log_info "Web server: $WEB_SERVER"
log_info "Deployment path: $DOC_ROOT"
echo ""

# ============================================
# Step 4: Deploy with Backup
# ============================================
echo -e "${BLUE}Step 4: Deploying to ${DOC_ROOT}...${NC}"

# Create deployment directory if not exists
if [ ! -d "$DOC_ROOT" ]; then
    log_info "Creating deployment directory: $DOC_ROOT"
    sudo mkdir -p "$DOC_ROOT"
fi

# Backup existing deployment
BACKUP_DIR=""
if [ -d "${DOC_ROOT}/forms" ] && [ -L "${DOC_ROOT}/forms" ]; then
    # Get actual path of symlink
    ACTUAL_PATH=$(readlink -f "${DOC_ROOT}/forms")
    BACKUP_DIR="${DOC_ROOT}/forms.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Backing up existing deployment..."
    sudo rm "${DOC_ROOT}/forms"  # Remove symlink first
    sudo cp -r "$ACTUAL_PATH" "$BACKUP_DIR"
    log_info "Backup created: $BACKUP_DIR"
elif [ -d "${DOC_ROOT}/forms" ]; then
    BACKUP_DIR="${DOC_ROOT}/forms.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Backing up existing deployment..."
    sudo mv "${DOC_ROOT}/forms" "$BACKUP_DIR"
    log_info "Backup created: $BACKUP_DIR"
fi

# Clean old backups (keep only MAX_BACKUPS most recent)
log_info "Cleaning old backups (keeping last $MAX_BACKUPS)..."
backup_count=$(ls -dt ${DOC_ROOT}/forms.backup.* 2>/dev/null | wc -l)
if [ $backup_count -gt $MAX_BACKUPS ]; then
    ls -dt ${DOC_ROOT}/forms.backup.* | tail -n +$((MAX_BACKUPS + 1)) | xargs -I {} sudo rm -rf {}
    log_info "Removed $((backup_count - MAX_BACKUPS)) old backups"
fi

# Create symbolic link
log_info "Creating symbolic link..."
sudo ln -sf "$FORMS_DIR" "${DOC_ROOT}/forms"
log_info "Symbolic link created: ${DOC_ROOT}/forms -> $FORMS_DIR"

# Set permissions (read-only for web server, keep ownership for git)
log_info "Setting permissions..."
sudo chmod -R 755 "$FORMS_DIR"
# Keep ownership as current user (raspi) to allow git operations
sudo chown -R $(whoami):$(whoami) "$FORMS_DIR"

# Set core files to read-only to prevent accidental modifications on Pi
log_info "Setting core files to read-only (prevents accidental edits)..."
chmod 444 "$FORMS_DIR/index.html"
chmod 444 "$FORMS_DIR/script.js"
chmod 444 "$FORMS_DIR/styles.css"
log_info "Core files set to read-only"

log_info "Deployment completed"
echo -e "${GREEN}✓ Deployment completed${NC}"
echo ""

# ============================================
# Step 5: Restart services
# ============================================
echo -e "${BLUE}Step 5: Restarting web server...${NC}"

case $WEB_SERVER in
    nginx)
        log_info "Testing nginx configuration..."
        if ! sudo nginx -t; then
            log_error "nginx configuration test failed"
            rollback
        fi

        log_info "Restarting nginx..."
        sudo systemctl restart nginx
        log_info "nginx restarted successfully"
        echo -e "${GREEN}✓ nginx restarted${NC}"
        ;;
    apache)
        log_info "Testing Apache configuration..."
        if ! sudo apache2ctl configtest; then
            log_error "Apache configuration test failed"
            rollback
        fi

        log_info "Restarting Apache..."
        sudo systemctl restart apache2
        log_info "Apache restarted successfully"
        echo -e "${GREEN}✓ Apache restarted${NC}"
        ;;
    custom)
        echo -e "${YELLOW}⚠ Custom deployment - please restart web server manually${NC}"
        ;;
esac

echo ""

# ============================================
# Step 6: Verify deployment
# ============================================
echo -e "${BLUE}Step 6: Verifying deployment...${NC}"

# Check if symbolic link exists
if [ -L "${DOC_ROOT}/forms" ]; then
    log_info "✓ Symbolic link exists"
    echo -e "${GREEN}✓ Symbolic link exists${NC}"
else
    log_error "Symbolic link not found"
    echo -e "${RED}✗ Symbolic link not found${NC}"
    rollback
fi

# Check if script.js exists
if [ -f "${DOC_ROOT}/forms/script.js" ]; then
    log_info "✓ script.js found"
    echo -e "${GREEN}✓ script.js found${NC}"
else
    log_error "script.js not found"
    echo -e "${RED}✗ script.js not found${NC}"
    rollback
fi

# Check email field in script.js
if grep -q "formData.append('email'" "${DOC_ROOT}/forms/script.js"; then
    log_info "✓ Email field present in script.js"
    echo -e "${GREEN}✓ Email field present in script.js${NC}"
else
    log_error "Email field missing from script.js"
    echo -e "${RED}✗ Email field missing from script.js${NC}"
    rollback
fi

# Check cache version in index.html
if grep -q "script.js?v=${CURRENT_VERSION}" "${DOC_ROOT}/forms/index.html"; then
    log_info "✓ Cache version ${CURRENT_VERSION} verified in index.html"
    echo -e "${GREEN}✓ Cache version ${CURRENT_VERSION} verified in index.html${NC}"
else
    log_error "Cache version mismatch (expected: ${CURRENT_VERSION})"
    echo -e "${RED}✗ Cache version mismatch${NC}"
    echo -e "${YELLOW}Expected: ${CURRENT_VERSION}${NC}"
    rollback
fi

echo ""

# ============================================
# Step 7: Display deployment summary
# ============================================
echo -e "${BLUE}Step 7: Deployment complete!${NC}"
log_info "Deployment completed successfully"
echo -e "${YELLOW}Note: Version was already updated on Windows before git push${NC}"
echo ""

# ============================================
# Complete
# ============================================
echo -e "${GREEN}==================================="
echo "Deployment completed successfully!"
echo "===================================${NC}"
echo ""
echo "Deployment Summary:"
echo "  Cache Version: ${CURRENT_VERSION}"
echo "  Web Server: ${WEB_SERVER}"
echo "  Deployment Path: ${DOC_ROOT}/forms"
echo "  Backup Location: ${BACKUP_DIR:-No backup needed}"
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
echo -e "${BLUE}Workflow Reminder:${NC}"
echo "  • Raspberry Pi is deployment-only (read-only)"
echo "  • Make changes on Windows, then push to GitHub"
echo "  • Run this script to deploy automatically"
echo "  • To edit files on Pi temporarily: chmod 644 <file>"
echo ""

# Display stash info if any
if git stash list | grep -q "auto-stash-before-pull"; then
    echo -e "${YELLOW}⚠ You have stashed changes:${NC}"
    git stash list | grep "auto-stash-before-pull" | tail -5
    echo ""
    echo "To restore stashed changes:"
    echo "  git stash pop"
    echo ""
fi

log_info "Deployment process finished"
echo ""
