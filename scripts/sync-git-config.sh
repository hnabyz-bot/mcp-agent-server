#!/bin/bash
#
# sync-git-config.sh
#
# Copy git user configuration from Windows to Raspberry Pi
# Run this script on Raspberry Pi after cloning a project
#

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   Git Configuration Sync Tool${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Target configuration
TARGET_NAME="drake.lee"
TARGET_EMAIL="drake.lee@abyzr.com"

# Current configuration
echo -e "${YELLOW}Current git configuration:${NC}"
echo "  user.name: $(git config --global user.name || 'not set')"
echo "  user.email: $(git config --global user.email || 'not set')"
echo ""

# Apply configuration
echo -e "${GREEN}Applying Windows git configuration...${NC}"
git config --global user.name "$TARGET_NAME"
git config --global user.email "$TARGET_EMAIL"

# Apply additional Windows-compatible settings
git config --global core.filemode false
git config --global pull.rebase false
git config --global init.defaultbranch main

echo ""
echo -e "${GREEN}✅ Configuration applied successfully!${NC}"
echo ""
echo -e "${YELLOW}New git configuration:${NC}"
echo "  user.name: $(git config --global user.name)"
echo "  user.email: $(git config --global user.email)"
echo "  core.filemode: $(git config --global core.filemode)"
echo "  pull.rebase: $(git config --global pull.rebase)"
echo "  init.defaultbranch: $(git config --global init.defaultbranch)"
echo ""

# Verify configuration
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Configuration complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
