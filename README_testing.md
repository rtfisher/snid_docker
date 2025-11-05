# SNID-Docker Test Suite

This document provides comprehensive documentation for the SNID-Docker test suite. The tests validate Docker builds, script functionality, and end-to-end integration workflows.

## Test Files

### Test Utilities
- **`tests/test_utils.sh`** - Common testing functions and assertions
  - Provides color-coded output functions
  - Assertion helpers (`assert_equals`, `assert_success`, `assert_file_exists`, etc.)
  - Test result tracking and summary generation

### Test Suites

#### 1. Unit Tests (`tests/test_run_snid.sh`)
Tests the `run_snid.sh` script without actually running Docker.

**What it tests:**
- Script exists and is executable
- Proper shebang and bash syntax
- OS detection logic (macOS, Linux, Windows/WSL)
- X11 configuration code
- Docker command structure
- Cleanup and error handling
- Volume mounting support
- Environment variable handling

**Run independently:**
```bash
./tests/test_run_snid.sh
```

#### 2. Docker Build Tests (`tests/test_docker_build.sh`)
Validates that the Docker image builds correctly and contains all required components.

**What it tests:**
- Dockerfile existence and validity
- Docker daemon availability
- Required tarballs presence
- Successful image build
- PGPLOT installation and configuration
- SNID binary compilation
- Templates directory setup
- User permissions and working directory
- Additional utilities (logwave, plotlnw)
- Examples directory

**Prerequisites:**
- Docker must be installed and running
- `snid-5.0.tar.gz` and `templates-2.0.tgz` must be present in project root

**Run independently:**
```bash
./tests/test_docker_build.sh
```

#### 3. Integration Tests (`tests/test_integration.sh`)
End-to-end tests that verify the complete workflow.

**What it tests:**
- Container lifecycle (start, run, stop)
- SNID execution
- Example data processing
- Volume mounting functionality
- Environment variables in running container
- User permissions and sudo access
- Utility executables (logwave, plotlnw)
- Template file accessibility

**Prerequisites:**
- Docker must be installed and running
- `snid-5.0.tar.gz` and `templates-2.0.tgz` must be present in project root

**Run independently:**
```bash
./tests/test_integration.sh
```

### Test Runner

#### Master Test Runner (`tests/run_all_tests.sh`)
Executes all test suites in sequence and provides a comprehensive summary.

**Usage:**
```bash
# Run all tests
./tests/run_all_tests.sh

# Run only quick tests (skip integration)
./tests/run_all_tests.sh --quick

# Show verbose output
./tests/run_all_tests.sh --verbose

# Show help
./tests/run_all_tests.sh --help
```

## Test Output Format

Tests use color-coded output for easy reading:

- 🟢 **Green** (`✓ PASS`) - Test passed successfully
- 🔴 **Red** (`✗ FAIL`) - Test failed
- 🟡 **Yellow** (`⊘ SKIP`) - Test was skipped (with reason)

Each test suite provides a summary:
```
========================================
Test Summary
========================================
Total tests run: 23
Passed: 23
Failed: 0

All tests passed!
```

## Writing New Tests

### Using Test Utilities

All test scripts should source `test_utils.sh` for common functionality:

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_utils.sh"

print_test_header "My New Test Suite"

# Your test functions here

# Example test
test_something() {
    assert_equals "expected" "actual" "Test description"
}

# Run tests
main() {
    test_something
    print_summary
}

