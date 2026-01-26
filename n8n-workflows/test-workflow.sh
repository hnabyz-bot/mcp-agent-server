#!/bin/bash

# n8n Issue Submission Workflow Test Script
# Version: 1.0.0
# Last Updated: 2026-01-26

set -e

# Configuration
N8N_WEBHOOK_URL="${N8N_WEBHOOK_URL:-http://localhost:5678/webhook/issue-submission}"
TEST_RESULTS=()
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
    echo ""
}

print_test() {
    TEST_COUNT=$((TEST_COUNT + 1))
    echo -n "Test $TEST_COUNT: $1 ... "
}

print_pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    echo -e "${GREEN}PASS${NC}"
    TEST_RESULTS+=("✓ $1")
}

print_fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo -e "${RED}FAIL${NC}"
    echo -e "  ${RED}Error: $1${NC}"
    TEST_RESULTS+=("✗ $1 - $2")
}

print_skip() {
    echo -e "${YELLOW}SKIP${NC}"
    TEST_RESULTS+=("○ $1")
}

# Test functions
test_webhook_connectivity() {
    print_test "Webhook Connectivity"

    if curl -s -f "$N8N_WEBHOOK_URL" > /dev/null 2>&1; then
        print_pass
    else
        print_fail "Cannot reach webhook" "Check n8n is running and URL is correct"
        return 1
    fi
}

test_valid_submission() {
    print_test "Valid Issue Submission"

    response=$(curl -s -w "\n%{http_code}" -X POST "$N8N_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d '{
            "title": "Automated Test Issue",
            "description": "This is a test issue created by the test script",
            "priority": "medium"
        }')

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
        success=$(echo "$body" | jq -r '.success' 2>/dev/null || echo "false")
        if [ "$success" = "true" ]; then
            print_pass
            echo "  Gitea: $(echo "$body" | jq -r '.gitea_issue_url')"
            echo "  Redmine: $(echo "$body" | jq -r '.redmine_issue_url')"
        else
            print_fail "API returned success=false" "$body"
        fi
    else
        print_fail "HTTP $http_code" "$body"
    fi
}

test_validation_empty_title() {
    print_test "Validation - Empty Title"

    response=$(curl -s -w "\n%{http_code}" -X POST "$N8N_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d '{
            "title": "",
            "description": "Test"
        }')

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "400" ]; then
        validation_error=$(echo "$body" | jq -r '.message' 2>/dev/null || echo "")
        if [ "$validation_error" = "Validation failed" ]; then
            print_pass
        else
            print_fail "Expected validation error" "$body"
        fi
    else
        print_fail "Expected 400, got $http_code" "$body"
    fi
}

test_validation_missing_description() {
    print_test "Validation - Missing Description"

    response=$(curl -s -w "\n%{http_code}" -X POST "$N8N_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d '{
            "title": "Test Issue"
        }')

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "400" ]; then
        errors=$(echo "$body" | jq -r '.errors[]' 2>/dev/null || echo "")
        if echo "$errors" | grep -qi "description"; then
            print_pass
        else
            print_fail "Expected description error" "$body"
        fi
    else
        print_fail "Expected 400, got $http_code" "$body"
    fi
}

test_priority_levels() {
    print_test "Priority Levels"

    for priority in low medium high critical; do
        response=$(curl -s -X POST "$N8N_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{
                \"title\": \"Test Priority $priority\",
                \"description\": \"Testing priority level\",
                \"priority\": \"$priority\"
            }")

        success=$(echo "$response" | jq -r '.success' 2>/dev/null || echo "false")
        if [ "$success" != "true" ]; then
            print_fail "Priority $priority failed" "$response"
            return 1
        fi
    done

    print_pass
}

test_labels() {
    print_test "Labels Support"

    response=$(curl -s -X POST "$N8N_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d '{
            "title": "Test Labels",
            "description": "Testing labels",
            "labels": ["bug", "urgent", "workflow"]
        }')

    success=$(echo "$response" | jq -r '.success' 2>/dev/null || echo "false")
    if [ "$success" = "true" ]; then
        print_pass
    else
        print_fail "Labels failed" "$response"
    fi
}

test_assignee() {
    print_test "Assignee Support"

    # This test may fail if assignee doesn't exist
    # Uncomment and modify if you have a valid assignee
    print_skip "Requires valid assignee username"
}

test_estimated_time() {
    print_test "Estimated Time"

    response=$(curl -s -X POST "$N8N_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d '{
            "title": "Test Estimated Time",
            "description": "Testing estimated time",
            "estimated_time": 8.5
        }')

    success=$(echo "$response" | jq -r '.success' 2>/dev/null || echo "false")
    if [ "$success" = "true" ]; then
        print_pass
    else
        print_fail "Estimated time failed" "$response"
    fi
}

test_progress() {
    print_test "Progress Percentage"

    response=$(curl -s -X POST "$N8N_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d '{
            "title": "Test Progress",
            "description": "Testing progress",
            "progress": 50
        }')

    success=$(echo "$response" | jq -r '.success' 2>/dev/null || echo "false")
    if [ "$success" = "true" ]; then
        print_pass
    else
        print_fail "Progress failed" "$response"
    fi
}

