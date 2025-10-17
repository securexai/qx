#!/bin/bash

# Kind (Kubernetes in Docker) Plugin for QX Installation Script
# Implements the standardized plugin interface

# Plugin information
kind_plugin_name() { echo "kind"; }
kind_plugin_version() {
    if command -v kind >/dev/null 2>&1; then
        kind version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown"
    else
        echo "not installed"
    fi
}
kind_plugin_info() {
    cat << EOF
Name: Kind (Kubernetes in Docker)
Description: Tool for running local Kubernetes clusters using Docker container nodes
Website: https://kind.sigs.k8s.io
Installation Method: Official binary download
Default Version: $(get_config_value "tools.kind.version" "0.30.0")
Install Path: $(get_config_value "paths.kind_install_path" "/usr/local/bin")
EOF
}

# Detection - check if kind is installed
kind_plugin_detect() {
    if command -v kind >/dev/null 2>&1; then
        return 0
    fi

    # Check specific install path
    local install_path
    install_path=$(get_config_value "paths.kind_install_path" "/usr/local/bin")
    if [ -x "$install_path/kind" ]; then
        return 0
    fi

    return 1
}

# Dependencies - none required
kind_plugin_dependencies() {
    echo ""
}

# Installation - download and install kind binary
kind_plugin_install() {
    local version="${1:-$(get_config_value "tools.kind.version" "0.30.0")}"
    local install_path="${2:-$(get_config_value "paths.kind_install_path" "/usr/local/bin")}"

    log_info "Installing kind version: $version"
    log_info "Install path: $install_path"

    # Construct download URL
    local download_url="https://kind.sigs.k8s.io/dl/v${version}/kind-linux-amd64"
    local temp_binary
    temp_binary=$(create_temp_file "kind")

    log_info "Downloading kind binary..."
    if secure_download "$download_url" "$temp_binary" ""; then
        # Make executable and move to install path
        chmod +x "$temp_binary"

        ensure_dir "$install_path"
        mv "$temp_binary" "$install_path/kind"

        log_success "kind binary installed to: $install_path/kind"
        return 0
    else
        rm -f "$temp_binary"
        log_error "Failed to download kind binary"
        return 1
    fi
}

# Verification - check that kind is working
kind_plugin_verify() {
    local install_path="${1:-$(get_config_value "paths.kind_install_path" "/usr/local/bin")}"
    local kind_binary="$install_path/kind"

    if [ -x "$kind_binary" ]; then
        # Try to get version to verify it's working
        if "$kind_binary" version >/dev/null 2>&1; then
            local version
            version=$("$kind_binary" version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
            log_success "✅ kind verified: $kind_binary (version: $version)"
            return 0
        else
            log_error "❌ kind binary exists but is not working: $kind_binary"
            return 1
        fi
    else
        log_error "❌ kind binary not found or not executable: $kind_binary"
        return 1
    fi
}

# Uninstallation - remove kind binary
kind_plugin_uninstall() {
    local install_path="${1:-$(get_config_value "paths.kind_install_path" "/usr/local/bin")}"

    log_warn "Uninstalling kind from: $install_path"

    local kind_binary="$install_path/kind"

    if [ -f "$kind_binary" ]; then
        rm -f "$kind_binary"
        log_success "kind binary removed: $kind_binary"
    else
        log_warn "kind binary not found: $kind_binary"
    fi

    return 0
}

# Get latest version
kind_plugin_get_latest_version() {
    curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq -r .tag_name
}