main
```

### Available Assertion Functions

- `assert_equals expected actual "test name"` - Assert two values are equal
- `assert_success "test name" command` - Assert command succeeds
- `assert_fails "test name" command` - Assert command fails
- `assert_file_exists file "test name"` - Assert file exists
- `assert_dir_exists dir "test name"` - Assert directory exists
- `assert_contains haystack needle "test name"` - Assert string contains substring
- `assert_not_empty value "test name"` - Assert value is not empty
- `print_result "test name" "PASS|FAIL"` - Manually print test result
- `skip_test "reason"` - Skip a test with explanation

### Test Best Practices

1. **Cleanup**: Always include cleanup functions and use `trap cleanup EXIT`
2. **Prerequisites**: Check for required tools/files and skip gracefully if missing
3. **Independence**: Tests should be independent and not rely on execution order
4. **Descriptive Names**: Use clear, descriptive test names
5. **Error Messages**: Provide helpful error messages for debugging
6. **Skip When Appropriate**: Skip tests when prerequisites aren't met rather than failing

## CI/CD Integration

These tests are automatically run by GitHub Actions on:
- Pushes to main branches (master, main, develop)
- Pull requests
- Manual workflow triggers

The CI workflow is defined in `.github/workflows/ci.yml`.

### CI Pipeline Stages

1. **Quick Tests** - Fast validation without Docker builds
   - File existence checks
   - Script syntax validation
   - Unit tests for run_snid.sh

2. **Docker Build Tests** - Full image build verification
   - Docker image build
   - PGPLOT installation
   - SNID compilation

3. **Integration Tests** - End-to-end workflow testing
   - Container lifecycle
   - Volume mounting
   - SNID execution

4. **Multi-Platform** - Compatibility checks across OS platforms
   - Linux (ubuntu-latest)
   - macOS (macos-latest)

5. **Test Report** - Consolidated results summary
   - Job status overview
   - Links to detailed logs

### Viewing CI Results

1. Go to the **Actions** tab in your GitHub repository
2. Click on the latest workflow run
3. View individual job results
4. Check the test summary at the bottom of each job

## Troubleshooting

### Tests Skip Due to Missing Tarballs

**Problem:** Tests show "Missing tarballs - skipping" messages

**Solution:** Download the required files:
- `snid-5.0.tar.gz`
- `templates-2.0.tgz`

From: https://people.lam.fr/blondin.stephane/software/snid/

Place them in the project root directory.

### Docker Tests Fail

**Problem:** "Docker daemon is not running" or similar errors

**Solution:**
- Ensure Docker Desktop is installed and running
- On macOS: Open Docker Desktop application
- On Linux: `sudo systemctl start docker`
- Verify with: `docker ps`

### Permission Denied Errors

**Problem:** Cannot execute test scripts

**Solution:**
```bash
chmod +x tests/*.sh
```

### Tests Fail on macOS

**Problem:** X11-related tests fail on macOS

**Solution:**
- Install XQuartz: https://www.xquartz.org
- Restart your computer after installation
- The unit tests should still pass; integration tests may skip X11 features

### CI Workflow Not Triggering

**Problem:** Push to repository but workflow doesn't run

**Solution:**
- Check that `.github/workflows/ci.yml` exists
- Verify you're pushing to master, main, or develop branch
- Check Actions tab is enabled in repository settings
- Review workflow file for syntax errors

## Contributing Tests

When adding new features to SNID-Docker:

1. Add corresponding tests to the appropriate test suite
2. If creating a new test suite, follow the existing structure
3. Ensure all tests pass locally before committing
4. Update this README if adding new test files
5. Verify CI pipeline passes on GitHub

## Test Coverage

Current test coverage includes:

### Covered ✅
- Script syntax validation
- OS detection (macOS, Linux, WSL)
- Docker build process
- PGPLOT installation
- SNID compilation
- Container lifecycle
- Volume mounting
- Environment variables
- User permissions
- Utility tools (logwave, plotlnw)
- Template accessibility
- Multi-platform compatibility

### Future Improvements 🔲
- X11 forwarding testing (requires X11 server in CI)
- Actual SNID spectrum analysis (requires test spectra)
- Performance benchmarking
- Memory usage validation
- Network isolation tests
- Security scanning

## Test Maintenance

### Updating Tests

When updating the codebase:

1. **Update run_snid.sh**: Add tests to `tests/test_run_snid.sh`
2. **Update Dockerfile**: Add tests to `tests/test_docker_build.sh`
3. **New features**: Add integration tests to `tests/test_integration.sh`

### Test Cleanup

Tests automatically clean up after themselves:
- Docker images are removed after build tests
- Containers are stopped and removed after integration tests
- Temporary files are deleted on exit

### Performance Considerations

- Unit tests run in seconds
- Docker build tests take 5-10 minutes (building PGPLOT and SNID)
- Integration tests take 2-3 minutes
- Total test suite: ~15-20 minutes

Use `--quick` flag for rapid feedback during development.

## Examples

### Running Tests During Development

```bash
# Quick syntax check
./tests/test_run_snid.sh

# Full local validation (when you have tarballs)
./tests/run_all_tests.sh

# Quick check without building Docker
./tests/run_all_tests.sh --quick
```

### Debugging Failed Tests

```bash
# Run with verbose output
./tests/run_all_tests.sh --verbose

# Run specific test suite
./tests/test_docker_build.sh

# Check Docker manually
docker build -t snid-app-test -f snid_dockerfile .
docker run --rm snid-app-test ./snid --help
```

### Adding a New Test

Example of adding a test to `test_run_snid.sh`:

```bash
# Test for new feature
test_new_feature() {
    if grep -q "new_feature_code" "$RUN_SNID_SCRIPT"; then
        print_result "Script contains new feature code" "PASS"
    else
        print_result "Script contains new feature code" "FAIL"
    fi
}

# Add to main() function
main() {
    # ... existing tests ...
    test_new_feature
    print_summary
}
```

## Support

For issues with tests:
1. Check this documentation
2. Review test output for specific error messages
3. Check GitHub Actions logs for CI failures
4. Open an issue on GitHub with test output

For issues with SNID itself, refer to:
- https://people.lam.fr/blondin.stephane/software/snid/
- The main README.md file
