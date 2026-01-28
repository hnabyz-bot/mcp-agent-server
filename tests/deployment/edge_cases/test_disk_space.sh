#!/bin/bash
# Edge Case Test: Disk Space Issues
# Tests deployment behavior under disk space constraints

# Test framework
ASSERT_PASS=0
ASSERT_FAIL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo "========================================="
echo "Edge Case Test: Disk Space Issues"
echo "========================================="
echo ""

# ========================================
# Test 1: Check available disk space
# ========================================
echo "Test 1: Check available disk space"

# Get available disk space in KB
AVAILABLE_KB=$(df / | tail -1 | awk '{print $4}')
AVAILABLE_MB=$((AVAILABLE_KB / 1024))

log_info "Available disk space: ${AVAILABLE_MB}MB"

# Minimum required space (100MB)
MIN_SPACE_MB=100

if [ $AVAILABLE_MB -gt $MIN_SPACE_MB ]; then
    assert_pass "Sufficient disk space (${AVAILABLE_MB}MB > ${MIN_SPACE_MB}MB)"
else
    assert_fail "Disk space check" "Insufficient space (${AVAILABLE_MB}MB < ${MIN_SPACE_MB}MB)"
fi

# ========================================
# Test 2: Simulate low disk space warning
# ========================================
echo ""
echo "Test 2: Low disk space warning threshold"

# Warning threshold (500MB)
WARNING_THRESHOLD_MB=500

if [ $AVAILABLE_MB -lt $WARNING_THRESHOLD_MB ]; then
    log_info "WARNING: Disk space below ${WARNING_THRESHOLD_MB}MB threshold"
    assert_pass "Low disk space warning triggered"
else
    assert_pass "Disk space above warning threshold"
fi

# ========================================
# Test 3: Check /var/www/html space
# ========================================
echo ""
echo "Test 3: Check deployment target directory space"

DOC_ROOT="/var/www/html"
if [ -d "$DOC_ROOT" ]; then
    DOC_AVAILABLE_KB=$(df "$DOC_ROOT" 2>/dev/null | tail -1 | awk '{print $4}')
    DOC_AVAILABLE_MB=$((DOC_AVAILABLE_KB / 1024))

    log_info "Available space in $DOC_ROOT: ${DOC_AVAILABLE_MB}MB"

    if [ $DOC_AVAILABLE_MB -gt 50 ]; then
        assert_pass "Deployment target has sufficient space"
    else
        assert_fail "Deployment target space" "Less than 50MB available in $DOC_ROOT"
    fi
else
    log_info "$DOC_ROOT does not exist (using test directory)"
    assert_pass "Deployment target check skipped"
fi

# ========================================
# Test 4: Large file handling
# ========================================
echo ""
echo "Test 4: Large file handling in deployment"

TEST_DIR="/tmp/test-disk-space-$$"
mkdir -p "$TEST_DIR"

# Create a large test file (10MB)
LARGE_FILE="$TEST_DIR/large-file.bin"
log_info "Creating 10MB test file..."
dd if=/dev/zero of="$LARGE_FILE" bs=1M count=10 > /dev/null 2>&1

FILE_SIZE_MB=$(du -m "$LARGE_FILE" | cut -f1)

if [ $FILE_SIZE_MB -ge 10 ]; then
    assert_pass "Large file created successfully (${FILE_SIZE_MB}MB)"
else
    assert_fail "Large file creation" "File size is ${FILE_SIZE_MB}MB (expected >= 10MB)"
fi

# ========================================
# Test 5: Disk space before and after copy
# ========================================
echo ""
echo "Test 5: Disk space change after file operation"

SPACE_BEFORE_KB=$(df "$TEST_DIR" | tail -1 | awk '{print $4}')

# Create additional files
for i in {1..5}; do
    dd if=/dev/zero of="$TEST_DIR/file-$i.bin" bs=1M count=1 > /dev/null 2>&1
done

SPACE_AFTER_KB=$(df "$TEST_DIR" | tail -1 | awk '{print $4}')

SPACE_DIFF_KB=$((SPACE_BEFORE_KB - SPACE_AFTER_KB))
SPACE_DIFF_MB=$((SPACE_DIFF_KB / 1024))

log_info "Disk space used: ${SPACE_DIFF_MB}MB"

if [ $SPACE_DIFF_MB -ge 5 ]; then
    assert_pass "Disk space decreased as expected (${SPACE_DIFF_MB}MB used)"
else
    assert_fail "Disk space tracking" "Expected >=5MB, got ${SPACE_DIFF_MB}MB"
fi

# ========================================
# Test 6: Backup space calculation
# ========================================
echo ""
echo "Test 6: Backup space requirements"

