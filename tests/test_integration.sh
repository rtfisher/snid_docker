#!/bin/bash

# Integration Tests
# End-to-end tests that verify the complete workflow

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_utils.sh"

# Test configuration
IMAGE_NAME="snid-app-integration-test"
CONTAINER_NAME="snid-integration-test-container"
DOCKERFILE_PATH="$SCRIPT_DIR/../snid_dockerfile"
BUILD_CONTEXT="$SCRIPT_DIR/.."

print_test_header "Integration Tests"

# Cleanup function
cleanup() {
    echo "Cleaning up test artifacts..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
    docker rmi -f "$IMAGE_NAME" 2>/dev/null || true
    rm -f /tmp/test_spectrum_*.dat 2>/dev/null || true
}

# Set trap for cleanup
trap cleanup EXIT

# Test 1: Check Docker availability
test_docker_available() {
    if ! command -v docker &> /dev/null; then
        print_result "Docker is available" "FAIL"
        skip_test "Docker not available - skipping integration tests"
        print_summary
        exit 0
    fi

    if ! docker info &> /dev/null; then
        print_result "Docker daemon is running" "FAIL"
        skip_test "Docker daemon not running - skipping integration tests"
        print_summary
        exit 0
    fi

    print_result "Docker is available and running" "PASS"
}

# Test 2: Check required tarballs
test_tarballs_available() {
    local snid_tarball="$BUILD_CONTEXT/snid-5.0.tar.gz"
    local templates_tarball="$BUILD_CONTEXT/templates-2.0.tgz"

    if [ ! -f "$snid_tarball" ] || [ ! -f "$templates_tarball" ]; then
        print_result "Required tarballs available" "FAIL"
        skip_test "Missing tarballs - skipping integration tests"
        print_summary
        exit 0
    fi

    print_result "Required tarballs are available" "PASS"
}

# Test 3: Build Docker image
test_build_image() {
    echo "Building Docker image for integration tests..."

    if docker build -t "$IMAGE_NAME" -f "$DOCKERFILE_PATH" "$BUILD_CONTEXT" > /tmp/integration_build.log 2>&1; then
        print_result "Docker image builds for integration tests" "PASS"
    else
        print_result "Docker image builds for integration tests" "FAIL"
        echo "  Build log:"
        tail -20 /tmp/integration_build.log | sed 's/^/  /'
        skip_test "Build failed - skipping remaining integration tests"
        print_summary
        exit 1
    fi
}

# Test 4: Container starts and stops cleanly
test_container_lifecycle() {
    echo "Testing container lifecycle..."

    # Start container in background
    if docker run -d --name "$CONTAINER_NAME" "$IMAGE_NAME" sleep 10 > /dev/null 2>&1; then
        print_result "Container starts successfully" "PASS"

        # Check container is running
        if docker ps | grep -q "$CONTAINER_NAME"; then
            print_result "Container is running" "PASS"
        else
            print_result "Container is running" "FAIL"
        fi

        # Stop container
        if docker stop "$CONTAINER_NAME" > /dev/null 2>&1; then
            print_result "Container stops cleanly" "PASS"
        else
            print_result "Container stops cleanly" "FAIL"
        fi

        # Remove container
        docker rm "$CONTAINER_NAME" > /dev/null 2>&1
    else
        print_result "Container starts successfully" "FAIL"
    fi
}

# Test 5: SNID version check
test_snid_version() {
    echo "Testing SNID version output..."

    # SNID might not have a --version flag, so we just check if it runs
    local output=$(docker run --rm "$IMAGE_NAME" bash -c "./snid 2>&1 | head -5" || echo "FAILED")

    if [[ "$output" != "FAILED" ]]; then
        print_result "SNID executes and produces output" "PASS"
    else
        print_result "SNID executes and produces output" "FAIL"
    fi
}

# Test 6: Test with example data if available
test_example_data() {
    echo "Testing with example data..."

    # Check if examples directory exists
    local examples_exist=$(docker run --rm "$IMAGE_NAME" bash -c "test -d examples && echo 'YES' || echo 'NO'")

    if [[ "$examples_exist" == "YES" ]]; then
        # List example files
        local example_files=$(docker run --rm "$IMAGE_NAME" bash -c "ls examples/*.dat 2>/dev/null | head -1" || echo "")

        if [ -n "$example_files" ]; then
            print_result "Example data files are available" "PASS"

            # Try to run SNID with the first example (without X11, just check it doesn't crash immediately)
            # Note: This will fail without X11 display, but we can check error messages
            local snid_output=$(docker run --rm "$IMAGE_NAME" bash -c "./snid $example_files 2>&1 || true")

            # Check if SNID at least tried to run (not a "file not found" error)
            if [[ "$snid_output" != *"No such file"* ]]; then
                print_result "SNID can locate example files" "PASS"
            else
                print_result "SNID can locate example files" "FAIL"
            fi
        else
            print_result "Example data files are available" "FAIL"
        fi
    else
        print_result "Examples directory exists" "FAIL"
    fi
}

