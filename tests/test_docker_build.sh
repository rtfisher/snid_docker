#!/bin/bash

# Docker Build Validation Tests
# Tests that verify the Docker image builds correctly and contains all required components

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_utils.sh"

# Test configuration
IMAGE_NAME="snid-app-test"
DOCKERFILE_PATH="$SCRIPT_DIR/../snid_dockerfile"
BUILD_CONTEXT="$SCRIPT_DIR/.."

print_test_header "Docker Build Validation Tests"

# Cleanup function
cleanup() {
    echo "Cleaning up test artifacts..."
    docker rmi -f "$IMAGE_NAME" 2>/dev/null || true
}

# Set trap for cleanup
trap cleanup EXIT

# Test 1: Dockerfile exists
test_dockerfile_exists() {
    assert_file_exists "$DOCKERFILE_PATH" "Dockerfile exists"
}

# Test 2: Required source files exist
test_required_files_exist() {
    assert_file_exists "$BUILD_CONTEXT/run_snid.sh" "run_snid.sh exists"
    assert_file_exists "$BUILD_CONTEXT/Makefile" "Makefile exists"
}

# Test 3: Docker is available
test_docker_available() {
    if command -v docker &> /dev/null; then
        print_result "Docker command is available" "PASS"
    else
        print_result "Docker command is available" "FAIL"
        skip_test "Docker not available - skipping remaining tests"
        print_summary
        exit 0
    fi
}

# Test 4: Docker daemon is running
test_docker_running() {
    if docker info &> /dev/null; then
        print_result "Docker daemon is running" "PASS"
    else
        print_result "Docker daemon is running" "FAIL"
        skip_test "Docker daemon not running - skipping remaining tests"
        print_summary
        exit 0
    fi
}

# Test 5: Check if required tarballs exist
test_tarballs_exist() {
    local snid_tarball="$BUILD_CONTEXT/snid-5.0.tar.gz"
    local templates_tarball="$BUILD_CONTEXT/templates-2.0.tgz"

    if [ -f "$snid_tarball" ] && [ -f "$templates_tarball" ]; then
        print_result "Required tarballs exist (snid-5.0.tar.gz, templates-2.0.tgz)" "PASS"
        return 0
    else
        print_result "Required tarballs exist" "FAIL"
        echo "  Note: snid-5.0.tar.gz and templates-2.0.tgz are required for build"
        echo "  Download from: https://people.lam.fr/blondin.stephane/software/snid/"
        skip_test "Missing tarballs - skipping build tests"
        print_summary
        exit 0
    fi
}

# Test 6: Docker image builds successfully
test_docker_build() {
    echo "Building Docker image (this may take several minutes)..."

    if docker build -t "$IMAGE_NAME" -f "$DOCKERFILE_PATH" "$BUILD_CONTEXT" > /tmp/docker_build.log 2>&1; then
        print_result "Docker image builds successfully" "PASS"
        return 0
    else
        print_result "Docker image builds successfully" "FAIL"
        echo "  Build log:"
        tail -20 /tmp/docker_build.log | sed 's/^/  /'
        return 1
    fi
}

# Test 7: Verify PGPLOT installation in container
test_pgplot_installed() {
    echo "Verifying PGPLOT installation..."

    local pgplot_check=$(docker run --rm "$IMAGE_NAME" bash -c "ls /usr/local/pgplot/libpgplot.* 2>/dev/null || echo 'NOT_FOUND'")

    if [[ "$pgplot_check" != "NOT_FOUND" ]]; then
        print_result "PGPLOT library installed in container" "PASS"
    else
        print_result "PGPLOT library installed in container" "FAIL"
    fi
}

