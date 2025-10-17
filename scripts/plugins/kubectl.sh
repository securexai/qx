#!/bin/bash

# kubectl Kubernetes CLI Plugin for QX Installation Script
# Implements the standardized plugin interface

# Plugin information
kubectl_plugin_name() { echo "kubectl"; }
kubectl_plugin_version() {
    if command -v kubectl >/dev/null 2>&1; then
        kubectl version --client --short 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 || echo "unknown"
    else
        echo "not installed"
    fi
}
kubectl_plugin_info() {
    cat << EOF
Name: kubectl Kubernetes CLI
Description: Kubernetes command-line tool for interacting with Kubernetes clusters
Website: https://kubernetes.io/docs/tasks/tools/
Installation Method: Official binary download
Default Version: $(get_config_value "tools.kubectl.version" "1.30.0")
Install Path: $(get_config_value "paths.kubectl_install_path" "/usr/local/bin")
EOF
}

# Detection - check if kubectl is installed
kubectl_plugin_detect() {
    if command -v kubectl >/dev/null 2>&1; then
        return 0
    fi

    # Check specific install path
    local install_path
    install_path=$(get_config_value "paths.kubectl_install_path" "/usr/local/bin")
    if [ -x "$install_path/kubectl" ]; then
        return 0
    fi

    return 1
}

# Dependencies - none required
kubectl_plugin_dependencies() {
    echo ""
}

# Installation - download and install kubectl binary
kubectl_plugin_install() {
    local version="${1:-$(get_config_value "tools.kubectl.version" "1.30.0")}"
    local install_path="${2:-$(get_config_value "paths.kubectl_install_path" "/usr/local/bin")}"

    log_info "Installing kubectl version: $version"
    log_info "Install path: $install_path"

    # Construct download URL
    local download_url="https://dl.k8s.io/release/v${version}/bin/linux/amd64/kubectl"
    local temp_binary
    temp_binary=$(create_temp_file "kubectl")

    log_info "Downloading kubectl binary..."
    if secure_download "$download_url" "$temp_binary" ""; then
        # Make executable and move to install path
        chmod +x "$temp_binary"

        ensure_dir "$install_path"
        mv "$temp_binary" "$install_path/kubectl"

        log_success "kubectl binary installed to: $install_path/kubectl"
        return 0
    else
        rm -f "$temp_binary"
        log_error "Failed to download kubectl binary"
        return 1
    fi
}

# Verification - check that kubectl is working
kubectl_plugin_verify() {
    local install_path="${1:-$(get_config_value "paths.kubectl_install_path" "/usr/local/bin")}"
    local kubectl_binary="$install_path/kubectl"

    if [ -x "$kubectl_binary" ]; then
        # Try to get version to verify it's working
        if "$kubectl_binary" version --client --short >/dev/null 2>&1; then
            local version
            version=$("$kubectl_binary" version --client --short 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 || echo "unknown")
            log_success "✅ kubectl verified: $kubectl_binary (version: $version)"
            return 0
        else
            log_error "❌ kubectl binary exists but is not working: $kubectl_binary"
            return 1
        fi
    else
        log_error "❌ kubectl binary not found or not executable: $kubectl_binary"
        return 1
    fi
}

# Uninstallation - remove kubectl binary
kubectl_plugin_uninstall() {
    local install_path="${1:-$(get_config_value "paths.kubectl_install_path" "/usr/local/bin")}"

    log_warn "Uninstalling kubectl from: $install_path"

    local kubectl_binary="$install_path/kubectl"

    if [ -f "$kubectl_binary" ]; then
        rm -f "$kubectl_binary"
        log_success "kubectl binary removed: $kubectl_binary"
    else
        log_warn "kubectl binary not found: $kubectl_binary"
    fi

    return 0
}

# Get latest version
kubectl_plugin_get_latest_version() {
    curl -L -s https://dl.k8s.io/release/stable.txt
}

    log_warn "Uninstalling kubectl from: $install_path"

    local kubectl_binary="$install_path/kubectl"

    if [ -f "$kubectl_binary" ]; then
        rm -f "$kubectl_binary"
        log_success "kubectl binary removed: $kubectl_binary"
    else
        log_warn "kubectl binary not found: $kubectl_binary"
    fi

    return 0
}