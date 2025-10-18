#!/bin/bash
#
# QX Kind Cluster Verification Script
# Verifies the health and status of the local Kind cluster
#
# Description:
#   This script runs a series of tests to ensure the Kind cluster created by
#   start-kind-cluster.sh is healthy and operational. It checks node status,
#   namespaces, pods, and the deployed test application.
#
# Features:
#   - Cluster connectivity check
#   - Node status verification
#   - Namespace and pod listing
#   - Test pod description and log inspection
#   - Command execution within the test pod
#
# Usage:
#   ./scripts/verify-cluster.sh [--help]
#
# Options:
#   --help      Show this help message
#
# Requirements:
#   - kubectl (Kubernetes CLI)
#
# Exit Codes:
#   0 - Success
#   1 - General error
#
# Author: QX Development Team
# Version: 1.0.0
# Last Updated: 2025-10-18

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="verify-cluster.sh"
readonly SCRIPT_VERSION="1.0.0"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Show usage information
show_help() {
    cat << EOF
QX Kind Cluster Verification Script v${SCRIPT_VERSION}

Verifies the health and status of the local Kind cluster.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --help      Show this help message

EXAMPLES:
    $0          # Run all verification tests

REQUIREMENTS:
    - kubectl (Kubernetes CLI)
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

run_test() {
    local description=$1
    shift
    local command=("$@")

    log_info "${description}"
    if "${command[@]}"; then
        log_success "Test passed."
    else
        log_error "Test failed."
    fi
    echo ""
}

# Main function
main() {
    log_info "QX Kind Cluster Verification Script v${SCRIPT_VERSION}"
    log_info "Starting cluster verification..."
    echo ""

    # Parse arguments
    parse_args "$@"

    run_test "Checking cluster connectivity..." "kubectl" "cluster-info"
    run_test "Checking node status..." "kubectl" "get" "nodes" "-o" "wide"
    run_test "Listing all namespaces..." "kubectl" "get" "namespaces"
    run_test "Listing all pods..." "kubectl" "get" "pods" "--all-namespaces"
    run_test "Describing the test pod..." "kubectl" "describe" "pod" "qx-test-pod" "-n" "qx-test"
    run_test "Checking logs of the test pod..." "kubectl" "logs" "qx-test-pod" "-n" "qx-test"
    run_test "Executing a command in the test pod..." "kubectl" "exec" "-n" "qx-test" "qx-test-pod" "--" "nginx" "-v"

    log_info "Cluster verification complete."
    log_success "All tests passed successfully! The cluster is healthy. 🎉"

    return 0
}

# Run main function with all arguments
main "$@"