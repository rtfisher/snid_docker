#!/bin/bash

# Master Test Runner
# Runs all test suites for the SNID-Docker project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
QUICK_MODE=false
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --quick    Run only quick tests (skip integration tests)"
            echo "  --verbose  Show detailed output from tests"
            echo "  --help     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Make test scripts executable
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true

# Test results tracking
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Function to run a test suite
run_test_suite() {
    local test_script="$1"
    local test_name="$2"

    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Running: $test_name${NC}"
    echo -e "${BLUE}========================================${NC}"

    TOTAL_SUITES=$((TOTAL_SUITES + 1))

    if [ "$VERBOSE" = true ]; then
        if "$test_script"; then
            echo -e "${GREEN}✓ $test_name PASSED${NC}"
            PASSED_SUITES=$((PASSED_SUITES + 1))
            return 0
        else
            echo -e "${RED}✗ $test_name FAILED${NC}"
            FAILED_SUITES=$((FAILED_SUITES + 1))
            return 1
        fi
    else
        if "$test_script" > /tmp/test_output_$$.log 2>&1; then
            echo -e "${GREEN}✓ $test_name PASSED${NC}"
            PASSED_SUITES=$((PASSED_SUITES + 1))
            return 0
        else
            echo -e "${RED}✗ $test_name FAILED${NC}"
            echo "  See output below:"
            tail -30 /tmp/test_output_$$.log | sed 's/^/  /'
            FAILED_SUITES=$((FAILED_SUITES + 1))
            return 1
        fi
    fi
}

# Print header
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SNID-Docker Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ "$QUICK_MODE" = true ]; then
    echo -e "${YELLOW}Running in QUICK mode (skipping integration tests)${NC}"
fi

# Check if tests directory exists
if [ ! -d "$SCRIPT_DIR" ]; then
    echo -e "${RED}Error: Tests directory not found${NC}"
    exit 1
fi

# Run test suites
echo "Starting test execution..."
echo ""

# 1. Run run_snid.sh unit tests
if [ -f "$SCRIPT_DIR/test_run_snid.sh" ]; then
    run_test_suite "$SCRIPT_DIR/test_run_snid.sh" "run_snid.sh Unit Tests" || true
else
    echo -e "${YELLOW}⊘ Skipping run_snid.sh tests (script not found)${NC}"
fi

# 2. Run Docker build tests
if [ "$QUICK_MODE" = false ]; then
    if [ -f "$SCRIPT_DIR/test_docker_build.sh" ]; then
        run_test_suite "$SCRIPT_DIR/test_docker_build.sh" "Docker Build Tests" || true
    else
        echo -e "${YELLOW}⊘ Skipping Docker build tests (script not found)${NC}"
    fi
else
    echo -e "${YELLOW}⊘ Skipping Docker build tests (quick mode)${NC}"
fi

# 3. Run integration tests
if [ "$QUICK_MODE" = false ]; then
    if [ -f "$SCRIPT_DIR/test_integration.sh" ]; then
        run_test_suite "$SCRIPT_DIR/test_integration.sh" "Integration Tests" || true
    else
        echo -e "${YELLOW}⊘ Skipping integration tests (script not found)${NC}"
    fi
else
    echo -e "${YELLOW}⊘ Skipping integration tests (quick mode)${NC}"
fi

# Print final summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Final Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Total test suites run: $TOTAL_SUITES"
echo -e "${GREEN}Passed: $PASSED_SUITES${NC}"
echo -e "${RED}Failed: $FAILED_SUITES${NC}"
echo ""

# Cleanup temp files
rm -f /tmp/test_output_$$.log 2>/dev/null || true

# Exit with appropriate code
if [ $FAILED_SUITES -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}All test suites passed! ✓${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Some test suites failed! ✗${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
