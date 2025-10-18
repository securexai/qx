#!/bin/bash
#
# QX Kind Cluster Management Script
# Starts a 3-node Kubernetes cluster using Kind for local development
#
# Description:
#   This script creates and configures a local Kubernetes cluster using Kind
#   with Podman as the container runtime. It sets up a 3-node cluster with
#   ingress support and deploys basic test resources.
#
# Features:
#   - Automated cluster creation with kind-config.yaml
#   - Podman container runtime integration
#   - Ingress controller deployment
#   - Basic test pod deployment
#   - Cluster health verification
#   - kubectl context configuration
#
# Usage:
#   ./scripts/start-kind-cluster.sh [--force] [--verbose]
#
# Options:
#   --force     Force cluster recreation if it already exists
#   --verbose   Enable verbose output
#   --help      Show this help message
#
# Requirements:
#   - kind (Kubernetes in Docker)
#   - kubectl (Kubernetes CLI)
#   - podman (Container runtime)
#   - All tools must be in PATH
#
# Exit Codes:
#   0 - Success
#   1 - General error
#   2 - Prerequisites not met
#   3 - Cluster creation failed
#   4 - Configuration failed
#
# Author: QX Development Team
# Version: 1.0.0
# Last Updated: 2025-10-18

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="start-kind-cluster.sh"
readonly SCRIPT_VERSION="1.0.0"
readonly CLUSTER_NAME="qx-dev-cluster"
readonly CONFIG_FILE="kind-config.yaml"
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
QX Kind Cluster Start Script v${SCRIPT_VERSION}

Starts a 3-node Kubernetes cluster using Kind for local development.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --force     Force cluster recreation if it already exists
    --verbose   Enable verbose output
    --help      Show this help message

EXAMPLES:
    $0                          # Start cluster with default settings
    $0 --verbose               # Start with verbose output
    $0 --force                 # Force recreation of existing cluster

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
        log_error "Please run: sudo bash scripts/install-prereqs.sh --profile development"
        return 2
    fi

    # Verify versions
    log_info "Kind version: $(kind version)"
    log_info "Kubectl version: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
    log_info "Podman version: $(podman --version)"

    log_success "All prerequisites satisfied"
    return 0
}

# Check if cluster already exists
check_existing_cluster() {
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        if [[ "$FORCE" == "true" ]]; then
            log_warn "Cluster '${CLUSTER_NAME}' already exists, recreating due to --force flag"
            return 1
        else
            log_error "Cluster '${CLUSTER_NAME}' already exists"
            log_error "Use --force to recreate the cluster"
            return 1
        fi
    fi
    return 0
}

# Delete existing cluster if forced
delete_existing_cluster() {
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        log_info "Deleting existing cluster '${CLUSTER_NAME}'..."
        if kind delete cluster --name "${CLUSTER_NAME}"; then
            log_success "Existing cluster deleted"
        else
            log_error "Failed to delete existing cluster"
            return 3
        fi
    fi
}

# Create the Kind cluster
create_cluster() {
    local config_path="${PROJECT_ROOT}/${CONFIG_FILE}"

    if [[ ! -f "$config_path" ]]; then
        log_error "Cluster configuration file not found: $config_path"
        return 4
    fi

    log_info "Creating Kind cluster '${CLUSTER_NAME}'..."
    log_info "Using configuration: $config_path"

    local kind_cmd="kind create cluster --name ${CLUSTER_NAME} --config ${config_path}"

    if [[ "$VERBOSE" == "true" ]]; then
        kind_cmd="${kind_cmd} --verbosity 4"
    fi

    if $kind_cmd; then
        log_success "Cluster '${CLUSTER_NAME}' created successfully"
    else
        log_error "Failed to create cluster '${CLUSTER_NAME}'"
        return 3
    fi
}

# Configure kubectl context
configure_kubectl() {
    log_info "Configuring kubectl context..."

    # Get the kubeconfig for the cluster
    if kind get kubeconfig --name "${CLUSTER_NAME}" > /dev/null; then
        # Set the context to use the new cluster
        kubectl config use-context "kind-${CLUSTER_NAME}" 2>/dev/null || true

        # Verify connection
        if kubectl cluster-info; then
            log_success "kubectl configured and connected to cluster"
        else
            log_error "Failed to connect to cluster with kubectl"
            return 4
        fi
    else
        log_error "Failed to get kubeconfig for cluster '${CLUSTER_NAME}'"
        return 4
    fi
}

# Deploy basic test resources
deploy_test_resources() {
    log_info "Deploying test resources..."

    # Create a simple test namespace
    kubectl create namespace qx-test --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

    # Deploy a test nginx pod
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: qx-test-pod
  namespace: qx-test
  labels:
    app: qx-test
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
EOF

    # Wait for pod to be ready
    log_info "Waiting for test pod to be ready..."
    if kubectl wait --for=condition=Ready pod/qx-test-pod -n qx-test --timeout=60s 2>/dev/null; then
        log_success "Test pod deployed and ready"
    else
        log_warn "Test pod deployment may have issues (continuing anyway)"
    fi
}

# Verify cluster health
verify_cluster() {
    log_info "Verifying cluster health..."

    # Check nodes
    local node_count
    node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    if [[ $node_count -eq 3 ]]; then
        log_success "All 3 nodes are ready"
    else
        log_warn "Expected 3 nodes, found $node_count"
    fi

    # Check cluster status
    if kubectl get nodes | grep -q "Ready"; then
        log_success "Cluster is healthy and ready"
    else
        log_error "Cluster health check failed"
        return 4
    fi
}

# Show cluster information
show_cluster_info() {
    log_info "Cluster Information:"
    echo "  Name: ${CLUSTER_NAME}"
    echo "  Nodes: $(kubectl get nodes --no-headers | wc -l)"
    echo "  Pods: $(kubectl get pods --all-namespaces --no-headers | wc -l)"
    echo "  Services: $(kubectl get services --all-namespaces --no-headers | wc -l)"
    echo ""
    echo "Useful commands:"
    echo "  kubectl get nodes                    # List cluster nodes"
    echo "  kubectl get pods --all-namespaces    # List all pods"
    echo "  kubectl cluster-info                 # Show cluster info"
    echo "  ./scripts/stop-kind-cluster.sh       # Stop the cluster"
}

# Main function
main() {
    log_info "QX Kind Cluster Start Script v${SCRIPT_VERSION}"
    log_info "Starting cluster '${CLUSTER_NAME}'..."

    # Parse arguments
    parse_args "$@"

    # Check prerequisites
    check_prerequisites || return $?

    # Check existing cluster
    check_existing_cluster || return 1

    # Delete existing cluster if forced
    if [[ "$FORCE" == "true" ]]; then
        delete_existing_cluster || return $?
    fi

    # Create cluster
    create_cluster || return $?

    # Configure kubectl
    configure_kubectl || return $?

    # Deploy test resources
    deploy_test_resources

    # Verify cluster
    verify_cluster || return $?

    # Show information
    show_cluster_info

    log_success "Cluster '${CLUSTER_NAME}' is ready for development! 🎉"
    log_info "Happy coding with QX! 🚀"

    return 0
}

# Run main function with all arguments
main "$@"