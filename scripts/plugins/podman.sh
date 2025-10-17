#!/bin/bash

# Podman Container Runtime Plugin for QX Installation Script
# Implements the standardized plugin interface

# Plugin information
podman_plugin_name() { echo "podman"; }
podman_plugin_version() {
    if command -v podman >/dev/null 2>&1; then
        podman --version 2>/dev/null | awk '{print $3}' || echo "unknown"
    else
        echo "not installed"
    fi
}
podman_plugin_info() {
    cat << EOF
Name: Podman Container Runtime
Description: Daemonless container engine for developing, managing, and running OCI Containers
Website: https://podman.io
Installation Method: Ubuntu package manager (apt)
Default Version: $(get_config_value "tools.podman.version" "4.9.4")
Package: $(get_config_value "tools.podman.package_name" "podman")
EOF
}

# Detection - check if podman is installed
podman_plugin_detect() {
    if command -v podman >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Dependencies - none required (handled by apt)
podman_plugin_dependencies() {
    echo ""
}

# Installation - use apt package manager
podman_plugin_install() {
    local package_name="${1:-$(get_config_value "tools.podman.package_name" "podman")}"

    log_info "Installing Podman via apt package: $package_name"

    # Check if running as root (required for apt)
    if [ "$EUID" -ne 0 ]; then
        log_error "Podman installation requires root privileges for apt package management"
        return 1
    fi

    # Update package list
    log_debug "Updating package list..."
    if ! apt-get update -qq; then
        log_error "Failed to update package list"
        return 1
    fi

    # Install podman
    log_info "Installing $package_name..."
    if DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$package_name"; then
        log_success "Podman package installed successfully"
        return 0
    else
        log_error "Failed to install Podman package: $package_name"
        return 1
    fi
}

# Verification - check that podman is working
podman_plugin_verify() {
    if command -v podman >/dev/null 2>&1; then
        # Try to get version to verify it's working
        if podman --version >/dev/null 2>&1; then
            local version
            version=$(podman --version 2>/dev/null | awk '{print $3}' || echo "unknown")
            log_success "✅ Podman verified (version: $version)"
            return 0
        else
            log_error "❌ Podman command exists but is not working"
            return 1
        fi
    else
        log_error "❌ Podman command not found"
        return 1
    fi
}

# Uninstallation - remove podman package
podman_plugin_uninstall() {
    local package_name="${1:-$(get_config_value "tools.podman.package_name" "podman")}"

    log_warn "Uninstalling Podman package: $package_name"

    # Check if running as root (required for apt)
    if [ "$EUID" -ne 0 ]; then
        log_error "Podman uninstallation requires root privileges"
        return 1
    fi

    # Remove podman package
    if apt-get remove -y -qq "$package_name"; then
        # Also remove any automatically installed dependencies that are no longer needed
        apt-get autoremove -y -qq >/dev/null 2>&1 || true
        log_success "Podman package removed successfully"
        return 0
    else
        log_error "Failed to remove Podman package: $package_name"
        return 1
    fi
}


# Get latest version from apt
podman_plugin_get_latest_version() {
    apt-cache show podman 2>/dev/null | grep -oP 'Version: \K[^-]+' | head -1 || echo "not-found"
}