#!/bin/bash

# Test utilities and helper functions for SNID-Docker test suite
# Provides common testing functions and assertions

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Print test header
print_test_header() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
}

# Print test result
print_result() {
    local test_name="$1"
    local result="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [ "$result" == "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Print test summary
print_summary() {
    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "Total tests run: $TESTS_RUN"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        return 1
    fi
}

# Assert equals
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [ "$expected" == "$actual" ]; then
        print_result "$test_name" "PASS"
        return 0
    else
        print_result "$test_name (expected: '$expected', got: '$actual')" "FAIL"
        return 1
    fi
}

# Assert command succeeds
assert_success() {
    local test_name="$1"
    shift
    local cmd="$@"

    if eval "$cmd" &>/dev/null; then
        print_result "$test_name" "PASS"
        return 0
    else
        print_result "$test_name (command failed: $cmd)" "FAIL"
        return 1
    fi
}

# Assert command fails
assert_fails() {
    local test_name="$1"
    shift
    local cmd="$@"

    if ! eval "$cmd" &>/dev/null; then
        print_result "$test_name" "PASS"
        return 0
    else
        print_result "$test_name (command should have failed: $cmd)" "FAIL"
        return 1
    fi
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    local test_name="$2"

    if [ -f "$file" ]; then
        print_result "$test_name" "PASS"
        return 0
    else
        print_result "$test_name (file not found: $file)" "FAIL"
        return 1
    fi
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"
    local test_name="$2"

    if [ -d "$dir" ]; then
        print_result "$test_name" "PASS"
        return 0
    else
        print_result "$test_name (directory not found: $dir)" "FAIL"
        return 1
    fi
}

# Assert string contains
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    if [[ "$haystack" == *"$needle"* ]]; then
        print_result "$test_name" "PASS"
        return 0
    else
        print_result "$test_name ('$haystack' does not contain '$needle')" "FAIL"
        return 1
    fi
}

# Assert not empty
assert_not_empty() {
    local value="$1"
    local test_name="$2"

    if [ -n "$value" ]; then
        print_result "$test_name" "PASS"
        return 0
    else
        print_result "$test_name (value is empty)" "FAIL"
        return 1
    fi
}

# Mock command - useful for testing scripts that call external commands
mock_command() {
    local cmd_name="$1"
    local mock_output="$2"
    local mock_return="${3:-0}"

    eval "${cmd_name}() { echo '$mock_output'; return $mock_return; }"
}

# Skip test with reason
skip_test() {
    local reason="$1"
    echo -e "${YELLOW}⊘ SKIP${NC}: $reason"
}
