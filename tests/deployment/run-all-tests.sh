#!/bin/bash
# Main Test Runner: Execute All Deployment Tests
# Runs all test suites and generates comprehensive report

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
TOTAL_SKIPPED=0

# Arrays for results
declare -a TEST_RESULTS=()

# Helper functions
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

print_header() {
    echo ""
    echo -e "${MAGENTA}=========================================${NC}"
    echo -e "${MAGENTA}$1${NC}"
    echo -e "${MAGENTA}=========================================${NC}"
    echo ""
}

# ========================================
# Test Suite Execution Functions
# ========================================

run_test_file() {
    local test_file="$1"
    local test_name="$2"
    local log_file="$LOGS_DIR/$(basename "$test_file" .sh)-$TIMESTAMP.log"

    print_header "Running: $test_name"

    if [ ! -f "$test_file" ]; then
        log_error "Test file not found: $test_file"
        TEST_RESULTS+=("FAILED|$test_name|File not found")
        ((TOTAL_FAILED++))
        return 1
    fi

    if [ ! -x "$test_file" ]; then
        log_warning "Test file not executable, adding execute permission..."
        chmod +x "$test_file"
    fi

    # Run test and capture output
    log_info "Executing: $test_file"
    log_info "Log file: $log_file"

    if "$test_file" > "$log_file" 2>&1; then
        log_success "$test_name PASSED"

        # Extract pass/fail counts from log
        local passed=$(grep -o "Passed: [0-9]*" "$log_file" | grep -o "[0-9]*" | head -1)
        local failed=$(grep -o "Failed: [0-9]*" "$log_file" | grep -o "[0-9]*" | head -1)
        local total=$((passed + failed))

        TEST_RESULTS+=("PASSED|$test_name|$passed/$total tests passed")

        ((TOTAL_PASSED++))
        ((TOTAL_TESTS++))
        return 0
    else
        log_error "$test_name FAILED"

        # Extract failure details
        local failed=$(grep -o "Failed: [0-9]*" "$log_file" | grep -o "[0-9]*" | head -1)
        local error_msg=$(tail -n 5 "$log_file" | head -n 1)

        TEST_RESULTS+=("FAILED|$test_name|$error_msg")

        ((TOTAL_FAILED++))
        ((TOTAL_TESTS++))
        return 1
    fi
}

run_unit_tests() {
    print_header "Phase 1: Unit Tests"

    local unit_dir="$SCRIPT_DIR/unit"
    local count=0

    if [ ! -d "$unit_dir" ]; then
        log_error "Unit tests directory not found"
        return 1
    fi

    for test_file in "$unit_dir"/test_*.sh; do
        if [ -f "$test_file" ]; then
            local test_name=$(basename "$test_file" .sh)
            run_test_file "$test_file" "Unit Test: $test_name"
            ((count++))
        fi
    done

    log_info "Unit tests completed: $count test files executed"
}

run_integration_tests() {
    print_header "Phase 2: Integration Tests"

    local integration_dir="$SCRIPT_DIR/integration"
    local count=0

    if [ ! -d "$integration_dir" ]; then
        log_error "Integration tests directory not found"
        return 1
    fi

    for test_file in "$integration_dir"/test_*.sh; do
        if [ -f "$test_file" ]; then
            local test_name=$(basename "$test_file" .sh)
            run_test_file "$test_file" "Integration Test: $test_name"
            ((count++))
        fi
    done

    log_info "Integration tests completed: $count test files executed"
}

run_edge_case_tests() {
    print_header "Phase 3: Edge Case Tests"

    local edge_dir="$SCRIPT_DIR/edge_cases"
    local count=0

    if [ ! -d "$edge_dir" ]; then
        log_error "Edge case tests directory not found"
        return 1
    fi

    for test_file in "$edge_dir"/test_*.sh; do
        if [ -f "$test_file" ]; then
            local test_name=$(basename "$test_file" .sh)
            run_test_file "$test_file" "Edge Case Test: $test_name"
            ((count++))
        fi
    done

    log_info "Edge case tests completed: $count test files executed"
}

run_security_tests() {
    print_header "Phase 4: Security Tests"

    local security_dir="$SCRIPT_DIR/security"
    local count=0

    if [ ! -d "$security_dir" ]; then
        log_error "Security tests directory not found"
        return 1
    fi

    for test_file in "$security_dir"/test_*.sh; do
        if [ -f "$test_file" ]; then
            local test_name=$(basename "$test_file" .sh)
            run_test_file "$test_file" "Security Test: $test_name"
            ((count++))
        fi
    done

    log_info "Security tests completed: $count test files executed"
}

run_performance_tests() {
    print_header "Phase 5: Performance Tests"

    local performance_dir="$SCRIPT_DIR/performance"
    local count=0

    if [ ! -d "$performance_dir" ]; then
        log_error "Performance tests directory not found"
        return 1
    fi

    for test_file in "$performance_dir"/test_*.sh; do
        if [ -f "$test_file" ]; then
            local test_name=$(basename "$test_file" .sh)
            run_test_file "$test_file" "Performance Test: $test_name"
            ((count++))
        fi
    done

    log_info "Performance tests completed: $count test files executed"
}

# ========================================
# Report Generation
# ========================================

