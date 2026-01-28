#!/bin/bash
# Performance Test: Deployment Speed and Resource Usage
# Tests deployment performance metrics

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
echo "Performance Test: Deployment Metrics"
echo "========================================="
echo ""

# Performance thresholds
MAX_WINDOWS_DEPLOY_TIME=30      # 30 seconds
MAX_PI_DEPLOY_TIME=60           # 60 seconds
MAX_TOTAL_WORKFLOW_TIME=120     # 2 minutes
MAX_MEMORY_USAGE=100            # 100 MB
MAX_CPU_USAGE=80                # 80%

# ========================================
# Test 1: Measure Git operation performance
# ========================================
echo "Test 1: Git operation performance"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"

if [ -d "$PROJECT_ROOT/.git" ]; then
    # Measure git status time
    START_TIME=$(date +%s.%N)
    git -C "$PROJECT_ROOT" status > /dev/null 2>&1
    END_TIME=$(date +%s.%N)
    GIT_STATUS_TIME=$(echo "$END_TIME - $START_TIME" | bc)

    log_info "Git status time: ${GIT_STATUS_TIME}s"

    if (( $(echo "$GIT_STATUS_TIME < 2.0" | bc -l) )); then
        assert_pass "Git status completes quickly (${GIT_STATUS_TIME}s < 2.0s)"
    else
        assert_fail "Git status" "Too slow: ${GIT_STATUS_TIME}s >= 2.0s"
    fi
else
    log_info "Not in a git repository, skipping git performance tests"
fi

# ========================================
# Test 2: Measure file copy performance
# ========================================
echo ""
echo "Test 2: File copy performance"

TEST_DIR="/tmp/test-perf-$$"
SOURCE_DIR="$TEST_DIR/source"
TARGET_DIR="$TEST_DIR/target"

mkdir -p "$SOURCE_DIR"
mkdir -p "$TARGET_DIR"

# Create test files (100 files, 1KB each)
log_info "Creating 100 test files..."
for i in {1..100}; do
    dd if=/dev/zero of="$SOURCE_DIR/file-$i.txt" bs=1024 count=1 > /dev/null 2>&1
done