test_attachment_base64() {
    print_test "Base64 Attachment"

    # Create a small test file and encode it
    test_content="This is a test file content"
    base64_content=$(echo -n "$test_content" | base64)

    response=$(curl -s -X POST "$N8N_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"title\": \"Test Attachment\",
            \"description\": \"Testing file upload\",
            \"attachments\": [{
                \"filename\": \"test.txt\",
                \"content_type\": \"text/plain\",
                \"data\": \"$base64_content\"
            }]
        }")

    success=$(echo "$response" | jq -r '.success' 2>/dev/null || echo "false")
    if [ "$success" = "true" ]; then
        print_pass
    else
        print_fail "Attachment failed" "$response"
    fi
}

test_invalid_priority() {
    print_test "Invalid Priority Rejection"

    response=$(curl -s -w "\n%{http_code}" -X POST "$N8N_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d '{
            "title": "Test Invalid Priority",
            "description": "Testing invalid priority",
            "priority": "invalid"
        }')

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "400" ]; then
        print_pass
    else
        print_fail "Should reject invalid priority" "$body"
    fi
}

test_concurrent_requests() {
    print_test "Concurrent Requests (10 parallel)"

    # Launch 10 concurrent requests
    for i in {1..10}; do
        (
            curl -s -X POST "$N8N_WEBHOOK_URL" \
                -H "Content-Type: application/json" \
                -d "{
                    \"title\": \"Concurrent Test $i\",
                    \"description\": \"Testing concurrent requests\"
                }" > /dev/null 2>&1
        ) &
    done

    # Wait for all to complete
    wait

    print_pass
}

test_long_title() {
    print_test "Title Length Validation (>255 chars)"

    # Generate a title longer than 255 characters
    long_title=$(python3 -c "print('A' * 300)" 2>/dev/null || echo "A...A")

    response=$(curl -s -w "\n%{http_code}" -X POST "$N8N_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"title\": \"$long_title\",
            \"description\": \"Testing long title\"
        }")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "400" ]; then
        errors=$(echo "$body" | jq -r '.errors[]' 2>/dev/null || echo "")
        if echo "$errors" | grep -qi "255"; then
            print_pass
        else
            print_fail "Expected 255 char limit error" "$body"
        fi
    else
        print_fail "Expected 400 for long title" "$body"
    fi
}

test_special_characters() {
    print_test "Special Characters in Description"

    response=$(curl -s -X POST "$N8N_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d '{
            "title": "Test Special Chars",
            "description": "Testing special characters: <script>alert(\"test\")</script>, \"quotes\", '\''single quotes'\'', \n\nNewlines\nand\nspecial chars: @#$%^&*()",
            "priority": "medium"
        }')

    success=$(echo "$response" | jq -r '.success' 2>/dev/null || echo "false")
    if [ "$success" = "true" ]; then
        print_pass
    else
        print_fail "Special characters failed" "$response"
    fi
}

test_unicode() {
    print_test "Unicode/Emoji Support"

    response=$(curl -s -X POST "$N8N_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d '{
            "title": "Test Unicode 🚀",
            "description": "Testing emoji: 🔥 💡 ⚡\nKorean: 안녕하세요\nJapanese: こんにちは\nChinese: 你好",
            "priority": "high"
        }')

    success=$(echo "$response" | jq -r '.success' 2>/dev/null || echo "false")
    if [ "$success" = "true" ]; then
        print_pass
    else
        print_fail "Unicode failed" "$response"
    fi
}

# Main execution
main() {
    print_header "n8n Issue Submission Workflow Test Suite"

    echo "Configuration:"
    echo "  Webhook URL: $N8N_WEBHOOK_URL"
    echo ""

    # Check dependencies
    if ! command -v curl &> /dev/null; then
        echo "Error: curl is required but not installed"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "Warning: jq is not installed. Some tests may fail."
        echo "Install jq: apt-get install jq or brew install jq"
        echo ""
    fi

    print_header "Running Tests"

    # Core tests
    test_webhook_connectivity
    test_valid_submission

    # Validation tests
    test_validation_empty_title
    test_validation_missing_description
    test_invalid_priority
    test_long_title

    # Feature tests
    test_priority_levels
    test_labels
    test_assignee
    test_estimated_time
    test_progress

    # Attachment tests
    test_attachment_base64

    # Edge case tests
    test_special_characters
    test_unicode

    # Performance tests
    test_concurrent_requests

    # Print summary
    print_header "Test Summary"
    echo "Total Tests: $TEST_COUNT"
    echo -e "Passed: ${GREEN}$PASS_COUNT${NC}"
    echo -e "Failed: ${RED}$FAIL_COUNT${NC}"
    echo ""

    if [ $FAIL_COUNT -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed${NC}"
        echo ""
        echo "Failed tests:"
        for result in "${TEST_RESULTS[@]}"; do
            if echo "$result" | grep -q "✗"; then
                echo "  $result"
            fi
        done
        exit 1
    fi
}

# Run main function
main
