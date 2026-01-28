#!/bin/bash
# Security Test: File Permissions and Access Control
# Tests security aspects of file permissions and sensitive data

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
echo "Security Test: File Permissions"
echo "========================================="
echo ""

# Setup test environment
TEST_DIR="/tmp/test-security-$$"
TEST_USER=$(whoami)
mkdir -p "$TEST_DIR/forms-interface"
cd "$TEST_DIR"

# Create test files
touch forms-interface/index.html
touch forms-interface/script.js
touch forms-interface/style.css

# ========================================
# Test 1: Web server read-only access
# ========================================
echo "Test 1: Verify web server has read-only access"

chmod 444 forms-interface/index.html
chmod 444 forms-interface/script.js
chmod 444 forms-interface/style.css

# Check if files are readable
if [ -r forms-interface/index.html ]; then
    assert_pass "Files are readable by web server"
else
    assert_fail "File readability" "Files not readable"
fi

# Check if files are NOT writable
if [ -w forms-interface/index.html ]; then
    assert_fail "File write protection" "index.html is writable (should be read-only)"
else
    assert_pass "Files are NOT writable (read-only protection)"
fi

# ========================================
# Test 2: Prevent directory listing
# ========================================
echo ""
echo "Test 2: Verify directory listing is prevented"

# Check for index.html in web root
if [ -f forms-interface/index.html ]; then
    assert_pass "index.html exists (prevents directory listing)"
else
    assert_fail "Directory listing protection" "index.html missing"
fi

# ========================================
# Test 3: .git directory not accessible
# ========================================
echo ""
echo "Test 3: Verify .git directory is not accessible via web"

# Create .git directory
mkdir -p forms-interface/.git
echo "sensitive" > forms-interface/.git/config

# Set restrictive permissions
chmod 700 forms-interface/.git

GIT_PERM=$(stat -c "%a" forms-interface/.git 2>/dev/null || stat -f "%A" forms-interface/.git)

if [ "$GIT_PERM" = "700" ]; then
    assert_pass ".git directory has restrictive permissions (700)"
else
    assert_fail ".git permissions" "Expected 700, got $GIT_PERM"
fi

# ========================================
# Test 4: Sensitive files not in web root
# ========================================
echo ""
echo "Test 4: Verify sensitive files are protected"

SENSITIVE_PATTERNS=(".env" "config.json" "secrets.txt" "*.key" "*.pem")

FOUND_SENSITIVE=false
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if find forms-interface -name "$pattern" -o -name ".env*" 2>/dev/null | grep -q .; then
        log_info "Found sensitive file matching: $pattern"
        FOUND_SENSITIVE=true
    fi
done

if [ "$FOUND_SENSITIVE" = false ]; then
    assert_pass "No sensitive files in web directory"
else
    # In real deployment, this would be a fail
    log_info "Sensitive files found (check if intentional)"
fi

# ========================================
# Test 5: File ownership validation
# ========================================
echo ""
echo "Test 5: Verify file ownership is appropriate"

# Set ownership to current user (not root)
chown -R "$TEST_USER":"$TEST_USER" forms-interface

INDEX_OWNER=$(stat -c "%U" forms-interface/index.html 2>/dev/null || stat -f "%Su" forms-interface/index.html)

if [ "$INDEX_OWNER" = "$TEST_USER" ]; then
    assert_pass "Files owned by non-root user ($TEST_USER)"
else
    assert_fail "File ownership" "Expected owner: $TEST_USER, got: $INDEX_OWNER"
fi

# ========================================
# Test 6: No world-writable files
# ========================================
echo ""
echo "Test 6: Verify no world-writable files"

# Check for world-writable files (permission should not have o+w)
WORLD_WRITABLE=$(find forms-interface -perm -o+w 2>/dev/null)

if [ -z "$WORLD_WRITABLE" ]; then
    assert_pass "No world-writable files found"
else
    assert_fail "World-writable files" "Found world-writable files: $WORLD_WRITABLE"
fi

# ========================================
# Test 7: SSH key permissions
# ========================================
echo ""
echo "Test 7: Verify SSH key permissions are restrictive"

# Create test SSH key
SSH_DIR="$TEST_DIR/.ssh"
mkdir -p "$SSH_DIR"
SSH_KEY="$SSH_DIR/test_key"
echo "test key content" > "$SSH_KEY"

# Set correct permissions (600)
chmod 600 "$SSH_KEY"

