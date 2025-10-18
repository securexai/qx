#!/bin/bash
#
# QX Kind Cluster Stop Script
# Stops and cleans up the local Kubernetes cluster
#
# Description:
#   This script safely stops the QX development Kind cluster, removes
#   all associated resources, and cleans up the local environment.
#
# Features:
#   - Graceful cluster shutdown
#   - Resource cleanup verification
#   - kubectl context reset
#   - Podman container cleanup
#   - Comprehensive error handling
#
# Usage:
#   ./scripts/stop-kind-cluster.sh [--force] [--verbose]
#
# Options:
#   --force     Force cleanup even if errors occur
#   --verbose   Enable verbose output
#   --help      Show this help message
#
# Requirements:
#   - kind (Kubernetes in Docker)
#   - kubectl (Kubernetes CLI)
#   - podman (Container runtime)
#
# Exit Codes:
#   0 - Success
#   1 - General error
#   2 - Prerequisites not met
#   3 - Cluster deletion failed
#
# Author: QX Development Team
# Version: 1.0.0
# Last Updated: 2025-10-18

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="stop-kind-cluster.sh"
readonly SCRIPT_VERSION="1.0.0"
readonly CLUSTER_NAME="qx-dev-cluster"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Default settings
VERBOSE=false
FORCE=false

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

# Show usage information
show_help() {
    cat << EOF
QX Kind Cluster Stop Script v${SCRIPT_VERSION}

Stops and cleans up the local QX development Kind cluster.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --force     Force cleanup even if errors occur
    --verbose   Enable verbose output
    --help      Show this help message

EXAMPLES:
    $0                          # Stop cluster gracefully
    $0 --verbose               # Stop with verbose output
    $0 --force                 # Force cleanup on errors

REQUIREMENTS:
    - kind (Kubernetes in Docker)
    - kubectl (Kubernetes CLI)
    - podman (Container runtime)

For more information, see docs/plan.md
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                FORCE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
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

# Check if prerequisites are installed
check_prerequisites() {
    local missing_tools=()

    log_info "Checking prerequisites..."

    # Check for required tools
    if ! command -v kind &> /dev/null; then
        missing_tools+=("kind")
    fi

    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi

    if ! command -v podman &> /dev/null; then
        missing_tools+=("podman")
    fi

    # Report missing tools
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_error "Cannot stop cluster without required tools"
        return 2
    fi

    log_success "All prerequisites satisfied"
    return 0
}

# Check if cluster exists
check_cluster_exists() {
    if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        log_warn "Cluster '${CLUSTER_NAME}' does not exist or is already stopped"
        return 1
    fi
    return 0
}

# Reset kubectl context
reset_kubectl_context() {
    log_info "Resetting kubectl context..."

    # Try to switch away from the kind context
    if kubectl config get-contexts | grep -q "kind-${CLUSTER_NAME}"; then
        # Find a suitable alternative context
        local alt_context
        alt_context=$(kubectl config get-contexts --no-headers | grep -v "kind-${CLUSTER_NAME}" | head -1 | awk '{print $1}' || echo "")

        if [[ -n "$alt_context" ]]; then
            log_info "Switching to context: $alt_context"
            kubectl config use-context "$alt_context" 2>/dev/null || true
        else
            log_warn "No alternative kubectl context found"
        fi
    else
        log_info "No kind context found to reset"
    fi
}

# Stop and delete the cluster
stop_cluster() {
    log_info "Stopping Kind cluster '${CLUSTER_NAME}'..."

    local kind_cmd="kind delete cluster --name ${CLUSTER_NAME}"

    if [[ "$VERBOSE" == "true" ]]; then
        kind_cmd="${kind_cmd} --verbosity 4"
    fi

    if $kind_cmd; then
        log_success "Cluster '${CLUSTER_NAME}' stopped and deleted"
        return 0
    else
        log_error "Failed to delete cluster '${CLUSTER_NAME}'"
        if [[ "$FORCE" == "true" ]]; then
            log_warn "Continuing with force cleanup despite cluster deletion failure"
            return 0
        fi
        return 3
    fi
}

# Clean up Podman containers and images
cleanup_podman() {
    log_info "Cleaning up Podman resources..."

    # Stop and remove any dangling containers
    local dangling_containers
    dangling_containers=$(podman ps -a --filter "label=io.x-k8s.kind.cluster=${CLUSTER_NAME}" --format "{{.ID}}" 2>/dev/null || true)

    if [[ -n "$dangling_containers" ]]; then
        log_info "Removing dangling containers..."
        echo "$dangling_containers" | xargs podman rm -f 2>/dev/null || true
        log_success "Dangling containers cleaned up"
    else
        log_info "No dangling containers found"
    fi

    # Clean up unused images (optional, only if force is enabled)
    if [[ "$FORCE" == "true" ]]; then
        log_info "Cleaning up unused images..."
        podman image prune -f >/dev/null 2>&1 || true
        log_success "Unused images cleaned up"
    fi
}

# Verify cluster is stopped
verify_cleanup() {
    log_info "Verifying cluster cleanup..."

    # Check if cluster still exists
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        log_error "Cluster '${CLUSTER_NAME}' still exists!"
        return 3
    else
        log_success "Cluster '${CLUSTER_NAME}' successfully removed"
    fi

    # Check for remaining containers
    local remaining_containers
    remaining_containers=$(podman ps -a --filter "label=io.x-k8s.kind.cluster=${CLUSTER_NAME}" --format "{{.ID}}" 2>/dev/null | wc -l || echo "0")

    if [[ "$remaining_containers" -gt 0 ]]; then
        if [[ "$FORCE" == "true" ]]; then
            log_warn "$remaining_containers containers still exist, but continuing due to --force"
        else
            log_error "$remaining_containers containers still exist"
            return 3
        fi
    else
        log_success "No remaining cluster containers"
    fi
}

# Show cleanup summary
show_cleanup_summary() {
    log_info "Cleanup Summary:"
    echo "  ✅ Cluster '${CLUSTER_NAME}' stopped and deleted"
    echo "  ✅ kubectl context reset"
    echo "  ✅ Podman resources cleaned up"
    echo "  ✅ Local environment restored"
    echo ""
    echo "To restart the cluster:"
    echo "  ./scripts/start-kind-cluster.sh"
}

# Main function
main() {
    log_info "QX Kind Cluster Stop Script v${SCRIPT_VERSION}"
    log_info "Stopping cluster '${CLUSTER_NAME}'..."

    # Parse arguments
    parse_args "$@"

    # Check prerequisites
    check_prerequisites || return $?

    # Check if cluster exists
    if ! check_cluster_exists; then
        log_success "Cluster cleanup complete (cluster was already stopped)"
        return 0
    fi

    # Reset kubectl context first
    reset_kubectl_context

    # Stop the cluster
    stop_cluster || return $?

    # Clean up Podman resources
    cleanup_podman

    # Verify cleanup
    verify_cleanup || return $?

    # Show summary
    show_cleanup_summary

    log_success "Cluster '${CLUSTER_NAME}' cleanup complete! 🧹"
    log_info "Ready for next development session"

    return 0
}

# Run main function with all arguments
main "$@"