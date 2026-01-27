#!/bin/bash
# Raspberry Pi Initial Setup Script for mcp-agent-server
# Run this once after cloning the repository

set -e

echo "==================================="
echo "Raspberry Pi Initial Setup"
echo "==================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project directory
PROJECT_DIR="$(pwd)"
FORMS_DIR="$PROJECT_DIR/forms-interface"

# ========================================
# Step 1: Install web server
# ========================================
echo -e "${BLUE}Step 1: Installing web server...${NC}"

if ! command -v nginx &> /dev/null && ! command -v apache2 &> /dev/null; then
    echo -e "${YELLOW}No web server detected. Installing nginx...${NC}"
    sudo apt update
    sudo apt install -y nginx
    echo -e "${GREEN}✓ nginx installed${NC}"
else
    echo -e "${GREEN}✓ Web server already installed${NC}"
fi
echo ""

# ========================================
# Step 2: Configure permissions
# ========================================
echo -e "${BLUE}Step 2: Configuring permissions...${NC}"

# Ensure ownership
sudo chown -R $(whoami):$(whoami) "$PROJECT_DIR"
chmod -R 755 "$FORMS_DIR"

echo -e "${GREEN}✓ Permissions configured${NC}"
echo ""

# ========================================
# Step 3: Set deployment script as executable
# ========================================
echo -e "${BLUE}Step 3: Making deployment script executable...${NC}"

chmod +x "$PROJECT_DIR/deploy-and-restart.sh"

echo -e "${GREEN}✓ Deployment script is now executable${NC}"
echo ""

# ========================================
# Step 4: Create systemd service (optional)
# ========================================
echo -e "${BLUE}Step 4: Creating auto-pull service...${NC}"

read -p "Do you want to enable auto-pull on boot? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Create systemd service file
    sudo tee /etc/systemd/system/mcp-agent-server-update.service > /dev/null <<EOF
[Unit]
Description=MCP Agent Server Auto-Update
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=$(whoami)
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/deploy-and-restart.sh

[Install]
WantedBy=multi-user.target
EOF

    # Create systemd timer for auto-update
    sudo tee /etc/systemd/system/mcp-agent-server-update.timer > /dev/null <<EOF
[Unit]
Description=MCP Agent Server Auto-Update Timer
Requires=mcp-agent-server-update.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=1h

[Install]
WantedBy=timers.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable mcp-agent-server-update.timer
    sudo systemctl start mcp-agent-server-update.timer

    echo -e "${GREEN}✓ Auto-pull service enabled (updates every hour)${NC}"
else
    echo -e "${YELLOW}⊘ Auto-pull service skipped${NC}"
fi
echo ""

# ========================================
# Complete
# ========================================
echo -e "${GREEN}==================================="
echo "Setup completed successfully!"
echo "===================================${NC}"
echo ""
echo "Quick Start:"
echo "  1. Deploy manually: sudo ./deploy-and-restart.sh"
echo "  2. Or wait for auto-update (if enabled)"
echo ""
echo "Access URLs:"
echo "  → http://localhost/forms"
echo "  → https://forms.abyz-lab.work"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  • Files are set to read-only after deployment"
echo "  • Make changes on Windows, then push to GitHub"
echo "  • Run deploy script to deploy automatically"
echo "  • Git conflicts are auto-resolved"
echo ""