# Test 8: Verify PGPLOT environment variables
test_pgplot_env_vars() {
    echo "Verifying PGPLOT environment variables..."

    local pgplot_dir=$(docker run --rm "$IMAGE_NAME" bash -c 'echo $PGPLOT_DIR')
    local pgplot_font=$(docker run --rm "$IMAGE_NAME" bash -c 'echo $PGPLOT_FONT')

    assert_equals "/usr/local/pgplot" "$pgplot_dir" "PGPLOT_DIR environment variable set"
    assert_equals "/usr/local/pgplot/grfont.dat" "$pgplot_font" "PGPLOT_FONT environment variable set"
}

# Test 9: Verify SNID binary exists
test_snid_binary_exists() {
    echo "Verifying SNID binary..."

    local snid_check=$(docker run --rm "$IMAGE_NAME" bash -c "ls /home/sniduser/snid-5.0/snid 2>/dev/null || echo 'NOT_FOUND'")

    if [[ "$snid_check" != "NOT_FOUND" ]]; then
        print_result "SNID binary exists in container" "PASS"
    else
        print_result "SNID binary exists in container" "FAIL"
    fi
}

# Test 10: Verify SNID is executable
test_snid_executable() {
    echo "Verifying SNID is executable..."

    if docker run --rm "$IMAGE_NAME" bash -c "test -x /home/sniduser/snid-5.0/snid"; then
        print_result "SNID binary is executable" "PASS"
    else
        print_result "SNID binary is executable" "FAIL"
    fi
}

# Test 11: Verify templates directory exists
test_templates_directory() {
    echo "Verifying templates directory..."

    if docker run --rm "$IMAGE_NAME" bash -c "test -d /home/sniduser/snid-5.0/templates-2.0"; then
        print_result "Templates directory exists in container" "PASS"
    else
        print_result "Templates directory exists in container" "FAIL"
    fi
}

# Test 12: Verify user permissions
test_user_permissions() {
    echo "Verifying user permissions..."

    local user=$(docker run --rm "$IMAGE_NAME" whoami)

    assert_equals "sniduser" "$user" "Container runs as sniduser"
}

# Test 13: Verify working directory
test_working_directory() {
    echo "Verifying working directory..."

    local pwd=$(docker run --rm "$IMAGE_NAME" pwd)

    assert_equals "/home/sniduser/snid-5.0" "$pwd" "Working directory is /home/sniduser/snid-5.0"
}

# Test 14: Verify additional utilities exist
test_utilities_exist() {
    echo "Verifying additional utilities..."

    local logwave_check=$(docker run --rm "$IMAGE_NAME" bash -c "ls /home/sniduser/snid-5.0/logwave 2>/dev/null || echo 'NOT_FOUND'")
    local plotlnw_check=$(docker run --rm "$IMAGE_NAME" bash -c "ls /home/sniduser/snid-5.0/plotlnw 2>/dev/null || echo 'NOT_FOUND'")

    if [[ "$logwave_check" != "NOT_FOUND" ]]; then
        print_result "logwave utility exists" "PASS"
    else
        print_result "logwave utility exists" "FAIL"
    fi

    if [[ "$plotlnw_check" != "NOT_FOUND" ]]; then
        print_result "plotlnw utility exists" "PASS"
    else
        print_result "plotlnw utility exists" "FAIL"
    fi
}

# Test 15: Verify examples directory
test_examples_directory() {
    echo "Verifying examples directory..."

    if docker run --rm "$IMAGE_NAME" bash -c "test -d /home/sniduser/snid-5.0/examples"; then
        print_result "Examples directory exists" "PASS"
    else
        print_result "Examples directory exists" "FAIL"
    fi
}

# Run all tests
main() {
    test_dockerfile_exists
    test_required_files_exist
    test_docker_available
    test_docker_running
    test_tarballs_exist
    test_docker_build
    test_pgplot_installed
    test_pgplot_env_vars
    test_snid_binary_exists
    test_snid_executable
    test_templates_directory
    test_user_permissions
    test_working_directory
    test_utilities_exist
    test_examples_directory

    print_summary
}

main
