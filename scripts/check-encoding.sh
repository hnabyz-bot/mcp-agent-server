#!/bin/bash
# UTF-8 Encoding Verification Script
# Check if files are properly UTF-8 encoded before deployment

set -e

echo "==================================="
echo "UTF-8 Encoding Verification"
echo "==================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

# Files to check
FILES=(
    "forms-interface/index.html"
    "forms-interface/script.js"
    "forms-interface/styles.css"
    "forms-interface/README.md"
)

echo -e "${YELLOW}Checking files for UTF-8 encoding...${NC}"
echo ""

for FILE in "${FILES[@]}"; do
    if [ ! -f "$FILE" ]; then
        echo -e "${YELLOW}⚠ Warning: $FILE not found, skipping${NC}"
        WARNINGS=$((WARNINGS + 1))
        continue
    fi

    # Check file encoding
    ENCODING=$(file -b --mime-encoding "$FILE")
    HAS_BOM=$(file -b "$FILE" | grep -c "with BOM" || true)

    echo -n "Checking $FILE... "

    # Check if UTF-8
    if [[ "$ENCODING" == "utf-8" ]] || [[ "$ENCODING" == "us-ascii" ]]; then
        if [ $HAS_BOM -eq 0 ]; then
            echo -e "${GREEN}✓ OK (UTF-8 without BOM)${NC}"
        else
            echo -e "${YELLOW}⚠ Warning: UTF-8 with BOM (recommended: UTF-8 without BOM)${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "${RED}✗ FAIL ($ENCODING)${NC}"
        echo -e "  ${RED}Expected: UTF-8${NC}"
        ERRORS=$((ERRORS + 1))
    fi

    # Check for common encoding corruption patterns
    if grep -qP '[\x00-\x08\x0B\x0C\x0E-\x1F]' "$FILE"; then
        echo -e "${RED}  ✗ Corrupted characters detected${NC}"
        ERRORS=$((ERRORS + 1))
    fi

    # Check for Korean text corruption
    if grep -qP '\?{2,}' "$FILE"; then
        echo -e "${YELLOW}  ⚠ Warning: Possible Korean text corruption (???)${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
done

echo ""
echo "==================================="
echo "Summary"
echo "==================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All files are properly UTF-8 encoded${NC}"
    echo ""
    echo "Safe to deploy!"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) detected${NC}"
    echo ""
    echo "Files are UTF-8, but consider fixing warnings."
    echo "Safe to deploy, but review recommended."
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) detected${NC}"
    echo ""
    echo "Deployment NOT recommended!"
    echo ""
    echo "Fix encoding issues:"
    echo "1. Open file in VSCode/Notepad++"
    echo "2. Save as 'UTF-8 without BOM'"
    echo "3. Commit and push again"
    exit 1
fi
