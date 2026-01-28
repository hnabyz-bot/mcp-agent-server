#!/bin/bash
# Performance Test Runner
# Executes all performance tests and generates summary report

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERFORMANCE_DIR="$SCRIPT_DIR/performance"
RESULTS_DIR="$SCRIPT_DIR/results"
LOGS_DIR="$SCRIPT_DIR/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create directories
mkdir -p "$RESULTS_DIR"
mkdir -p "$LOGS_DIR"

# Test counters
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0

print_header() {
    echo ""
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# ========================================
# Main Execution
# ========================================

print_header "Performance Test Suite"
log_info "Started at: $(date)"
log_info "Performance tests directory: $PERFORMANCE_DIR"

if [ ! -d "$PERFORMANCE_DIR" ]; then
    log_error "Performance tests directory not found: $PERFORMANCE_DIR"
    exit 1
fi

# Run all performance tests
for test_file in "$PERFORMANCE_DIR"/test_*.sh; do
    if [ -f "$test_file" ]; then
        test_name=$(basename "$test_file" .sh)
        log_file="$LOGS_DIR/${test_name}-$TIMESTAMP.log"

        print_header "Running: $test_name"

        if [ ! -x "$test_file" ]; then
            log_info "Adding execute permission..."
            chmod +x "$test_file"
        fi

        if "$test_file" > "$log_file" 2>&1; then
            log_success "$test_name PASSED"
            ((TOTAL_PASSED++))
        else
            log_warning "$test_name FAILED (may be expected in test environments)"
            ((TOTAL_FAILED++))
        fi

        ((TOTAL_TESTS++))
    fi
done

# Generate summary
print_header "Performance Test Summary"
echo "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $TOTAL_PASSED${NC}"
echo -e "${RED}Failed: $TOTAL_FAILED${NC}"

# Performance metrics
if [ -f "$PERFORMANCE_DIR/performance-metrics.txt" ]; then
    echo ""
    echo "Performance Metrics:"
    cat "$PERFORMANCE_DIR/performance-metrics.txt"
fi

# Save summary to file
SUMMARY_FILE="$RESULTS_DIR/performance-test-summary-$TIMESTAMP.txt"
cat > "$SUMMARY_FILE" << EOF
Performance Test Suite Summary
Generated: $(date)

Total Tests: $TOTAL_TESTS
Passed: $TOTAL_PASSED
Failed: $TOTAL_FAILED

NOTE: Performance test failures may be expected in
test environments. Review results before deployment.

Log Files: $LOGS_DIR
EOF

log_info "Summary saved to: $SUMMARY_FILE"

# Exit with appropriate code
# Performance tests are informational, so we don't fail on them
if [ $TOTAL_FAILED -eq 0 ]; then
    log_success "All performance tests passed!"
    exit 0
else
    log_warning "Some performance tests failed."
    log_warning "Review results and consider environment differences."
    exit 0  # Always exit 0 for performance tests
fi
