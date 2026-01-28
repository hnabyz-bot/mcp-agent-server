#!/bin/bash
# Raspberry Pi Initial Setup Script for mcp-agent-server (Improved Version)
# Run this once after cloning the repository

set -e

# ============================================
# Configuration
# ============================================
LOG_FILE="/var/log/mcp-agent-setup.log"
UPDATE_INTERVAL_HOURS=6  # Changed from 1 hour to 6 hours

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

echo "==================================="
echo "Raspberry Pi Initial Setup"
echo "==================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Project directory
PROJECT_DIR="$(pwd)"
FORMS_DIR="$PROJECT_DIR/forms-interface"

# ============================================
# Pre-flight Checks
# ============================================
log_info "Starting setup process..."

if [ ! -d "$FORMS_DIR" ]; then
    log_error "forms-interface directory not found!"
    log_error "Please run this script from the project root directory."
    exit 1
fi

# ============================================
# Step 1: Install web server
# ============================================
echo -e "${BLUE}Step 1: Installing web server...${NC}"

if ! command -v nginx &> /dev/null && ! command -v apache2 &> /dev/null; then
    echo -e "${YELLOW}No web server detected. Installing nginx...${NC}"

    # Update package list
    log_info "Updating package list..."
    sudo apt update

    # Install nginx
    log_info "Installing nginx..."
    sudo apt install -y nginx

    # Enable nginx to start on boot
    sudo systemctl enable nginx

    echo -e "${GREEN}✓ nginx installed and enabled${NC}"
else
    echo -e "${GREEN}✓ Web server already installed${NC}"

    # Display which web server is installed
    if command -v nginx &> /dev/null; then
        echo -e "${BLUE}  → nginx${NC}"
    fi
    if command -v apache2 &> /dev/null; then
        echo -e "${BLUE}  → Apache${NC}"
    fi
fi
echo ""

# ============================================
# Step 2: Configure permissions
# ============================================
echo -e "${BLUE}Step 2: Configuring permissions...${NC}"

# Ensure ownership
log_info "Setting project directory ownership..."
sudo chown -R $(whoami):$(whoami) "$PROJECT_DIR"

# Set forms directory permissions
log_info "Setting forms directory permissions..."
chmod -R 755 "$FORMS_DIR"

echo -e "${GREEN}✓ Permissions configured${NC}"
echo ""

# ============================================
# Step 3: Set deployment script as executable
# ============================================
echo -e "${BLUE}Step 3: Making deployment script executable...${NC}"

chmod +x "$PROJECT_DIR/deploy-and-restart.sh"
chmod +x "$PROJECT_DIR/restart-services.sh"

echo -e "${GREEN}✓ Deployment scripts are now executable${NC}"
echo ""

# ============================================
# Step 4: Create log directory
# ============================================
echo -e "${BLUE}Step 4: Setting up logging...${NC}"

# Create log directory if it doesn't exist
if [ ! -d "/var/log" ]; then
    sudo mkdir -p /var/log
fi

# Grant write permission to log file (create if not exists)
if [ ! -f "$LOG_FILE" ]; then
    sudo touch "$LOG_FILE"
    sudo chmod 666 "$LOG_FILE"
fi

log_info "Log file created: $LOG_FILE"
echo -e "${GREEN}✓ Logging configured${NC}"
echo ""

# ============================================
# Step 5: Create systemd service (optional)
# ============================================
echo -e "${BLUE}Step 5: Creating auto-pull service...${NC}"

read -p "Do you want to enable auto-pull on boot? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Creating systemd service files..."

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
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true

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
OnUnitActiveSec=${UPDATE_INTERVAL_HOURS}h
AccuracySec=1h

[Install]
WantedBy=timers.target
EOF

    # Reload systemd and enable timer
    log_info "Reloading systemd daemon..."
    sudo systemctl daemon-reload

    log_info "Enabling timer..."
    sudo systemctl enable mcp-agent-server-update.timer

    log_info "Starting timer..."
    sudo systemctl start mcp-agent-server-update.timer

    # Display timer status
    echo ""
    echo -e "${GREEN}✓ Auto-pull service enabled${NC}"
    echo -e "${BLUE}  Update interval: Every ${UPDATE_INTERVAL_HOURS} hours${NC}"
    echo -e "${BLUE}  First update: 5 minutes after boot${NC}"
    echo ""
    echo "Timer status:"
    sudo systemctl status mcp-agent-server-update.timer --no-pager
    echo ""
else
    echo -e "${YELLOW}⊘ Auto-pull service skipped${NC}"
    echo -e "${YELLOW}  You can run deployment manually: sudo ./deploy-and-restart.sh${NC}"
fi
echo ""

# ============================================
# Step 6: Network connectivity check
# ============================================
echo -e "${BLUE}Step 6: Checking network connectivity...${NC}"

if ping -c 1 -W 2 github.com &> /dev/null; then
    echo -e "${GREEN}✓ GitHub connectivity OK${NC}"
else
    echo -e "${YELLOW}⚠ Cannot reach GitHub${NC}"
    echo -e "${YELLOW}  Please check your internet connection${NC}"
fi
echo ""

# ============================================
# Step 7: Display setup summary
# ============================================
echo -e "${GREEN}==================================="
echo "Setup completed successfully!"
echo "===================================${NC}"
echo ""
echo "Setup Summary:"
echo "  Project Directory: $PROJECT_DIR"
echo "  Forms Directory: $FORMS_DIR"
echo "  Log File: $LOG_FILE"
echo "  Web Server: $(command -v nginx &> /dev/null && echo 'nginx' || echo 'apache2')"
if [[ $REPLY =~ ^[Yy]$ ]] 2>/dev/null; then
    echo "  Auto-Update: Enabled (every ${UPDATE_INTERVAL_HOURS}h)"
else
    echo "  Auto-Update: Disabled"
fi
echo ""
echo "Quick Start:"
echo "  1. Deploy manually: sudo ./deploy-and-restart.sh"
echo "  2. Restart services: sudo ./restart-services.sh"
echo "  3. View logs: tail -f $LOG_FILE"
if [[ $REPLY =~ ^[Yy]$ ]] 2>/dev/null; then
    echo "  4. View timer: sudo systemctl status mcp-agent-server-update.timer"
fi
echo ""
echo "Access URLs:"
echo "  → http://localhost/forms"
echo "  → https://forms.abyz-lab.work"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  • Files are set to read-only after deployment"
echo "  • Make changes on Windows, then push to GitHub"
echo "  • Run deploy script to deploy automatically"
echo "  • Git conflicts are auto-resolved with stash"
echo "  • Deployment failures trigger automatic rollback"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Test deployment: sudo ./deploy-and-restart.sh"
echo "  2. Verify forms interface: http://localhost/forms"
echo "  3. Check logs for any issues: tail -f $LOG_FILE"
echo ""

log_info "Setup process completed successfully"
echo ""