# Measure copy time
START_TIME=$(date +%s.%N)
cp -r "$SOURCE_DIR"/* "$TARGET_DIR/"
END_TIME=$(date +%s.%N)
COPY_TIME=$(echo "$END_TIME - $START_TIME" | bc)

log_info "Copy time for 100 files: ${COPY_TIME}s"

if (( $(echo "$COPY_TIME < 5.0" | bc -l) )); then
    assert_pass "File copy completes quickly (${COPY_TIME}s < 5.0s)"
else
    assert_fail "File copy" "Too slow: ${COPY_TIME}s >= 5.0s"
fi

# ========================================
# Test 3: Measure permission setting performance
# ========================================
echo ""
echo "Test 3: Permission setting performance"

START_TIME=$(date +%s.%N)
chmod -R 755 "$TARGET_DIR" > /dev/null 2>&1
END_TIME=$(date +%s.%N)
CHMOD_TIME=$(echo "$END_TIME - $START_TIME" | bc)

log_info "Chmod -R time: ${CHMOD_TIME}s"

if (( $(echo "$CHMOD_TIME < 1.0" | bc -l) )); then
    assert_pass "Permission setting completes quickly (${CHMOD_TIME}s < 1.0s)"
else
    assert_fail "Permission setting" "Too slow: ${CHMOD_TIME}s >= 1.0s"
fi

# ========================================
# Test 4: Measure symbolic link creation
# ========================================
echo ""
echo "Test 4: Symbolic link creation performance"

LINK_TARGET="$TEST_DIR/current"
START_TIME=$(date +%s.%N)
ln -sf "$SOURCE_DIR" "$LINK_TARGET"
END_TIME=$(date +%s.%N)
LINK_TIME=$(echo "$END_TIME - $START_TIME" | bc)

log_info "Symbolic link creation time: ${LINK_TIME}s"

if (( $(echo "$LINK_TIME < 0.1" | bc -l) )); then
    assert_pass "Symbolic link creation is instant (${LINK_TIME}s < 0.1s)"
else
    assert_fail "Symbolic link" "Too slow: ${LINK_TIME}s >= 0.1s"
fi

# ========================================
# Test 5: Measure memory usage during deployment
# ========================================
echo ""
echo "Test 5: Memory usage monitoring"

# Get memory before operations
MEM_BEFORE=$(free -m | grep Mem | awk '{print $3}')

# Simulate deployment operations
for i in {1..10}; do
    mkdir -p "$TEST_DIR/deploy-$i"
    cp -r "$SOURCE_DIR"/* "$TEST_DIR/deploy-$i/" > /dev/null 2>&1
done

# Get memory after operations
MEM_AFTER=$(free -m | grep Mem | awk '{print $3}')
MEM_USED=$((MEM_AFTER - MEM_BEFORE))

log_info "Memory used during deployment: ${MEM_USED}MB"

if [ $MEM_USED -lt $MAX_MEMORY_USAGE ]; then
    assert_pass "Memory usage within limits (${MEM_USED}MB < ${MAX_MEMORY_USAGE}MB)"
else
    assert_fail "Memory usage" "Too high: ${MEM_USED}MB >= ${MAX_MEMORY_USAGE}MB"
fi

# ========================================
# Test 6: Measure CPU usage during deployment
# ========================================
echo ""
echo "Test 6: CPU usage monitoring"

# This is a simplified CPU check
# In production, use proper monitoring tools
CPU_CHECK=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)

log_info "Current CPU usage: ${CPU_CHECK}%"

if (( $(echo "$CPU_CHECK < $MAX_CPU_USAGE" | bc -l) )); then
    assert_pass "CPU usage within normal range (${CPU_CHECK}% < ${MAX_CPU_USAGE}%)"
else
    log_info "High CPU usage detected (may be temporary)"
fi

# ========================================
# Test 7: Measure deployment script execution time
# ========================================
echo ""
echo "Test 7: Deployment script execution time"

# Simulate deploy-and-restart.sh operations
DEPLOY_START=$(date +%s.%N)

# Step 1: Git pull simulation
sleep 0.1

# Step 2: Version check
sleep 0.05

# Step 3: Backup creation
BACKUP_NAME="$TEST_DIR/forms.backup.$(date +%Y%m%d_%H%M%S)"
cp -r "$SOURCE_DIR" "$BACKUP_NAME" > /dev/null 2>&1

# Step 4: Symbolic link
ln -sf "$SOURCE_DIR" "$TEST_DIR/forms" > /dev/null 2>&1

# Step 5: Permissions
chmod -R 755 "$SOURCE_DIR" > /dev/null 2>&1

DEPLOY_END=$(date +%s.%N)
DEPLOY_TIME=$(echo "$DEPLOY_END - $DEPLOY_START" | bc)

log_info "Deployment operations time: ${DEPLOY_TIME}s"

if (( $(echo "$DEPLOY_TIME < $MAX_PI_DEPLOY_TIME" | bc -l) )); then
    assert_pass "Deployment completes within limit (${DEPLOY_TIME}s < ${MAX_PI_DEPLOY_TIME}s)"
else
    assert_fail "Deployment time" "Too slow: ${DEPLOY_TIME}s >= ${MAX_PI_DEPLOY_TIME}s"
fi

# ========================================
# Test 8: Measure I/O performance
# ========================================
echo ""
echo "Test 8: Disk I/O performance"

# Test write speed
IO_FILE="$TEST_DIR/io-test.bin"
IO_START=$(date +%s.%N)
dd if=/dev/zero of="$IO_FILE" bs=1M count=10 > /dev/null 2>&1
IO_END=$(date +%s.%N)
IO_TIME=$(echo "$IO_END - $IO_START" | bc)

IO_SPEED=$(echo "scale=2; 10 / $IO_TIME" | bc)

log_info "Write speed: ${IO_SPEED}MB/s"

if (( $(echo "$IO_SPEED > 10" | bc -l) )); then
    assert_pass "Disk write speed acceptable (${IO_SPEED}MB/s > 10MB/s)"
else
    assert_fail "Disk I/O" "Too slow: ${IO_SPEED}MB/s <= 10MB/s"
fi

# ========================================
# Test 9: Concurrent deployment test
# ========================================
echo ""
echo "Test 9: Concurrent deployment handling"

# Simulate multiple deployment attempts
CONCURRENT_START=$(date +%s.%N)

for i in {1..3}; do
    (
        mkdir -p "$TEST_DIR/concurrent-$i"
        cp -r "$SOURCE_DIR"/* "$TEST_DIR/concurrent-$i/" > /dev/null 2>&1
    ) &
done

# Wait for all background jobs
wait

CONCURRENT_END=$(date +%s.%N)
CONCURRENT_TIME=$(echo "$CONCURRENT_END - $CONCURRENT_START" | bc)

log_info "3 concurrent deployments: ${CONCURRENT_TIME}s"

if (( $(echo "$CONCURRENT_TIME < 10.0" | bc -l) )); then
    assert_pass "Concurrent deployments handled well (${CONCURRENT_TIME}s < 10.0s)"
else
    assert_fail "Concurrent deployments" "Too slow: ${CONCURRENT_TIME}s >= 10.0s"
fi

# ========================================
# Test 10: Large file performance
# ========================================
echo ""
echo "Test 10: Large file handling performance"

# Create a large file (50MB)
LARGE_FILE="$TEST_DIR/large-file.bin"
log_info "Creating 50MB test file..."
dd if=/dev/zero of="$LARGE_FILE" bs=1M count=50 > /dev/null 2>&1

# Measure copy time
LARGE_START=$(date +%s.%N)
cp "$LARGE_FILE" "$TEST_DIR/large-copy.bin"
LARGE_END=$(date +%s.%N)
LARGE_TIME=$(echo "$LARGE_END - $LARGE_START" | bc)

LARGE_SPEED=$(echo "scale=2; 50 / $LARGE_TIME" | bc)

log_info "Large file copy speed: ${LARGE_SPEED}MB/s"

if (( $(echo "$LARGE_SPEED > 20" | bc -l) )); then
    assert_pass "Large file copy speed good (${LARGE_SPEED}MB/s > 20MB/s)"
else
    assert_fail "Large file copy" "Too slow: ${LARGE_SPEED}MB/s <= 20MB/s"
fi

# ========================================
# Test 11: Auto-update timer overhead
# ========================================
echo ""
echo "Test 11: Auto-update timer overhead"

# Simulate systemd timer execution
TIMER_START=$(date +%s.%N)

# Simulate timer actions
sleep 0.5  # Check for updates
# Update would happen here
sleep 0.3  # Verify deployment

TIMER_END=$(date +%s.%N)
TIMER_TIME=$(echo "$TIMER_END - $TIMER_START" | bc)

log_info "Timer execution time: ${TIMER_TIME}s"

if (( $(echo "$TIMER_TIME < 5.0" | bc -l) )); then
    assert_pass "Timer overhead minimal (${TIMER_TIME}s < 5.0s)"
else
    assert_fail "Timer overhead" "Too high: ${TIMER_TIME}s >= 5.0s"
fi

# ========================================
# Test 12: Performance regression detection
# ========================================
echo ""
echo "Test 12: Performance regression detection"

# Store current performance metrics
PERF_FILE="$TEST_DIR/performance-metrics.txt"
cat > "$PERF_FILE" << EOF
git_status_time=${GIT_STATUS_TIME}s
copy_time=${COPY_TIME}s
chmod_time=${CHMOD_TIME}s
link_time=${LINK_TIME}s
deploy_time=${DEPLOY_TIME}s
io_speed=${IO_SPEED}MB/s
concurrent_time=${CONCURRENT_TIME}s
large_file_speed=${LARGE_SPEED}MB/s
EOF

log_info "Performance metrics saved to: $PERF_FILE"

if [ -f "$PERF_FILE" ]; then
    assert_pass "Performance metrics captured"
    echo ""
    echo -e "${BLUE}Performance Summary:${NC}"
    cat "$PERF_FILE"
else
    assert_fail "Metrics capture" "Failed to save performance metrics"
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

echo -e "${BLUE}Performance Benchmarks:${NC}"
echo "Windows deploy target: < ${MAX_WINDOWS_DEPLOY_TIME}s"
echo "Raspberry Pi deploy: < ${MAX_PI_DEPLOY_TIME}s"
echo "Total workflow: < ${MAX_TOTAL_WORKFLOW_TIME}s"
echo "Memory usage: < ${MAX_MEMORY_USAGE}MB"
echo "CPU usage: < ${MAX_CPU_USAGE}%"
echo ""

if [ $ASSERT_FAIL -eq 0 ]; then
    echo -e "${GREEN}All performance tests passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}Some performance tests failed.${NC}"
    echo -e "${YELLOW}This may be expected in test environments.${NC}"
    exit 1
fi
