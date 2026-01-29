#!/bin/bash
# Forms Interface Deployment Script
# This script deploys the forms-interface to the web server

set -e  # Exit on error

echo "==================================="
echo "Forms Interface Deployment Script"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project directory
PROJECT_DIR="$(pwd)"
FORMS_DIR="$PROJECT_DIR/forms-interface"

# Check if we're in the right directory
if [ ! -d "$FORMS_DIR" ]; then
    echo -e "${RED}Error: forms-interface directory not found!${NC}"
    echo "Please run this script from the mcp-agent-server directory."
    exit 1
fi

# Step 1: Pull latest changes
echo -e "${YELLOW}Step 1: Pulling latest changes from git...${NC}"
git pull origin main
echo -e "${GREEN}✓ Git pull completed${NC}"
echo ""

# Step 2: Detect web server
echo -e "${YELLOW}Step 2: Detecting web server...${NC}"

WEB_SERVER=""
DOC_ROOT=""

# Check for nginx
if command -v nginx &> /dev/null || docker ps | grep -q nginx; then
    WEB_SERVER="nginx"
    DOC_ROOT="/var/www/html"
    echo -e "${GREEN}✓ Detected: nginx${NC}"
fi

# Check for apache2
if command -v apache2 &> /dev/null || docker ps | grep -q apache; then
    WEB_SERVER="apache"
    DOC_ROOT="/var/www/html"
    echo -e "${GREEN}✓ Detected: Apache${NC}"
fi

# If no web server detected, ask user
if [ -z "$WEB_SERVER" ]; then
    echo -e "${YELLOW}No standard web server detected.${NC}"
    echo ""
    echo "Please choose deployment method:"
    echo "1) nginx (/var/www/html)"
    echo "2) Apache (/var/www/html)"
    echo "3) Custom directory"
    echo "4) Start standalone HTTP server (port 8080)"
    echo ""
    read -p "Enter choice (1-4): " choice

    case $choice in
        1)
            WEB_SERVER="nginx"
            DOC_ROOT="/var/www/html"
            ;;
        2)
            WEB_SERVER="apache"
            DOC_ROOT="/var/www/html"
            ;;
        3)
            read -p "Enter custom directory path: " DOC_ROOT
            WEB_SERVER="custom"
            ;;
        4)
            WEB_SERVER="standalone"
            ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac
fi

echo ""

# Step 3: Deploy based on web server type
case $WEB_SERVER in
    nginx|apache|custom)
        echo -e "${YELLOW}Step 3: Deploying to $DOC_ROOT...${NC}"

        # Backup existing deployment if exists
        if [ -d "$DOC_ROOT/forms" ]; then
            echo -e "${YELLOW}Backing up existing forms directory...${NC}"
            sudo mv "$DOC_ROOT/forms" "$DOC_ROOT/forms.backup.$(date +%Y%m%d_%H%M%S)"
        fi

        # Create symbolic link
        echo -e "${YELLOW}Creating symbolic link...${NC}"
        sudo ln -sf "$FORMS_DIR" "$DOC_ROOT/forms"

        # Set permissions (KEEP USER OWNERSHIP for Git compatibility)
        echo -e "${YELLOW}Setting permissions...${NC}"
        # NO chown needed - keep user ownership (e.g., raspi:raspi)
        # Directories: 755 (rwxr-xr-x) - owner full, group/others read+execute
        sudo find "$FORMS_DIR" -type d -exec chmod 755 {} \;
        # Files: 644 (rw-r--r--) - owner read+write, group/others read-only
        sudo find "$FORMS_DIR" -type f -exec chmod 644 {} \;

        # Configure nginx for forms (local testing)
        if [ "$WEB_SERVER" = "nginx" ]; then
            echo -e "${YELLOW}Configuring nginx for local access...${NC}"

            # Create nginx config snippet for forms
            NGINX_FORMS_CONF="/etc/nginx/snippets/forms-location.conf"
            sudo tee "$NGINX_FORMS_CONF" > /dev/null << 'EOF'
# Forms interface location configuration
location /forms {
    alias /home/raspi/workspace/mcp-agent-server/forms-interface;
    index index.html;
    try_files $uri $uri/ /forms/index.html =404;
}
EOF

            # Check if snippet is already included in main config
            if ! grep -q "snippets/forms-location.conf" /etc/nginx/sites-enabled/default; then
                # Insert snippet include before the closing brace
                sudo sed -i '/^\s*}\s*$/i include snippets/forms-location.conf;' /etc/nginx/sites-enabled/default
            fi

            # Test nginx configuration
            if sudo nginx -t 2>/dev/null; then
                echo -e "${GREEN}✓ nginx configuration is valid${NC}"
                sudo systemctl reload nginx
                echo -e "${GREEN}✓ nginx reloaded${NC}"
            else
                echo -e "${RED}✗ nginx configuration test failed${NC}"
                echo "Skipping nginx reload. Local access may not work."
            fi
        fi

        echo -e "${GREEN}✓ Deployment completed${NC}"
        echo ""
        echo "Forms interface is now available at:"
        if [ "$WEB_SERVER" = "nginx" ] || [ "$WEB_SERVER" = "apache" ]; then
            echo "  → http://localhost/forms"
            echo "  → https://forms.abyz-lab.work (via Cloudflare Tunnel)"
        fi
        ;;

    standalone)
        echo -e "${YELLOW}Step 3: Starting standalone HTTP server...${NC}"
        echo ""
        echo "Starting HTTP server on port 8080..."
        echo "Press Ctrl+C to stop the server"
        echo ""

        cd "$FORMS_DIR"
        python3 -m http.server 8080
        ;;
esac

# Step 4: Verify deployment
if [ "$WEB_SERVER" = "nginx" ] || [ "$WEB_SERVER" = "apache" ]; then
    echo ""
    echo -e "${YELLOW}Step 4: Verifying deployment...${NC}"

    # Check symbolic link
    if [ -L "$DOC_ROOT/forms" ]; then
        echo -e "${GREEN}✓ Symbolic link exists${NC}"
    else
        echo -e "${RED}✗ Symbolic link not found${NC}"
        exit 1
    fi

    # Check file permissions
    PERM=$(stat -c "%a" "$FORMS_DIR/index.html" 2>/dev/null || stat -f "%A" "$FORMS_DIR/index.html")
    if [ "$PERM" = "644" ]; then
        echo -e "${GREEN}✓ File permissions correct (644)${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: Unexpected permissions: $PERM (expected 644)${NC}"
    fi

    # Test HTTP access
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/forms/ 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ HTTP access working (200)${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: HTTP returned code $HTTP_CODE${NC}"
    fi

    echo -e "${GREEN}✓ Deployment verification completed${NC}"
fi

echo ""
echo -e "${GREEN}==================================="
echo "Deployment completed successfully!"
echo "===================================${NC}"
echo ""
echo "Test the form at: https://forms.abyz-lab.work"
echo ""
