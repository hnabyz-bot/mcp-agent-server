#!/bin/bash
# Unit Test: Cache Version Bump Logic
# Tests version parsing and increment logic

# Test framework
ASSERT_PASS=0
ASSERT_FAIL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helper functions
assert_pass() {
    local test_name="$1"
    echo -e "${GREEN}✓ PASS${NC}: $test_name"
    ((ASSERT_PASS++))
}

assert_fail() {
    local test_name="$1"
    local reason="$2"
    echo -e "${RED}✗ FAIL${NC}: $test_name"
    echo -e "  ${YELLOW}Reason: $reason${NC}"
    ((ASSERT_FAIL++))
}

# Setup test environment
TEST_DIR="/tmp/test-cache-version-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "========================================="
echo "Unit Test: Cache Version Bump Logic"
echo "========================================="
echo ""

# ========================================
# Test 1: Parse current version from index.html
# ========================================
echo "Test 1: Parse current version using regex"

# Create test index.html
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Test Form</title>
    <link rel="stylesheet" href="style.css">
    <script src="script.js?v=1.0.5"></script>
</head>
<body>
    <h1>Test</h1>
</body>
</html>
EOF

# Extract version using same regex as deploy script
CURRENT_VERSION=$(grep -oP 'script\.js\?v=\K[0-9.]+(?=["<])' index.html 2>/dev/null || echo "0.0.0")

if [ "$CURRENT_VERSION" = "1.0.5" ]; then
    assert_pass "Parse version 1.0.5 from index.html"
else
    assert_fail "Parse version" "Expected 1.0.5, got $CURRENT_VERSION"
fi

# ========================================
# Test 2: Parse version with different formats
# ========================================
echo ""
echo "Test 2: Parse version variations"

# Test variation 1: version 2.3.10
cat > index.html << 'EOF'
<script src="script.js?v=2.3.10"></script>
EOF

CURRENT_VERSION=$(grep -oP 'script\.js\?v=\K[0-9.]+(?=["<])' index.html 2>/dev/null || echo "0.0.0")
if [ "$CURRENT_VERSION" = "2.3.10" ]; then
    assert_pass "Parse version 2.3.10"
else
    assert_fail "Parse version 2.3.10" "Expected 2.3.10, got $CURRENT_VERSION"
fi

# Test variation 2: version 0.0.1
cat > index.html << 'EOF'
<script src="script.js?v=0.0.1"></script>
EOF

CURRENT_VERSION=$(grep -oP 'script\.js\?v=\K[0-9.]+(?=["<])' index.html 2>/dev/null || echo "0.0.0")
if [ "$CURRENT_VERSION" = "0.0.1" ]; then
    assert_pass "Parse version 0.0.1"
else
    assert_fail "Parse version 0.0.1" "Expected 0.0.1, got $CURRENT_VERSION"
fi

# ========================================
# Test 3: Increment patch version
# ========================================
echo ""
echo "Test 3: Increment patch version"

# Test: 1.0.5 -> 1.0.6
CURRENT_VERSION="1.0.5"
MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"

if [ "$NEW_VERSION" = "1.0.6" ]; then
    assert_pass "Increment 1.0.5 -> 1.0.6"
else
    assert_fail "Increment patch" "Expected 1.0.6, got $NEW_VERSION"
fi

# Test: 2.3.10 -> 2.3.11
CURRENT_VERSION="2.3.10"
MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"

if [ "$NEW_VERSION" = "2.3.11" ]; then
    assert_pass "Increment 2.3.10 -> 2.3.11"
else
    assert_fail "Increment 2.3.10" "Expected 2.3.11, got $NEW_VERSION"
fi

# ========================================
# Test 4: Update index.html with new version
# ========================================
echo ""
echo "Test 4: Update index.html with new version"

# Create test file
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <script src="script.js?v=1.0.5"></script>
</head>
</html>
EOF

# Simulate version update
NEW_VERSION="1.0.6"
sed -i "s/script\.js?v=[0-9.]*/script.js?v=$NEW_VERSION/" index.html

# Verify update
UPDATED_VERSION=$(grep -oP 'script\.js\?v=\K[0-9.]+(?=["<])' index.html 2>/dev/null)

if [ "$UPDATED_VERSION" = "1.0.6" ]; then
    assert_pass "Update index.html to version 1.0.6"
else
    assert_fail "Update index.html" "Expected 1.0.6, got $UPDATED_VERSION"
fi

# ========================================
# Test 5: Version increment doesn't affect major/minor
# ========================================
echo ""
echo "Test 5: Verify only patch version increments"

# Test multiple increments
VERSIONS=("1.0.0" "1.0.1" "1.0.2" "2.5.9" "2.5.10")
EXPECTED=("1.0.1" "1.0.2" "1.0.3" "2.5.10" "2.5.11")

ALL_PASS=true
for i in "${!VERSIONS[@]}"; do
    CURRENT="${VERSIONS[$i]}"
    EXPECT="${EXPECTED[$i]}"

    MAJOR=$(echo "$CURRENT" | cut -d. -f1)
    MINOR=$(echo "$CURRENT" | cut -d. -f2)
    PATCH=$(echo "$CURRENT" | cut -d. -f3)
    NEW_PATCH=$((PATCH + 1))
    NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"

    if [ "$NEW_VERSION" != "$EXPECT" ]; then
        assert_fail "Increment $CURRENT" "Expected $EXPECT, got $NEW_VERSION"
        ALL_PASS=false
    fi
done

if [ "$ALL_PASS" = true ]; then
    assert_pass "All patch increments preserve major.minor"
fi

# ========================================
# Test 6: Handle version string without patch
# ========================================
echo ""
echo "Test 6: Handle edge case - version without patch"

# Test with just major.minor
CURRENT_VERSION="1.0"
MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=${3:-0}  # Default to 0 if not present
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"

if [ "$NEW_VERSION" = "1.0.1" ]; then
    assert_pass "Handle version 1.0 -> 1.0.1"
else
    assert_fail "Handle version without patch" "Expected 1.0.1, got $NEW_VERSION"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"

# ========================================
# Test Summary
# ========================================
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "${GREEN}Passed: $ASSERT_PASS${NC}"
echo -e "${RED}Failed: $ASSERT_FAIL${NC}"
echo "Total: $((ASSERT_PASS + ASSERT_FAIL))"
echo ""

if [ $ASSERT_FAIL -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
