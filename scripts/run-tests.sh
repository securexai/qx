#!/bin/bash

# Test runner script for QX installation script
# Runs unit and integration tests in Podman containers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if Podman is available
check_podman() {
    if ! command -v podman >/dev/null 2>&1; then
        log_error "Podman is not installed. Please install Podman first."
        exit 1
    fi
}

# Run unit tests in container
run_unit_tests() {
    log_info "Running unit tests in Podman container..."

    local container_name="qx-test-unit-$(date +%s)"

    # Run unit tests
    if podman run --rm --name "$container_name" \
        -v "$REPO_DIR:/workspace:ro" \
        -w /workspace \
        --tmpfs /tmp:rw,noexec,nosuid,size=100m \
        docker.io/library/ubuntu:24.04 \
        bash -c "
            set -e
            export DEBIAN_FRONTEND=noninteractive

            # Install dependencies
            apt-get update -qq
            apt-get install -y -qq curl ca-certificates

            # Run unit tests
            cd scripts
            bash tests/framework.sh run_test_suite 'Unit Tests' \
                test_command_exists \
                test_executable_exists \
                test_ensure_dir \
                test_get_absolute_path \
                test_array_contains \
                test_validate_version \
                test_version_compare \
                test_url_encode \
                test_generate_random_string \
                test_is_dry_run \
                test_is_force_mode
        "; then
        log_success "Unit tests passed"
        return 0
    else
        log_error "Unit tests failed"
        return 1
    fi
}

# Run integration tests in container
run_integration_tests() {
    log_info "Running integration tests in Podman container..."

    local container_name="qx-test-integration-$(date +%s)"

    # Run integration tests
    if podman run --rm --name "$container_name" \
        -v "$REPO_DIR:/workspace:ro" \
        -w /workspace/scripts \
        --tmpfs /tmp:rw,noexec,nosuid,size=100m \
        docker.io/library/ubuntu:24.04 \
        bash -c "
            set -ex
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq
            apt-get install -y -qq curl ca-certificates unzip bc

            source tests/framework.sh
            source tests/integration/test_error_handling.sh
            source tests/integration/test_rollback.sh
            run_test_suite 'Integration Tests' \
                test_err_trap_in_subshell \
                test_automatic_rollback_on_failure
        "; then
        log_success "Integration tests passed"
        return 0
    else
        log_error "Integration tests failed"
        return 1
    fi
}

# Run all tests
run_all_tests() {
    local unit_result=0
    local integration_result=0

    log_info "Starting QX installation script test suite..."
    log_info "Repository: $REPO_DIR"
    log_info "Using Ubuntu 24.04 container for testing"

    # Run unit tests
    if run_unit_tests; then
        unit_result=0
    else
        unit_result=1
    fi

    # Run integration tests
    if run_integration_tests; then
        integration_result=0
    else
        integration_result=1
    fi

    # Summary
    echo
    log_info "Test Results Summary:"
    echo "======================"

    if [ $unit_result -eq 0 ]; then
        log_success "✓ Unit tests: PASSED"
    else
        log_error "✗ Unit tests: FAILED"
    fi

    if [ $integration_result -eq 0 ]; then
        log_success "✓ Integration tests: PASSED"
    else
        log_error "✗ Integration tests: FAILED"
    fi

    if [ $unit_result -eq 0 ] && [ $integration_result -eq 0 ]; then
        log_success "🎉 All tests passed!"
        return 0
    else
        log_error "❌ Some tests failed"
        return 1
    fi
}

# Show usage
show_usage() {
    cat << EOF
QX Installation Script Test Runner

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -u, --unit         Run only unit tests
    -i, --integration  Run only integration tests
    -a, --all          Run all tests (default)
    -h, --help         Show this help message

DESCRIPTION:
    This script runs the test suite for the QX installation script using
    Podman containers. Tests are executed in disposable Ubuntu 24.04
    containers to ensure clean, isolated test environments.

    - Unit tests: Test individual functions and utilities
    - Integration tests: Test complete script workflows in dry-run mode

EXAMPLES:
    $0                    # Run all tests
    $0 --unit            # Run only unit tests
    $0 --integration     # Run only integration tests

REQUIREMENTS:
    - Podman installed and running
    - Internet connection for container downloads

EOF
}

# Main execution
main() {
    local test_type="all"

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -u|--unit)
                test_type="unit"
                shift
                ;;
            -i|--integration)
                test_type="integration"
                shift
                ;;
            -a|--all)
                test_type="all"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Check prerequisites
    check_podman

    # Run tests based on type
    case "$test_type" in
        unit)
            run_unit_tests
            ;;
        integration)
            run_integration_tests
            ;;
        all)
            run_all_tests
            ;;
    esac
}

# Run main function
main "$@"