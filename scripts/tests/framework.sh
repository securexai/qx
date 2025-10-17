#!/bin/bash

# Test framework for QX installation script
# Provides unit testing capabilities for shell scripts

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Test results
declare -a FAILED_TESTS
declare -a SKIPPED_TESTS

# Test environment setup
setup_test_env() {
    # Create temporary test directory
    TEST_TMP_DIR=$(mktemp -d -t qx-test.XXXXXX)
    TEST_SCRIPT_DIR="$TEST_TMP_DIR/scripts"
    TEST_CONFIG_DIR="$TEST_TMP_DIR/config"
    TEST_CACHE_DIR="$TEST_TMP_DIR/cache"

    # Copy test files (minimal setup)
    mkdir -p "$TEST_SCRIPT_DIR" "$TEST_CONFIG_DIR" "$TEST_CACHE_DIR"

    # Set up minimal test configuration
    cat > "$TEST_CONFIG_DIR/default.yaml" << 'EOF'
global:
  log_level: "debug"
  log_file: ""
  cache_dir: "/tmp/qx-test-cache"
  temp_dir: "/tmp/qx-test-temp"
  parallel_downloads: 1
  download_timeout: 30
  retry_attempts: 1
  retry_delay: 1

platform:
  min_ubuntu_version: "24.04"
  architectures: ["x86_64"]
  required_system_packages: ["curl", "ca-certificates"]

security:
  verify_checksums: false
  require_https: true
  allow_insecure_downloads: false
  temp_file_permissions: "600"

ui:
  show_progress: false
  show_summary: false
  interactive_mode: false
  color_output: false

tools:
  bun:
    version: "1.2.23"
    install_path: "/usr/local"
EOF

    # Export test environment variables
    export TEST_MODE=true
    export SCRIPT_DIR="$TEST_SCRIPT_DIR"
    export CONFIG_DIR="$TEST_CONFIG_DIR"
    export CACHE_DIR="$TEST_CACHE_DIR"
}

# Clean up test environment
cleanup_test_env() {
    if [ -d "$TEST_TMP_DIR" ]; then
        rm -rf "$TEST_TMP_DIR"
    fi
}

# Test assertion functions
assert() {
    local condition="$1"
    local message="${2:-Assertion failed}"

    if ! eval "$condition"; then
        fail "$message"
    fi
}

assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected '$expected', got '$actual'}"

    if [ "$expected" != "$actual" ]; then
        fail "$message"
    fi
}

assert_not_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected not '$expected', but got '$actual'}"

    if [ "$expected" = "$actual" ]; then
        fail "$message"
    fi
}

assert_exists() {
    local file="$1"
    local message="${2:-File does not exist: $file}"

    if [ ! -e "$file" ]; then
        fail "$message"
    fi
}

assert_not_exists() {
    local file="$1"
    local message="${2:-File should not exist: $file}"

    if [ -e "$file" ]; then
        fail "$message"
    fi
}

assert_success() {
    local command="$1"
    local message="${2:-Command failed: $command}"

    if ! eval "$command"; then
        fail "$message"
    fi
}

assert_failure() {
    local command="$1"
    local message="${2:-Command should have failed: $command}"

    if eval "$command"; then
        fail "$message"
    fi
}

# Test runner functions
run_test() {
    local test_name="$1"
    local test_function="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    echo -n "Running test: $test_name... "

    # Set up test environment
    setup_test_env

    # Run test function
    if $test_function; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "✅ PASSED"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        echo "❌ FAILED"
    fi

    # Clean up
    cleanup_test_env
}

skip_test() {
    local test_name="$1"
    local reason="${2:-No reason given}"

    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    SKIPPED_TESTS+=("$test_name: $reason")

    echo "⏭️  SKIPPED: $test_name ($reason)"
}

fail() {
    local message="$1"
    echo "FAIL: $message" >&2
    return 1
}

# Test suite runner
run_test_suite() {
    local suite_name="$1"
    shift

    echo "========================================="
    echo "Running test suite: $suite_name"
    echo "========================================="

    # Reset counters
    TESTS_RUN=0
    TESTS_PASSED=0
    TESTS_FAILED=0
    TESTS_SKIPPED=0
    FAILED_TESTS=()
    SKIPPED_TESTS=()

    # Run all test functions passed as arguments
    for test_func in "$@"; do
        local test_name
        test_name=$(echo "$test_func" | sed 's/^test_//' | tr '_' ' ')
        run_test "$test_name" "$test_func"
    done

    # Print summary
    echo ""
    echo "========================================="
    echo "Test Results Summary"
    echo "========================================="
    echo "Total tests: $TESTS_RUN"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo "Skipped: $TESTS_SKIPPED"

    if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
        echo ""
        echo "Failed tests:"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  - $test"
        done
    fi

    if [ ${#SKIPPED_TESTS[@]} -gt 0 ]; then
        echo ""
        echo "Skipped tests:"
        for test in "${SKIPPED_TESTS[@]}"; do
            echo "  - $test"
        done
    fi

    # Return success only if no tests failed
    [ $TESTS_FAILED -eq 0 ]
}