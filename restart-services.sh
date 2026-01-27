#!/bin/bash
# Quick Service Restart Script for Raspberry Pi
# Restarts nginx and n8n services

set -e

echo "==================================="
echo "Service Restart Script"
echo "==================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ========================================
# Restart nginx
# ========================================
echo -e "${YELLOW}Restarting nginx...${NC}"
if systemctl is-active --quiet nginx; then
    sudo systemctl restart nginx
    echo -e "${GREEN}✓ nginx restarted successfully${NC}"
else
    echo -e "${YELLOW}⚠ nginx is not running${NC}"
    sudo systemctl start nginx
    echo -e "${GREEN}✓ nginx started${NC}"
fi

# ========================================
# Restart n8n
# ========================================
echo -e "${YELLOW}Restarting n8n...${NC}"
if docker ps | grep -q n8n; then
    docker restart n8n
    echo -e "${GREEN}✓ n8n container restarted${NC}"
elif systemctl is-active --quiet n8n; then
    sudo systemctl restart n8n
    echo -e "${GREEN}✓ n8n service restarted${NC}"
else
    echo -e "${YELLOW}⚠ n8n not found (not running or not installed)${NC}"
fi

# ========================================
# Status Check
# ========================================
echo ""
echo -e "${YELLOW}Service Status:${NC}"
echo ""

echo "nginx:"
if systemctl is-active --quiet nginx; then
    echo -e "  ${GREEN}● Running${NC}"
else
    echo -e "  ${RED}● Stopped${NC}"
fi

echo ""
echo "n8n:"
if docker ps | grep -q n8n; then
    echo -e "  ${GREEN}● Running (Docker)${NC}"
elif systemctl is-active --quiet n8n; then
    echo -e "  ${GREEN}● Running (Service)${NC}"
else
    echo -e "  ${RED}● Stopped${NC}"
fi

echo ""
echo -e "${GREEN}==================================="
echo "Restart completed!"
echo "===================================${NC}"
echo ""
