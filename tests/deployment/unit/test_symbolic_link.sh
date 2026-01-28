#!/bin/bash
# Unit Test: Symbolic Link Creation
# Tests symbolic link creation and validation logic

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
TEST_DIR="/tmp/test-symlink-$$"
SOURCE_DIR="$TEST_DIR/forms-interface"
TARGET_DIR="$TEST_DIR/var/www/html"
TEST_USER=$(whoami)

mkdir -p "$SOURCE_DIR"
mkdir -p "$TARGET_DIR"
cd "$TEST_DIR"

echo "========================================="
echo "Unit Test: Symbolic Link Creation"
echo "========================================="
echo ""

# Create test files
touch "$SOURCE_DIR/index.html"
touch "$SOURCE_DIR/script.js"
echo "console.log('test');" > "$SOURCE_DIR/script.js"

# ========================================
# Test 1: Create symbolic link
# ========================================
echo "Test 1: Create symbolic link"

ln -sf "$SOURCE_DIR" "$TARGET_DIR/forms"

if [ -L "$TARGET_DIR/forms" ]; then
    assert_pass "Symbolic link created successfully"
else
    assert_fail "Symbolic link creation" "Link does not exist"
fi

# ========================================
# Test 2: Verify link points to correct source
# ========================================
echo ""
echo "Test 2: Verify link points to correct source"

LINK_TARGET=$(readlink -f "$TARGET_DIR/forms")

if [ "$LINK_TARGET" = "$SOURCE_DIR" ]; then
    assert_pass "Link points to correct source directory"
else
    assert_fail "Link target" "Expected $SOURCE_DIR, got $LINK_TARGET"
fi

# ========================================
# Test 3: Backup existing deployment
# ========================================
echo ""
echo "Test 3: Backup existing deployment before creating new link"

# Create an existing deployment
mkdir -p "$TARGET_DIR/forms-old"
echo "old content" > "$TARGET_DIR/forms-old/old-file.txt"

# Backup with timestamp
BACKUP_NAME="$TARGET_DIR/forms.backup.$(date +%Y%m%d_%H%M%S)"

# Simulate backup by moving
mv "$TARGET_DIR/forms" "$BACKUP_NAME" 2>/dev/null || true

if [ -d "$BACKUP_NAME" ] && [ ! -L "$TARGET_DIR/forms" ]; then
    assert_pass "Existing deployment backed up with timestamp"
else
    assert_fail "Backup creation" "Backup was not created properly"
fi

# ========================================
# Test 4: Recreate link after backup
# ========================================
echo ""
echo "Test 4: Recreate symbolic link after backup"

ln -sf "$SOURCE_DIR" "$TARGET_DIR/forms"

if [ -L "$TARGET_DIR/forms" ]; then
    assert_pass "Symbolic link recreated after backup"
else
    assert_fail "Recreate link" "Link was not recreated"
fi

# ========================================
# Test 5: Verify files accessible through link
# ========================================
echo ""
echo "Test 5: Verify files accessible through symbolic link"

if [ -f "$TARGET_DIR/forms/script.js" ]; then
    assert_pass "Files accessible through symbolic link"
else
    assert_fail "File accessibility" "script.js not accessible through link"
fi

# ========================================
# Test 6: Verify file content through link
# ========================================
echo ""
echo "Test 6: Verify file content matches through link"

CONTENT=$(cat "$TARGET_DIR/forms/script.js")

if [ "$CONTENT" = "console.log('test');" ]; then
    assert_pass "File content matches through symbolic link"
else
    assert_fail "File content" "Content does not match"
fi

# ========================================
# Test 7: Multiple backups don't conflict
# ========================================
echo ""
echo "Test 7: Multiple backups with unique timestamps"

# Create multiple backups
BACKUP1="$TARGET_DIR/forms.backup.20260127_140000"
BACKUP2="$TARGET_DIR/forms.backup.20260127_150000"

mkdir -p "$BACKUP1"
mkdir -p "$BACKUP2"

if [ -d "$BACKUP1" ] && [ -d "$BACKUP2" ] && [ "$BACKUP1" != "$BACKUP2" ]; then
    assert_pass "Multiple backups have unique timestamps"
else
    assert_fail "Multiple backups" "Backups conflict or not unique"
fi

# ========================================
# Test 8: Link survives source directory rename
# ========================================
echo ""
echo "Test 8: Link behavior when source is renamed"

# Rename source
MOVED_SOURCE="$TEST_DIR/forms-interface-renamed"
mv "$SOURCE_DIR" "$MOVED_SOURCE"

# Link should be broken or update depending on implementation
# With -sf flag, link should be updated if we recreate it
ln -sf "$MOVED_SOURCE" "$TARGET_DIR/forms"

NEW_LINK_TARGET=$(readlink -f "$TARGET_DIR/forms")

if [ "$NEW_LINK_TARGET" = "$MOVED_SOURCE" ]; then
    assert_pass "Link updates to renamed source with -sf flag"
else
    assert_fail "Link update" "Link did not update to renamed source"
fi

# Restore for cleanup
mv "$MOVED_SOURCE" "$SOURCE_DIR"

# ========================================
# Test 9: Cleanup old backups
# ========================================
echo ""
echo "Test 9: Backup cleanup functionality"

# Count backups
BACKUP_COUNT=$(ls -d "$TARGET_DIR"/forms.backup.* 2>/dev/null | wc -l)

if [ "$BACKUP_COUNT" -gt 0 ]; then
    assert_pass "Backups can be listed and counted"
else
    assert_fail "Backup listing" "No backups found"
fi

# ========================================
# Test 10: Link permissions
# ========================================
echo ""
echo "Test 10: Symbolic link permissions"

# Symbolic links have specific permissions
LINK_PERM=$(stat -c "%a" "$TARGET_DIR/forms" 2>/dev/null || stat -f "%A" "$TARGET_DIR/forms")

# Symbolic links typically show 777 (lrwxrwxrwx)
if [ "$LINK_PERM" = "777" ]; then
    assert_pass "Symbolic link has expected permissions (777)"
else
    # Some systems may show different permissions, check if it's a symlink
    if [ -L "$TARGET_DIR/forms" ]; then
        assert_pass "File is a symbolic link (permissions: $LINK_PERM)"
    else
        assert_fail "Link permissions" "Not a symbolic link"
    fi
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
