#!/bin/bash
# Unit Test: File Permissions
# Tests file permission setting logic

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
TEST_DIR="/tmp/test-file-permissions-$$"
TEST_USER=$(whoami)
mkdir -p "$TEST_DIR/forms-interface"
cd "$TEST_DIR"

echo "========================================="
echo "Unit Test: File Permissions"
echo "========================================="
echo ""

# Create test files
touch forms-interface/index.html
touch forms-interface/script.js
touch forms-interface/style.css

# ========================================
# Test 1: Directory permission 755
# ========================================
echo "Test 1: Set directory permission to 755"

chmod 755 forms-interface

PERM=$(stat -c "%a" forms-interface 2>/dev/null || stat -f "%A" forms-interface)

if [ "$PERM" = "755" ]; then
    assert_pass "Directory permission set to 755"
else
    assert_fail "Directory permission" "Expected 755, got $PERM"
fi

# ========================================
# Test 2: Core files read-only 444
# ========================================
echo ""
echo "Test 2: Set core files to read-only (444)"

chmod 444 forms-interface/index.html
chmod 444 forms-interface/script.js
chmod 444 forms-interface/style.css

INDEX_PERM=$(stat -c "%a" forms-interface/index.html 2>/dev/null || stat -f "%A" forms-interface/index.html)
SCRIPT_PERM=$(stat -c "%a" forms-interface/script.js 2>/dev/null || stat -f "%A" forms-interface/script.js)
STYLE_PERM=$(stat -c "%a" forms-interface/style.css 2>/dev/null || stat -f "%A" forms-interface/style.css)

if [ "$INDEX_PERM" = "444" ] && [ "$SCRIPT_PERM" = "444" ] && [ "$STYLE_PERM" = "444" ]; then
    assert_pass "All core files set to 444 (read-only)"
else
    assert_fail "Core files read-only" "index.html=$INDEX_PERM, script.js=$SCRIPT_PERM, style.css=$STYLE_PERM"
fi

# ========================================
# Test 3: Verify read-only prevents modification
# ========================================
echo ""
echo "Test 3: Verify read-only prevents write"

# Try to write to read-only file
if echo "test" >> forms-interface/index.html 2>/dev/null; then
    assert_fail "Read-only protection" "Write to read-only file succeeded (should fail)"
else
    assert_pass "Read-only file prevents write"
fi

# ========================================
# Test 4: Ownership preservation
# ========================================
echo ""
echo "Test 4: Verify file ownership"

# Set ownership to current user
chown -R "$TEST_USER":"$TEST_USER" forms-interface

INDEX_OWNER=$(stat -c "%U:%G" forms-interface/index.html 2>/dev/null || stat -f "%Su:%Sg" forms-interface/index.html)
SCRIPT_OWNER=$(stat -c "%U:%G" forms-interface/script.js 2>/dev/null || stat -f "%Su:%Sg" forms-interface/script.js)

if [ "$INDEX_OWNER" = "$TEST_USER:$TEST_USER" ] && [ "$SCRIPT_OWNER" = "$TEST_USER:$TEST_USER" ]; then
    assert_pass "File ownership preserved as $TEST_USER:$TEST_USER"
else
    assert_fail "File ownership" "Expected $TEST_USER:$TEST_USER"
fi

# ========================================
# Test 5: Web server can read files
# ========================================
echo ""
echo "Test 5: Verify files are readable by web server"

# Check if files are readable (r--r--r--)
if [ -r forms-interface/index.html ] && [ -r forms-interface/script.js ]; then
    assert_pass "Files are readable by any user (including web server)"
else
    assert_fail "File readability" "Core files are not readable"
fi

# ========================================
# Test 6: Directory is executable (traversable)
# ========================================
echo ""
echo "Test 6: Verify directory is executable (traversable)"

if [ -x forms-interface ]; then
    assert_pass "Directory is executable (traversable)"
else
    assert_fail "Directory executable" "Directory is not traversable"
fi

# ========================================
# Test 7: Restore writable permissions
# ========================================
echo ""
echo "Test 7: Restore writable permissions (644)"

chmod 644 forms-interface/index.html

RESTORED_PERM=$(stat -c "%a" forms-interface/index.html 2>/dev/null || stat -f "%A" forms-interface/index.html)

if [ "$RESTORED_PERM" = "644" ]; then
    assert_pass "Restore writable permissions to 644"
else
    assert_fail "Restore permissions" "Expected 644, got $RESTORED_PERM"
fi

# ========================================
# Test 8: Verify writable allows modification
# ========================================
echo ""
echo "Test 8: Verify writable file allows modification"

if echo "test content" >> forms-interface/index.html 2>/dev/null; then
    assert_pass "Writable file allows modification"
else
    assert_fail "Writable modification" "Write to writable file failed"
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
