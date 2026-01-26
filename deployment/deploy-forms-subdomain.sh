#!/bin/bash

# Forms Subdomain Deployment Script
# Purpose: Automates the deployment of forms.abyz-lab.work subdomain
# Usage: sudo ./deploy-forms-subdomain.sh
# Author: DevOps Team
# Date: 2026-01-26

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
TUNNEL_ID="<TUNNEL_ID>"  # Replace with actual tunnel ID
DOMAIN="forms.abyz-lab.work"
NGINX_PORT=8080
N8N_PORT=5678

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Forms Subdomain Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run this script as root (sudo)${NC}"
    exit 1
fi

# Function to print section headers
print_section() {
    echo ""
    echo -e "${YELLOW}>>> $1${NC}"
    echo ""
}

# Function to verify command success
verify_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 completed successfully${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

# Phase 1: System Update
print_section "Phase 1: System Update"
echo "Updating package list..."
apt update
verify_success "Package update"

# Phase 2: Install nginx
print_section "Phase 2: Install nginx"
if ! command -v nginx &> /dev/null; then
    echo "Installing nginx..."
    apt install nginx -y
    verify_success "nginx installation"
else
    echo -e "${GREEN}✓ nginx already installed${NC}"
fi

# Phase 3: Backup existing configuration
print_section "Phase 3: Backup Existing Configuration"
BACKUP_DIR="/tmp/forms-deployment-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ -f ~/.cloudflared/config.yml ]; then
    cp ~/.cloudflared/config.yml "$BACKUP_DIR/config.yml.backup"
    echo -e "${GREEN}✓ Backed up cloudflared config.yml${NC}"
fi

if [ -f /etc/nginx/sites-available/$DOMAIN ]; then
    cp /etc/nginx/sites-available/$DOMAIN "$BACKUP_DIR/nginx-$DOMAIN.backup"
    echo -e "${GREEN}✓ Backed up existing nginx configuration${NC}"
fi

# Phase 4: Create web root directory
print_section "Phase 4: Create Web Root Directory"
WEB_ROOT="/var/www/$DOMAIN"
echo "Creating web root at $WEB_ROOT..."
mkdir -p "$WEB_ROOT"
chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"
verify_success "Web root directory creation"

# Phase 5: Copy nginx configuration
print_section "Phase 5: Deploy nginx Configuration"
echo "Copying nginx configuration..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINX_CONFIG="$SCRIPT_DIR/../config/nginx-forms.conf"

if [ -f "$NGINX_CONFIG" ]; then
    cp "$NGINX_CONFIG" /etc/nginx/sites-available/$DOMAIN
    verify_success "nginx configuration copy"
else
    echo -e "${RED}Error: nginx configuration file not found at $NGINX_CONFIG${NC}"
    echo "Please copy config/nginx-forms.conf manually"
    exit 1
fi

# Create symbolic link if it doesn't exist
if [ ! -L /etc/nginx/sites-enabled/$DOMAIN ]; then
    ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN
    verify_success "nginx site enable"
else
    echo -e "${GREEN}✓ nginx site already enabled${NC}"
fi

# Phase 6: Update cloudflared configuration
print_section "Phase 6: Update Cloudflare Tunnel Configuration"
echo "Updating cloudflared config.yml..."
TUNNEL_CONFIG="$SCRIPT_DIR/../config/cloudflare-tunnel-config.yaml"

if [ -f "$TUNNEL_CONFIG" ]; then
    # Note: Manual step required to update tunnel ID
    echo -e "${YELLOW}⚠ WARNING: You must manually update the tunnel ID in $TUNNEL_CONFIG${NC}"
    echo -e "${YELLOW}           Then update ~/.cloudflared/config.yml${NC}"
    echo ""
    echo "To update tunnel configuration:"
    echo "1. Edit $TUNNEL_CONFIG and replace <TUNNEL_ID> with actual tunnel ID"
    echo "2. Copy to ~/.cloudflared/config.yml:"
    echo "   sudo cp $TUNNEL_CONFIG ~/.cloudflared/config.yml"
    echo "3. Restart cloudflared:"
    echo "   sudo systemctl restart cloudflared"
else
    echo -e "${RED}Error: Tunnel configuration file not found at $TUNNEL_CONFIG${NC}"
fi

# Phase 7: Test nginx configuration
print_section "Phase 7: Test nginx Configuration"
echo "Testing nginx configuration..."
nginx -t
if [ $? -eq 0 ]; then
    verify_success "nginx configuration test"
else
    echo -e "${RED}✗ nginx configuration test failed${NC}"
    echo "Restoring backup..."
    if [ -f "$BACKUP_DIR/nginx-$DOMAIN.backup" ]; then
        cp "$BACKUP_DIR/nginx-$DOMAIN.backup" /etc/nginx/sites-available/$DOMAIN
    fi
    exit 1
fi

# Phase 8: Reload nginx
print_section "Phase 8: Reload nginx"
echo "Reloading nginx..."
systemctl reload nginx
verify_success "nginx reload"

# Phase 9: Enable nginx to start on boot
print_section "Phase 9: Enable nginx on Boot"
systemctl enable nginx
verify_success "nginx enable on boot"

# Phase 10: Verify services
print_section "Phase 10: Verify Services"
echo "Checking service status..."

# Check nginx
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ nginx is running${NC}"
else
    echo -e "${RED}✗ nginx is not running${NC}"
fi

# Check cloudflared
if systemctl is-active --quiet cloudflared; then
    echo -e "${GREEN}✓ cloudflared is running${NC}"
else
    echo -e "${YELLOW}⚠ cloudflared is not running (may need restart after config update)${NC}"
fi

# Check port availability
echo ""
echo "Checking port availability..."
if netstat -tlnp 2>/dev/null | grep -q ":$NGINX_PORT "; then
    echo -e "${GREEN}✓ Port $NGINX_PORT is in use (nginx)${NC}"
else
    echo -e "${YELLOW}⚠ Port $NGINX_PORT is not in use${NC}"
fi

if netstat -tlnp 2>/dev/null | grep -q ":$N8N_PORT "; then
    echo -e "${GREEN}✓ Port $N8N_PORT is in use (n8n)${NC}"
else
    echo -e "${YELLOW}⚠ Port $N8N_PORT is not in use (n8n may not be running)${NC}"
fi

# Phase 11: Next steps
print_section "Deployment Completed"
echo -e "${GREEN}✓ Base deployment completed successfully!${NC}"
echo ""
echo "Backup location: $BACKUP_DIR"
echo ""
echo -e "${YELLOW}=== REMAINING MANUAL TASKS ===${NC}"
echo ""
echo "1. Update Cloudflare DNS:"
echo "   - Go to Cloudflare Dashboard → DNS → Records"
echo "   - Add CNAME record:"
echo "     Name: forms"
echo "     Target: $TUNNEL_ID.cfargotunnel.com"
echo "     Proxy: Proxied (orange cloud)"
echo ""
echo "2. Update cloudflared configuration:"
echo "   - Replace <TUNNEL_ID> in config/cloudflare-tunnel-config.yaml"
echo "   - Copy to ~/.cloudflared/config.yml"
echo "   - Restart: sudo systemctl restart cloudflared"
echo ""
echo "3. Create HTML form:"
echo "   - Place HTML files in $WEB_ROOT"
echo "   - Example: deployment/forms-subdomain-setup.md contains sample form"
echo ""
echo "4. Configure SSL certificate:"
echo "   Option A: Let's Encrypt"
echo "     sudo certbot --nginx -d $DOMAIN"
echo ""
echo "   Option B: Cloudflare Origin Certificate (recommended)"
echo "     - Download from Cloudflare Dashboard → SSL/TLS → Origin Server"
echo "     - Save to /etc/cloudflare/"
echo "     - Update nginx config to use certificate"
echo ""
echo "5. Create n8n webhook:"
echo "   - Access n8n at https://api.abyz-lab.work"
echo "   - Create workflow with Webhook trigger"
echo "   - Set webhook path: /webhook/form-submit"
echo "   - Update nginx /submit location to proxy to webhook"
echo ""
echo "6. Test deployment:"
echo "   - DNS: dig $DOMAIN"
echo "   - HTTP: curl -I http://$DOMAIN"
echo "   - HTTPS: curl -I https://$DOMAIN"
echo "   - Form: Test form submission in browser"
echo ""
echo "7. Configure security and caching:"
echo "   - See deployment/forms-subdomain-setup.md for detailed guide"
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Script Complete${NC}"
echo -e "${GREEN}========================================${NC}"