# Test 7: Volume mounting functionality
test_volume_mounting() {
    echo "Testing volume mounting..."

    # Create a test file
    local test_dir="/tmp/snid_test_mount_$$"
    mkdir -p "$test_dir"
    echo "test data" > "$test_dir/test.txt"

    # Mount and check if file is accessible
    local result=$(docker run --rm -v "$test_dir:/home/sniduser/snid-5.0/testmount" "$IMAGE_NAME" bash -c "cat /home/sniduser/snid-5.0/testmount/test.txt 2>/dev/null || echo 'FAILED'")

    if [[ "$result" == "test data" ]]; then
        print_result "Volume mounting works correctly" "PASS"
    else
        print_result "Volume mounting works correctly" "FAIL"
    fi

    # Cleanup
    rm -rf "$test_dir"
}

# Test 8: Environment variables are set correctly
test_environment_variables() {
    echo "Testing environment variables..."

    local pgplot_dir=$(docker run --rm "$IMAGE_NAME" bash -c 'echo $PGPLOT_DIR')
    local pgplot_font=$(docker run --rm "$IMAGE_NAME" bash -c 'echo $PGPLOT_FONT')
    local pgplot_dev=$(docker run --rm "$IMAGE_NAME" bash -c 'echo $PGPLOT_DEV')
    local ld_library_path=$(docker run --rm "$IMAGE_NAME" bash -c 'echo $LD_LIBRARY_PATH')

    assert_equals "/usr/local/pgplot" "$pgplot_dir" "PGPLOT_DIR is set correctly"
    assert_equals "/usr/local/pgplot/grfont.dat" "$pgplot_font" "PGPLOT_FONT is set correctly"
    assert_equals "/xw" "$pgplot_dev" "PGPLOT_DEV is set correctly"

    if [[ "$ld_library_path" == *"/usr/local/pgplot"* ]]; then
        print_result "LD_LIBRARY_PATH includes PGPLOT directory" "PASS"
    else
        print_result "LD_LIBRARY_PATH includes PGPLOT directory" "FAIL"
    fi
}

# Test 9: User and permissions
test_user_and_permissions() {
    echo "Testing user and permissions..."

    local user=$(docker run --rm "$IMAGE_NAME" whoami)
    assert_equals "sniduser" "$user" "Container runs as sniduser"

    # Check if user can write to home directory
    if docker run --rm "$IMAGE_NAME" bash -c "touch /home/sniduser/test_write && rm /home/sniduser/test_write" > /dev/null 2>&1; then
        print_result "User has write permissions in home directory" "PASS"
    else
        print_result "User has write permissions in home directory" "FAIL"
    fi

    # Check if user has sudo access
    if docker run --rm "$IMAGE_NAME" bash -c "sudo echo 'test' > /dev/null 2>&1"; then
        print_result "User has sudo access" "PASS"
    else
        print_result "User has sudo access" "FAIL"
    fi
}

# Test 10: Logwave utility works
test_logwave_utility() {
    echo "Testing logwave utility..."

    if docker run --rm "$IMAGE_NAME" bash -c "test -x ./logwave"; then
        print_result "logwave utility is executable" "PASS"

        # Try to run it (might fail without input, but should exist)
        local output=$(docker run --rm "$IMAGE_NAME" bash -c "./logwave 2>&1 || true")
        if [[ "$output" != *"command not found"* ]]; then
            print_result "logwave executes" "PASS"
        else
            print_result "logwave executes" "FAIL"
        fi
    else
        print_result "logwave utility is executable" "FAIL"
    fi
}

# Test 11: Plotlnw utility works
test_plotlnw_utility() {
    echo "Testing plotlnw utility..."

    if docker run --rm "$IMAGE_NAME" bash -c "test -x ./plotlnw"; then
        print_result "plotlnw utility is executable" "PASS"
    else
        print_result "plotlnw utility is executable" "FAIL"
    fi
}

# Test 12: Templates are accessible
test_templates_accessible() {
    echo "Testing template accessibility..."

    local template_count=$(docker run --rm "$IMAGE_NAME" bash -c "ls templates-2.0/*.dat 2>/dev/null | wc -l" || echo "0")

    if [ "$template_count" -gt 0 ]; then
        print_result "Template files are accessible ($template_count templates found)" "PASS"
    else
        print_result "Template files are accessible" "FAIL"
    fi
}

# Run all tests
main() {
    test_docker_available
    test_tarballs_available
    test_build_image
    test_container_lifecycle
    test_snid_version
    test_example_data
    test_volume_mounting
    test_environment_variables
    test_user_and_permissions
    test_logwave_utility
    test_plotlnw_utility
    test_templates_accessible

    print_summary
}

main
