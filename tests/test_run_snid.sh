#!/bin/bash

# run_snid.sh Unit Tests
# Tests the functionality of the run_snid.sh script without actually running Docker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_utils.sh"

# Test configuration
RUN_SNID_SCRIPT="$SCRIPT_DIR/../run_snid.sh"

print_test_header "run_snid.sh Unit Tests"

# Test 1: Script exists and is executable
test_script_exists() {
    assert_file_exists "$RUN_SNID_SCRIPT" "run_snid.sh exists"
}

test_script_executable() {
    if [ -x "$RUN_SNID_SCRIPT" ]; then
        print_result "run_snid.sh is executable" "PASS"
    else
        print_result "run_snid.sh is executable" "FAIL"
    fi
}

# Test 2: Script has proper shebang
test_shebang() {
    local first_line=$(head -n 1 "$RUN_SNID_SCRIPT")

    if [[ "$first_line" == "#!/bin/bash"* ]]; then
        print_result "Script has correct shebang" "PASS"
    else
        print_result "Script has correct shebang (found: '$first_line')" "FAIL"
    fi
}

# Test 3: Script contains OS detection logic
test_os_detection_code() {
    if grep -q "uname" "$RUN_SNID_SCRIPT" && grep -q "PLATFORM" "$RUN_SNID_SCRIPT"; then
        print_result "Script contains OS detection code" "PASS"
    else
        print_result "Script contains OS detection code" "FAIL"
    fi
}

# Test 4: Script contains cleanup function
test_cleanup_function() {
    if grep -q "cleanup()" "$RUN_SNID_SCRIPT" && grep -q "trap cleanup" "$RUN_SNID_SCRIPT"; then
        print_result "Script contains cleanup function and trap" "PASS"
    else
        print_result "Script contains cleanup function and trap" "FAIL"
    fi
}

# Test 5: Script contains Docker commands
test_docker_commands() {
    if grep -q "docker build" "$RUN_SNID_SCRIPT" && grep -q "docker run" "$RUN_SNID_SCRIPT"; then
        print_result "Script contains Docker build and run commands" "PASS"
    else
        print_result "Script contains Docker build and run commands" "FAIL"
    fi
}

# Test 6: Script contains X11 configuration
test_x11_config() {
    if grep -q "xhost" "$RUN_SNID_SCRIPT"; then
        print_result "Script contains X11 configuration (xhost)" "PASS"
    else
        print_result "Script contains X11 configuration (xhost)" "FAIL"
    fi
}

# Test 7: Script handles macOS platform
test_macos_handling() {
    if grep -q "macOS" "$RUN_SNID_SCRIPT" || grep -q "Darwin" "$RUN_SNID_SCRIPT"; then
        print_result "Script handles macOS platform" "PASS"
    else
        print_result "Script handles macOS platform" "FAIL"
    fi
}

# Test 8: Script handles Linux platform
test_linux_handling() {
    if grep -q "Linux" "$RUN_SNID_SCRIPT"; then
        print_result "Script handles Linux platform" "PASS"
    else
        print_result "Script handles Linux platform" "FAIL"
    fi
}

# Test 9: Script handles Windows/WSL platform
test_windows_handling() {
    if grep -q "Windows" "$RUN_SNID_SCRIPT" || grep -q "microsoft" "$RUN_SNID_SCRIPT"; then
        print_result "Script handles Windows/WSL platform" "PASS"
    else
        print_result "Script handles Windows/WSL platform" "FAIL"
    fi
}

# Test 10: Script references XQuartz
test_xquartz_reference() {
    if grep -q -i "xquartz" "$RUN_SNID_SCRIPT"; then
        print_result "Script references XQuartz for macOS" "PASS"
    else
        print_result "Script references XQuartz for macOS" "FAIL"
    fi
}

# Test 11: Script checks for X11 servers on Windows
test_windows_x11_servers() {
    local x11_servers=("VcXsrv" "Xming" "Cygwin")
    local found=0

    for server in "${x11_servers[@]}"; do
        if grep -q "$server" "$RUN_SNID_SCRIPT"; then
            ((found++))
        fi
    done

    if [ $found -ge 2 ]; then
        print_result "Script checks for multiple Windows X11 servers" "PASS"
    else
        print_result "Script checks for multiple Windows X11 servers (found: $found)" "FAIL"
    fi
}

