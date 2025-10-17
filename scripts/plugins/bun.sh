#!/bin/bash

# Bun JavaScript Runtime Plugin for QX Installation Script
# Implements the standardized plugin interface

# Plugin information
bun_plugin_name() { echo "bun"; }
bun_plugin_version() {
    if command -v bun >/dev/null 2>&1; then
        bun --version 2>/dev/null | sed 's/bun //' || echo "unknown"
    else
        echo "not installed"
    fi
}
bun_plugin_info() {
    cat << EOF
Name: Bun JavaScript Runtime
Description: Fast all-in-one JavaScript runtime, bundler, transpiler, and package manager
Website: https://bun.sh
Installation Method: Official installer script
Default Version: $(get_config_value "tools.bun.version" "1.2.23")
Installation Path: $(get_config_value "paths.bun_install_path" "/usr/local")
EOF
}

# Detection - check multiple possible locations
bun_plugin_detect() {
    # Check if bun is in PATH
    if command -v bun >/dev/null 2>&1; then
        return 0
    fi

    # Check system-wide installation
    local install_path
    install_path=$(get_config_value "paths.bun_install_path" "/usr/local")
    if [ -x "$install_path/bin/bun" ]; then
        return 0
    fi

    # Check user's home directory for bun (when running with sudo)
    if [ -n "${HOME:-}" ] && [ -x "$HOME/.bun/bin/bun" ]; then
        return 0
    fi

    # Check root's home directory
    if [ -x "/root/.bun/bin/bun" ]; then
        return 0
    fi

    # Check if BUN_INSTALL environment variable points to a custom location
    if [ -n "${BUN_INSTALL:-}" ] && [ -x "$BUN_INSTALL/bin/bun" ]; then
        return 0
    fi

    return 1
}

# Dependencies - unzip is required for the installer
bun_plugin_dependencies() {
    echo "unzip"
}

# Installation
bun_plugin_install() {
    local version="${1:-$(get_config_value "tools.bun.version" "1.2.23")}"
    local install_path="${2:-$(get_config_value "paths.bun_install_path" "/usr/local")}"

    log_info "Installing Bun version: $version"
    log_info "Install path: $install_path"

    # Create installation directory if it doesn't exist
    ensure_dir "$install_path"

    # Set environment for installation
    export BUN_INSTALL="$install_path"

    # Download and execute installer
    local installer_url="https://bun.sh/install"
    local temp_installer
    temp_installer=$(create_temp_file "bun-installer")

    log_info "Downloading Bun installer..."
    if secure_download "$installer_url" "$temp_installer" ""; then
        log_info "Executing Bun installer..."
        if bash "$temp_installer"; then
            rm -f "$temp_installer"
            return 0
        else
            rm -f "$temp_installer"
            log_error "Bun installer execution failed"
            return 1
        fi
    else
        rm -f "$temp_installer"
        log_error "Failed to download Bun installer"
        return 1
    fi
}

# Verification - check that bun is installed and working
bun_plugin_verify() {
    local install_path="${1:-$(get_config_value "paths.bun_install_path" "/usr/local")}"
    local bun_binary="$install_path/bin/bun"

    # Check if binary exists and is executable
    if [ -x "$bun_binary" ]; then
        # Try to get version to verify it's working
        if "$bun_binary" --version >/dev/null 2>&1; then
            local version
            version=$("$bun_binary" --version 2>/dev/null | sed 's/bun //' || echo "unknown")
            log_success "✅ Bun verified: $bun_binary (version: $version)"
            return 0
        else
            log_error "❌ Bun binary exists but is not working: $bun_binary"
            return 1
        fi
    else
        log_error "❌ Bun binary not found or not executable: $bun_binary"
        return 1
    fi
}

# Uninstallation - remove bun installation
bun_plugin_uninstall() {
    local install_path="${1:-$(get_config_value "paths.bun_install_path" "/usr/local")}"

    log_warn "Uninstalling Bun from: $install_path"

    # Remove installation directory
    if [ -d "$install_path" ]; then
        rm -rf "$install_path"
        log_info "Removed installation directory: $install_path"
    fi

    # Remove from user's home directory if it exists
    if [ -n "${HOME:-}" ] && [ -d "$HOME/.bun" ]; then
        rm -rf "$HOME/.bun"
        log_info "Removed user installation directory: $HOME/.bun"
    fi

    # Remove from root's home directory if it exists
    if [ -d "/root/.bun" ]; then
        rm -rf "/root/.bun"
        log_info "Removed root installation directory: /root/.bun"
    fi

    # Note: We don't modify PATH or other environment variables as they
    # may be managed by the system or user configuration

    return 0
}

# Get latest version
bun_plugin_get_latest_version() {
    curl -sSL https://bun.sh/install | grep -o 'BUN_VERSION=".*"' | sed 's/BUN_VERSION="\(.*\)"/\1/'
}