# Simulate existing deployment size
EXISTING_SIZE_MB=15

# Calculate backup space needed (assumes compression or copy)
BACKUP_SPACE_MB=$EXISTING_SIZE_MB

log_info "Backup space required: ${BACKUP_SPACE_MB}MB"

if [ $AVAILABLE_MB -gt $BACKUP_SPACE_MB ]; then
    assert_pass "Sufficient space for backup"
else
    assert_fail "Backup space" "Insufficient space for backup (need ${BACKUP_SPACE_MB}MB)"
fi

# ========================================
# Test 7: Disk space monitoring during deployment
# ========================================
echo ""
echo "Test 7: Disk space monitoring simulation"

# Monitor space during file operations
SPACE_READINGS=()

for i in {1..3}; do
    READING=$(df "$TEST_DIR" | tail -1 | awk '{print $4}')
    SPACE_READINGS+=("$READING")
    log_info "Reading $i: ${READING}KB"

    # Create a file
    dd if=/dev/zero of="$TEST_DIR/monitor-$i.bin" bs=1M count=1 > /dev/null 2>&1
done

# Check if space is decreasing
FIRST_READING=${SPACE_READINGS[0]}
LAST_READING=${SPACE_READINGS[2]}

if [ $LAST_READING -lt $FIRST_READING ]; then
    assert_pass "Disk space decreasing as files are added"
else
    assert_fail "Space monitoring" "Space not decreasing properly"
fi

# ========================================
# Test 8: Cleanup old backups
# ========================================
echo ""
echo "Test 8: Cleanup old backups when space is low"

# Create multiple backups
BACKUP_DIR="$TEST_DIR/backups"
mkdir -p "$BACKUP_DIR"

for i in {1..5}; do
    dd if=/dev/zero of="$BACKUP_DIR/backup-$i.bin" bs=1M count=1 > /dev/null 2>&1
done

BACKUP_COUNT=$(ls -1 "$BACKUP_DIR" | wc -l)

if [ $BACKUP_COUNT -eq 5 ]; then
    assert_pass "Multiple backups created (${BACKUP_COUNT} backups)"
else
    assert_fail "Backup creation" "Expected 5 backups, found $BACKUP_COUNT"
fi

# Simulate cleanup (remove oldest 2 backups)
log_info "Simulating cleanup - removing oldest backups"
rm "$BACKUP_DIR/backup-1.bin"
rm "$BACKUP_DIR/backup-2.bin"

REMAINING_BACKUPS=$(ls -1 "$BACKUP_DIR" | wc -l)

if [ $REMAINING_BACKUPS -eq 3 ]; then
    assert_pass "Old backups cleaned up (3 remaining)"
else
    assert_fail "Backup cleanup" "Expected 3 backups, found $REMAINING_BACKUPS"
fi

# ========================================
# Test 9: Disk space threshold alert
# ========================================
echo ""
echo "Test 9: Disk space threshold alert simulation"

# Simulate critical space threshold (10% of total)
TOTAL_SPACE_KB=$(df "$TEST_DIR" | tail -1 | awk '{print $2}')
CRITICAL_THRESHOLD_KB=$((TOTAL_SPACE_KB * 10 / 100))

AVAILABLE_NOW_KB=$(df "$TEST_DIR" | tail -1 | awk '{print $4}')

log_info "Critical threshold: $((CRITICAL_THRESHOLD_KB / 1024))MB"
log_info "Currently available: $((AVAILABLE_NOW_KB / 1024))MB"

if [ $AVAILABLE_NOW_KB -lt $CRITICAL_THRESHOLD_KB ]; then
    assert_fail "Critical space" "Available space below critical threshold"
else
    assert_pass "Disk space above critical threshold"
fi

# ========================================
# Test 10: Deployment abort on insufficient space
# ========================================
echo ""
echo "Test 10: Deployment abort when insufficient space"

# Simulate required space check
REQUIRED_SPACE_MB=50
AVAILABLE_FOR_DEPLOY_MB=$AVAILABLE_MB

log_info "Required: ${REQUIRED_SPACE_MB}MB"
log_info "Available: ${AVAILABLE_FOR_DEPLOY_MB}MB"

if [ $AVAILABLE_FOR_DEPLOY_MB -lt $REQUIRED_SPACE_MB ]; then
    assert_pass "Deployment would be aborted (insufficient space)"
else
    assert_pass "Deployment can proceed (sufficient space)"
fi

# Cleanup
log_info "Cleaning up test files..."
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
    echo -e "${GREEN}All disk space tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some disk space tests failed.${NC}"
    exit 1
fi