# Test 12: Script has volume mounting support
test_volume_mounting() {
    if grep -q "\-v" "$RUN_SNID_SCRIPT" && grep -q "localmount" "$RUN_SNID_SCRIPT"; then
        print_result "Script supports volume mounting" "PASS"
    else
        print_result "Script supports volume mounting" "FAIL"
    fi
}

# Test 13: Script references correct image name
test_image_name() {
    if grep -q "snid-app" "$RUN_SNID_SCRIPT"; then
        print_result "Script uses correct image name (snid-app)" "PASS"
    else
        print_result "Script uses correct image name" "FAIL"
    fi
}

# Test 14: Script references correct container name
test_container_name() {
    if grep -q "snid-container" "$RUN_SNID_SCRIPT"; then
        print_result "Script uses correct container name (snid-container)" "PASS"
    else
        print_result "Script uses correct container name" "FAIL"
    fi
}

# Test 15: Script sets DISPLAY environment variable
test_display_variable() {
    if grep -q "DISPLAY" "$RUN_SNID_SCRIPT"; then
        print_result "Script sets DISPLAY environment variable" "PASS"
    else
        print_result "Script sets DISPLAY environment variable" "FAIL"
    fi
}

# Test 16: Script has X11 socket mounting
test_x11_socket() {
    if grep -q ".X11-unix" "$RUN_SNID_SCRIPT"; then
        print_result "Script mounts X11 socket" "PASS"
    else
        print_result "Script mounts X11 socket" "FAIL"
    fi
}

# Test 17: Script waits for Docker to start
test_docker_wait() {
    if grep -q "docker system info" "$RUN_SNID_SCRIPT" || grep -q "Waiting for Docker" "$RUN_SNID_SCRIPT"; then
        print_result "Script waits for Docker to start" "PASS"
    else
        print_result "Script waits for Docker to start" "FAIL"
    fi
}

# Test 18: Script uses dockerfile parameter
test_dockerfile_param() {
    if grep -q "\-f.*snid_dockerfile" "$RUN_SNID_SCRIPT"; then
        print_result "Script specifies Dockerfile with -f parameter" "PASS"
    else
        print_result "Script specifies Dockerfile with -f parameter" "FAIL"
    fi
}

# Test 19: Script uses --rm flag for cleanup
test_rm_flag() {
    if grep -q "\-\-rm" "$RUN_SNID_SCRIPT"; then
        print_result "Script uses --rm flag for automatic cleanup" "PASS"
    else
        print_result "Script uses --rm flag for automatic cleanup" "FAIL"
    fi
}

# Test 20: Script uses interactive mode
test_interactive_mode() {
    if grep -q "\-it" "$RUN_SNID_SCRIPT" || grep -q "\-i.*\-t" "$RUN_SNID_SCRIPT"; then
        print_result "Script uses interactive mode (-it)" "PASS"
    else
        print_result "Script uses interactive mode" "FAIL"
    fi
}

# Test 21: Script syntax is valid
test_script_syntax() {
    if bash -n "$RUN_SNID_SCRIPT" 2>/dev/null; then
        print_result "Script has valid bash syntax" "PASS"
    else
        print_result "Script has valid bash syntax" "FAIL"
    fi
}

# Test 22: Script handles desktop mounting
test_desktop_mounting() {
    if grep -q "Desktop/snid" "$RUN_SNID_SCRIPT" && grep -q "desktop" "$RUN_SNID_SCRIPT"; then
        print_result "Script mounts desktop directory" "PASS"
    else
        print_result "Script mounts desktop directory" "FAIL"
    fi
}

# Run all tests
main() {
    test_script_exists
    test_script_executable
    test_shebang
    test_os_detection_code
    test_cleanup_function
    test_docker_commands
    test_x11_config
    test_macos_handling
    test_linux_handling
    test_windows_handling
    test_xquartz_reference
    test_windows_x11_servers
    test_volume_mounting
    test_image_name
    test_container_name
    test_display_variable
    test_x11_socket
    test_docker_wait
    test_dockerfile_param
    test_rm_flag
    test_interactive_mode
    test_script_syntax
    test_desktop_mounting

    print_summary
}

main
