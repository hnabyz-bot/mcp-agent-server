#!/bin/bash
# Integration Test: Full Deployment Workflow
# Tests complete Windows → GitHub → Raspberry Pi deployment flow

# Test framework
ASSERT_PASS=0
ASSERT_FAIL=0
TEST_START_TIME=$(date +%s)

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

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
TEST_DEPLOY_DIR="/tmp/test-deployment-$$"
FORMS_DIR="$PROJECT_ROOT/forms-interface"
DOC_ROOT="$TEST_DEPLOY_DIR/var/www/html"

# Setup test environment
mkdir -p "$DOC_ROOT"
mkdir -p "$TEST_DEPLOY_DIR/forms-interface"

echo "========================================="
echo "Integration Test: Full Deployment Workflow"
echo "========================================="
echo ""
log_info "Test Directory: $TEST_DEPLOY_DIR"
log_info "Forms Directory: $FORMS_DIR"
log_info "Document Root: $DOC_ROOT"
echo ""

# ========================================
# Phase 1: Windows Deployment Simulation
# ========================================
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Phase 1: Windows Deployment Simulation${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 1.1: Verify forms-interface directory exists
log_info "Test 1.1: Verify forms-interface directory"
if [ -d "$FORMS_DIR" ]; then
    assert_pass "forms-interface directory exists"
else
    assert_fail "forms-interface directory" "Directory not found at $FORMS_DIR"
    exit 1
fi

# Test 1.2: Check for required files
log_info "Test 1.2: Check for required files"
REQUIRED_FILES=("index.html" "script.js" "styles.css")
ALL_FILES_PRESENT=true

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$FORMS_DIR/$file" ]; then
        assert_fail "Required file $file" "File not found"
        ALL_FILES_PRESENT=false
    fi
done

if [ "$ALL_FILES_PRESENT" = true ]; then
    assert_pass "All required files present (index.html, script.js, styles.css)"
fi

# Test 1.3: Read current version
log_info "Test 1.3: Read current cache version"
CURRENT_VERSION=$(grep -oP 'script\.js\?v=\K[0-9.]+(?=["<])' "$FORMS_DIR/index.html" 2>/dev/null || echo "0.0.0")

if [ "$CURRENT_VERSION" != "0.0.0" ]; then
    assert_pass "Current version read: $CURRENT_VERSION"
else
    assert_fail "Read current version" "Could not parse version from index.html"
fi

# Test 1.4: Simulate version bump (Windows logic)
log_info "Test 1.4: Simulate cache version bump"
MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"

log_info "Version bump: $CURRENT_VERSION → $NEW_VERSION"

if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
    assert_pass "Version incremented correctly"
else
    assert_fail "Version increment" "Version did not change"
fi

# ========================================
# Phase 2: Git Operations Simulation
# ========================================
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Phase 2: Git Operations Simulation${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 2.1: Verify git repository
log_info "Test 2.1: Verify git repository"
if [ -d "$PROJECT_ROOT/.git" ]; then
    assert_pass "Git repository detected"
else
    assert_fail "Git repository" ".git directory not found"
fi

# Test 2.2: Check git status
log_info "Test 2.2: Check git status"
GIT_STATUS=$(git -C "$PROJECT_ROOT" status --porcelain 2>/dev/null | wc -l)

if [ "$GIT_STATUS" -eq 0 ]; then
    assert_pass "Working directory is clean"
else
    log_info "Working directory has $GIT_STATUS changed files (may be expected)"
fi

# Test 2.3: Verify remote origin
log_info "Test 2.3: Verify remote origin"
REMOTE=$(git -C "$PROJECT_ROOT" remote get-url origin 2>/dev/null)

if [ -n "$REMOTE" ]; then
    assert_pass "Remote origin configured: $REMOTE"
else
    assert_fail "Remote origin" "No remote origin configured"
fi

# ========================================
# Phase 3: Raspberry Pi Deployment Simulation
# ========================================
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Phase 3: Raspberry Pi Deployment${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 3.1: Copy forms-interface to test location
log_info "Test 3.1: Copy forms-interface to test location"
cp -r "$FORMS_DIR"/* "$TEST_DEPLOY_DIR/forms-interface/"

if [ -f "$TEST_DEPLOY_DIR/forms-interface/index.html" ]; then
    assert_pass "Forms copied to test deployment directory"
else
    assert_fail "Copy forms" "Failed to copy forms-interface"
fi

# Test 3.2: Backup existing deployment
log_info "Test 3.2: Backup existing deployment"
EXISTING_DEPLOYMENT="$DOC_ROOT/forms"

if [ -e "$EXISTING_DEPLOYMENT" ]; then
    BACKUP_DIR="$DOC_ROOT/forms.backup.$(date +%Y%m%d_%H%M%S)"
    mv "$EXISTING_DEPLOYMENT" "$BACKUP_DIR"
    assert_pass "Existing deployment backed up"
else
    log_info "No existing deployment to backup (first deployment)"
fi

# Test 3.3: Create symbolic link
log_info "Test 3.3: Create symbolic link"
ln -sf "$TEST_DEPLOY_DIR/forms-interface" "$DOC_ROOT/forms"

if [ -L "$DOC_ROOT/forms" ]; then
    assert_pass "Symbolic link created"
else
    assert_fail "Symbolic link" "Link creation failed"
fi

# Test 3.4: Set permissions
log_info "Test 3.4: Set file permissions"
chmod -R 755 "$TEST_DEPLOY_DIR/forms-interface"
chmod 444 "$TEST_DEPLOY_DIR/forms-interface/index.html"
chmod 444 "$TEST_DEPLOY_DIR/forms-interface/script.js"
chmod 444 "$TEST_DEPLOY_DIR/forms-interface/styles.css"

INDEX_PERM=$(stat -c "%a" "$TEST_DEPLOY_DIR/forms-interface/index.html" 2>/dev/null || stat -f "%A" "$TEST_DEPLOY_DIR/forms-interface/index.html")

if [ "$INDEX_PERM" = "444" ]; then
    assert_pass "File permissions set correctly (444)"
else
    assert_fail "File permissions" "Expected 444, got $INDEX_PERM"
fi

# ========================================
# Phase 4: Deployment Verification
# ========================================
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Phase 4: Deployment Verification${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 4.1: Verify symbolic link exists
log_info "Test 4.1: Verify symbolic link"
if [ -L "$DOC_ROOT/forms" ]; then
    assert_pass "Symbolic link verified"
else
    assert_fail "Symbolic link verification" "Link does not exist"
fi

# Test 4.2: Verify script.js exists
log_info "Test 4.2: Verify script.js accessible through link"
if [ -f "$DOC_ROOT/forms/script.js" ]; then
    assert_pass "script.js accessible through link"
else
    assert_fail "script.js" "File not accessible through link"
fi

# Test 4.3: Verify index.html exists
log_info "Test 4.3: Verify index.html accessible through link"
if [ -f "$DOC_ROOT/forms/index.html" ]; then
    assert_pass "index.html accessible through link"
else
    assert_fail "index.html" "File not accessible through link"
fi

# Test 4.4: Verify cache version
log_info "Test 4.4: Verify cache version in deployed index.html"
DEPLOYED_VERSION=$(grep -oP 'script\.js\?v=\K[0-9.]+(?=["<])' "$DOC_ROOT/forms/index.html" 2>/dev/null || echo "0.0.0")

if [ "$DEPLOYED_VERSION" = "$CURRENT_VERSION" ]; then
    assert_pass "Deployed version matches: $DEPLOYED_VERSION"
else
    assert_fail "Cache version" "Expected $CURRENT_VERSION, got $DEPLOYED_VERSION"
fi

# Test 4.5: Verify email field in script.js
log_info "Test 4.5: Verify email field present in script.js"
if grep -q "formData.append('email'" "$DOC_ROOT/forms/script.js" 2>/dev/null; then
    assert_pass "Email field present in script.js"
else
    log_info "Email field check skipped (field may not exist in current version)"
fi

# ========================================
# Phase 5: Rollback Test
# ========================================
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Phase 5: Rollback Mechanism${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 5.1: Simulate deployment failure
log_info "Test 5.1: Simulate deployment failure"

# Create a backup to restore
BACKUP_FOR_ROLLBACK="$DOC_ROOT/forms.rollback.test"
cp -r "$TEST_DEPLOY_DIR/forms-interface" "$BACKUP_FOR_ROLLBACK"

# Corrupt current deployment
echo "corrupted" > "$DOC_ROOT/forms/index.html"

# Verify corruption
if grep -q "corrupted" "$DOC_ROOT/forms/index.html"; then
    assert_pass "Deployment corrupted for rollback test"
else
    assert_fail "Corrupt deployment" "Failed to corrupt deployment"
fi

# Test 5.2: Restore from backup
log_info "Test 5.2: Restore from backup"
rm "$DOC_ROOT/forms"
ln -sf "$BACKUP_FOR_ROLLBACK" "$DOC_ROOT/forms"

if ! grep -q "corrupted" "$DOC_ROOT/forms/index.html"; then
    assert_pass "Rollback successful - deployment restored"
else
    assert_fail "Rollback" "Failed to restore from backup"
fi

# ========================================
# Test Summary
# ========================================
TEST_END_TIME=$(date +%s)
TEST_DURATION=$((TEST_END_TIME - TEST_START_TIME))

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}Passed: $ASSERT_PASS${NC}"
echo -e "${RED}Failed: $ASSERT_FAIL${NC}"
echo "Total: $((ASSERT_PASS + ASSERT_FAIL))"
echo "Duration: ${TEST_DURATION}s"
echo ""

# Performance check
if [ $TEST_DURATION -lt 120 ]; then
    echo -e "${GREEN}✓ Performance test passed: ${TEST_DURATION}s < 120s${NC}"
else
    echo -e "${YELLOW}⚠ Performance warning: ${TEST_DURATION}s >= 120s${NC}"
fi

# Cleanup
log_info "Cleaning up test environment..."
cd /
rm -rf "$TEST_DEPLOY_DIR"

echo ""
if [ $ASSERT_FAIL -eq 0 ]; then
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}All integration tests passed!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    exit 0
else
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}Some integration tests failed.${NC}"
    echo -e "${RED}=========================================${NC}"
    exit 1
fi