generate_text_report() {
    local report_file="$RESULTS_DIR/test-summary-$TIMESTAMP.txt"

    print_header "Generating Report"

    cat > "$report_file" << EOF
========================================
Deployment Test Suite Summary
========================================
Generated: $(date)
Test Run ID: $TIMESTAMP

========================================
Overall Results
========================================
Total Test Suites: $TOTAL_TESTS
Passed: $TOTAL_PASSED
Failed: $TOTAL_FAILED
Skipped: $TOTAL_SKIPPED
Success Rate: $(echo "scale=2; $TOTAL_PASSED * 100 / $TOTAL_TESTS" | bc)%

========================================
Detailed Results
========================================

EOF

    for result in "${TEST_RESULTS[@]}"; do
        IFS='|' read -r status name message <<< "$result"
        echo "[$status] $name" >> "$report_file"
        echo "  $message" >> "$report_file"
        echo "" >> "$report_file"
    done

    cat >> "$report_file" << EOF

========================================
Log Files Location
========================================
$LOGS_DIR

========================================
End of Report
========================================
EOF

    log_success "Report generated: $report_file"
    cat "$report_file"
}

generate_html_report() {
    local report_file="$RESULTS_DIR/test-summary-$TIMESTAMP.html"

    cat > "$report_file" << EOF
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Deployment Test Report - $TIMESTAMP</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header h1 {
            margin: 0 0 10px 0;
            font-size: 2em;
        }
        .header .timestamp {
            opacity: 0.9;
            font-size: 0.9em;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        .summary-card h3 {
            margin: 0 0 10px 0;
            color: #666;
            font-size: 0.9em;
            text-transform: uppercase;
        }
        .summary-card .value {
            font-size: 2.5em;
            font-weight: bold;
            margin: 0;
        }
        .value.passed { color: #10b981; }
        .value.failed { color: #ef4444; }
        .value.total { color: #3b82f6; }
        .results-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        .results-section h2 {
            margin-top: 0;
            color: #1f2937;
            border-bottom: 2px solid #e5e7eb;
            padding-bottom: 15px;
        }
        .test-result {
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
            border-left: 4px solid;
        }
        .test-result.passed {
            background-color: #f0fdf4;
            border-left-color: #10b981;
        }
        .test-result.failed {
            background-color: #fef2f2;
            border-left-color: #ef4444;
        }
        .test-result .status {
            font-weight: bold;
            text-transform: uppercase;
            font-size: 0.85em;
            margin-bottom: 5px;
        }
        .test-result.passed .status { color: #10b981; }
        .test-result.failed .status { color: #ef4444; }
        .test-result .name {
            font-size: 1.1em;
            font-weight: 600;
            margin: 5px 0;
        }
        .test-result .message {
            color: #6b7280;
            font-size: 0.9em;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding: 20px;
            color: #6b7280;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Deployment Test Report</h1>
        <div class="timestamp">Generated: $(date)</div>
        <div class="timestamp">Test Run ID: $TIMESTAMP</div>
    </div>

    <div class="summary">
        <div class="summary-card">
            <h3>Total Tests</h3>
            <p class="value total">$TOTAL_TESTS</p>
        </div>
        <div class="summary-card">
            <h3>Passed</h3>
            <p class="value passed">$TOTAL_PASSED</p>
        </div>
        <div class="summary-card">
            <h3>Failed</h3>
            <p class="value failed">$TOTAL_FAILED</p>
        </div>
        <div class="summary-card">
            <h3>Success Rate</h3>
            <p class="value total">$(echo "scale=1; $TOTAL_PASSED * 100 / $TOTAL_TESTS" | bc)%</p>
        </div>
    </div>

    <div class="results-section">
        <h2>Detailed Results</h2>

EOF

    for result in "${TEST_RESULTS[@]}"; do
        IFS='|' read -r status name message <<< "$result"

        local status_class=""
        if [ "$status" = "PASSED" ]; then
            status_class="passed"
        else
            status_class="failed"
        fi

        cat >> "$report_file" << EOF
        <div class="test-result $status_class">
            <div class="status">$status</div>
            <div class="name">$name</div>
            <div class="message">$message</div>
        </div>

EOF
    done

    cat >> "$report_file" << EOF
    </div>

    <div class="footer">
        <p>Log files: $LOGS_DIR</p>
        <p>Generated by Deployment Test Suite v1.0.0</p>
    </div>
</body>
</html>
EOF

    log_success "HTML report generated: $report_file"
}

# ========================================
# Main Execution
# ========================================

main() {
    local start_time=$(date +%s)

    print_header "Deployment Test Suite"
    log_info "Started at: $(date)"
    log_info "Test Run ID: $TIMESTAMP"
    log_info "Results directory: $RESULTS_DIR"
    log_info "Logs directory: $LOGS_DIR"

    # Check if bc is installed (needed for calculations)
    if ! command -v bc > /dev/null 2>&1; then
        log_error "bc is not installed. Install it with: sudo apt-get install bc"
        exit 1
    fi

    # Run all test suites
    run_unit_tests
    run_integration_tests
    run_edge_case_tests
    run_security_tests
    run_performance_tests

    # Calculate duration
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    # Generate reports
    generate_text_report
    generate_html_report

    # Final summary
    print_header "Test Suite Completed"
    log_info "Duration: ${minutes}m ${seconds}s"
    log_info "Total Test Suites: $TOTAL_TESTS"
    log_success "Passed: $TOTAL_PASSED"

    if [ $TOTAL_FAILED -gt 0 ]; then
        log_error "Failed: $TOTAL_FAILED"
    fi

    if [ $TOTAL_SKIPPED -gt 0 ]; then
        log_warning "Skipped: $TOTAL_SKIPPED"
    fi

    # Exit with appropriate code
    if [ $TOTAL_FAILED -eq 0 ]; then
        log_success "All tests passed!"
        exit 0
    else
        log_error "Some tests failed!"
        exit 1
    fi
}

# Run main function
main "$@"