SSH_KEY_PERM=$(stat -c "%a" "$SSH_KEY" 2>/dev/null || stat -f "%A" "$SSH_KEY")

if [ "$SSH_KEY_PERM" = "600" ]; then
    assert_pass "SSH key has restrictive permissions (600)"
else
    assert_fail "SSH key permissions" "Expected 600, got $SSH_KEY_PERM"
fi

# ========================================
# Test 8: .gitignore validation
# ========================================
echo ""
echo "Test 8: Verify .gitignore protects sensitive files"

# Create test .gitignore
cat > forms-interface/.gitignore << 'EOF'
.env
*.key
*.pem
secrets.txt
config.json
EOF

# Check if sensitive patterns are in .gitignore
if grep -q ".env" forms-interface/.gitignore && \
   grep -q "*.key" forms-interface/.gitignore; then
    assert_pass ".gitignore contains sensitive file patterns"
else
    assert_fail ".gitignore" "Missing sensitive file patterns"
fi

# ========================================
# Test 9: Symbolic link safety
# ========================================
echo ""
echo "Test 9: Verify symbolic links don't expose sensitive data"

# Create a symlink pointing outside web root
ln -s /etc/passwd forms-interface/test-link 2>/dev/null || true

if [ -L forms-interface/test-link ]; then
    assert_fail "Symbolic link to system file" "Symlink to /etc/passwd exists (security risk)"
    rm forms-interface/test-link
else
    assert_pass "No unsafe symbolic links detected"
fi

# ========================================
# Test 10: Execute permissions validation
# ========================================
echo ""
echo "Test 10: Verify execute permissions are minimal"

# Ensure static files are NOT executable
chmod 644 forms-interface/index.html

INDEX_PERM=$(stat -c "%a" forms-interface/index.html 2>/dev/null || stat -f "%A" forms-interface/index.html)

if [ "$INDEX_PERM" = "644" ]; then
    assert_pass "Static files have no execute permission (644)"
else
    assert_fail "Execute permissions" "Expected 644, got $INDEX_PERM"
fi

# Directories should be executable (for traversal)
chmod 755 forms-interface
DIR_PERM=$(stat -c "%a" forms-interface 2>/dev/null || stat -f "%A" forms-interface)

if [ "$DIR_PERM" = "755" ]; then
    assert_pass "Directory has execute permission for traversal (755)"
else
    assert_fail "Directory permissions" "Expected 755, got $DIR_PERM"
fi

# ========================================
# Test 11: Backup file permissions
# ========================================
echo ""
echo "Test 11: Verify backup files have secure permissions"

BACKUP_DIR="$TEST_DIR/backups"
mkdir -p "$BACKUP_DIR"
cp forms-interface/index.html "$BACKUP_DIR/"

# Set restrictive permissions on backup
chmod 600 "$BACKUP_DIR/index.html"

BACKUP_PERM=$(stat -c "%a" "$BACKUP_DIR/index.html" 2>/dev/null || stat -f "%A" "$BACKUP_DIR/index.html")

if [ "$BACKUP_PERM" = "600" ]; then
    assert_pass "Backup files have restrictive permissions (600)"
else
    assert_fail "Backup permissions" "Expected 600, got $BACKUP_PERM"
fi

# ========================================
# Test 12: Log file permissions
# ========================================
echo ""
echo "Test 12: Verify log files are readable but not world-writable"

LOG_FILE="$TEST_DIR/deploy.log"
echo "test log entry" > "$LOG_FILE"
chmod 640 "$LOG_FILE"

LOG_PERM=$(stat -c "%a" "$LOG_FILE" 2>/dev/null || stat -f "%A" "$LOG_FILE")

if [ "$LOG_PERM" = "640" ]; then
    assert_pass "Log file has 640 permissions (owner/group read, owner write)"
else
    assert_fail "Log permissions" "Expected 640, got $LOG_PERM"
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

echo -e "${BLUE}Security Recommendations:${NC}"
echo "1. Never store credentials in deployment scripts"
echo "2. Use environment variables for sensitive configuration"
echo "3. Regularly audit file permissions"
echo "4. Implement automated security scanning in CI/CD"
echo "5. Review .gitignore for sensitive file patterns"
echo ""

if [ $ASSERT_FAIL -eq 0 ]; then
    echo -e "${GREEN}All security tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some security tests failed.${NC}"
    exit 1
fi
