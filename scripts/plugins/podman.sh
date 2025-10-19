#!/bin/bash

# Podman Container Runtime Plugin for QX Installation Script
# Implements the standardized plugin interface for Ubuntu 24.04 (Noble)
# Adds version pinning to 5.6.2, dependency management, systemd startup,
# uninstall cleanup, and rollback integration.

# Constants for libcontainers (Kubic) repo (Ubuntu 24.04)
PODMAN_APT_KEYRING="/etc/apt/keyrings/libcontainers-archive-keyring.gpg"
PODMAN_APT_LIST="/etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
PODMAN_APT_URL="https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_24.04/"
PODMAN_APT_KEY_URL="${PODMAN_APT_URL}Release.key"

# Helper: get required version from channel or config (defaults to 5.6.2)
_podman_required_version() {
    local channel="${CHANNEL:-stable}"
    local from_channel
    if command -v get_tool_version_from_channel >/dev/null 2>&1; then
        from_channel=$(get_tool_version_from_channel "podman" "$channel" || true)
    fi
    if [ -n "$from_channel" ] && [ "$from_channel" != "latest" ]; then
        echo "$from_channel"
    else
        echo "$(get_config_value "tools.podman.version" "5.6.2")"
    fi
}

# Helper: ensure libcontainers APT repo is configured
_podman_setup_apt_repo() {
    # Create keyrings directory
    ensure_dir "/etc/apt/keyrings"

    # Import GPG key if missing
    if [ ! -f "$PODMAN_APT_KEYRING" ]; then
        log_info "Adding libcontainers APT repository key"
        local tmp_key
        tmp_key=$(create_temp_file "podman-key")
        if curl -fsSL "$PODMAN_APT_KEY_URL" -o "$tmp_key"; then
            if gpg --yes --dearmor -o "$PODMAN_APT_KEYRING" "$tmp_key"; then
                chmod 644 "$PODMAN_APT_KEYRING"
                record_file_installation "$PODMAN_APT_KEYRING"
                log_success "Repository key installed: $PODMAN_APT_KEYRING"
            else
                log_error "Failed to dearmor repository key"
                return 1
            fi
        else
            log_error "Failed to download repository key from $PODMAN_APT_KEY_URL"
            return 1
        fi
        rm -f "$tmp_key"
    else
        log_debug "Repository key already present: $PODMAN_APT_KEYRING"
    fi

    # Create sources.list entry if missing
    if [ ! -f "$PODMAN_APT_LIST" ]; then
        log_info "Configuring libcontainers APT repository"
        echo "deb [signed-by=$PODMAN_APT_KEYRING] $PODMAN_APT_URL /" > "$PODMAN_APT_LIST"
        chmod 644 "$PODMAN_APT_LIST"
        record_file_installation "$PODMAN_APT_LIST"
        log_success "Repository configured: $PODMAN_APT_LIST"
    else
        log_debug "Repository already configured: $PODMAN_APT_LIST"
    fi

    log_debug "Updating package lists"
    apt-get update -qq
}

# Helper: find exact apt version matching X.Y.Z
_podman_find_exact_version() {
    local desired="$1"
    # Try apt-cache madison first for structured output
    local exact
    exact=$(apt-cache madison podman 2>/dev/null | awk -v v="$desired" '$0 ~ v {print $3; exit}')
    if [ -z "$exact" ]; then
        # Fallback to apt-cache policy parse
        exact=$(apt-cache policy podman 2>/dev/null | awk -v v="$desired" '/Candidate|Version table:/,0 { if ($1 ~ /^[[:space:]]*[0-9]/) { gsub(/^[[:space:]]+/, "", $1); if ($1 ~ "^" v) { print $1; exit } } }')
    fi
    echo "$exact"
}

# Helper: enable systemd socket for Podman API at boot
_podman_enable_startup() {
    if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
        log_info "Enabling Podman systemd socket for startup"
        if systemctl enable --now podman.socket >/dev/null 2>&1; then
            log_success "podman.socket enabled and started"
            # Register rollback to disable if needed
            register_rollback_action "svc_podman_socket" "run_command" "systemctl disable --now podman.socket >/dev/null 2>&1 || true"
        else
            log_warn "Could not enable podman.socket (continuing)"
        fi
    else
        log_warn "systemd not available; skipping startup configuration"
    fi
}

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
Installation Method: Ubuntu package manager (apt + libcontainers repo)
Default Version: $(_podman_required_version)
Packages: podman, conmon, crun, runc, podman-plugins, netavark, aardvark-dns, slirp4netns
EOF
}

# Detection - check if podman is installed and matches required version (if specified)
podman_plugin_detect() {
    if ! command -v podman >/dev/null 2>&1; then
        return 1
    fi
    local installed
    installed=$(podman --version 2>/dev/null | awk '{print $3}' || true)
    local required
    required=$(_podman_required_version)
    if [ -n "$required" ] && [ "$required" != "latest" ]; then
        if version_compare "$installed" eq "$required"; then
            return 0
        else
            log_info "Podman installed ($installed) but required is $required — will upgrade/downgrade"
            return 1
        fi
    fi
    return 0
}

# Dependencies required before repo setup/installation
podman_plugin_dependencies() {
    echo "ca-certificates curl gnupg lsb-release uidmap dbus-user-session"
}

# Installation - pinned to desired version if available
podman_plugin_install() {
    local version="${1:-$(_podman_required_version)}"

    if [ -z "$version" ] || [ "$version" = "latest" ]; then
        version="$(_podman_required_version)"
    fi

    log_info "Installing Podman version: $version on Ubuntu 24.04"

    # Root required for apt operations
    if [ "$EUID" -ne 0 ]; then
        log_error "Podman installation requires root privileges"
        return 1
    fi

    # Ensure repo is configured
    _podman_setup_apt_repo

    # Ensure base dependencies for rootless networking and runtimes
    local deps=(conmon crun runc podman-plugins netavark aardvark-dns slirp4netns)

    # Find exact Podman version in repo
    local exact
    exact=$(_podman_find_exact_version "$version")
    if [ -z "$exact" ]; then
        log_error "Could not find Podman version matching $version in repositories"
        return 1
    fi

    log_info "Resolved Podman package version: $exact"

    # Install packages with rollback tracking
    log_info "Installing Podman and dependencies"
    if DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "podman=$exact"; then
        record_package_installation "podman"
    else
        log_error "Failed to install podman=$exact"
        return 1
    fi

    # Install supplemental deps (best-effort, not strictly version pinned)
    local to_install=("${deps[@]}")
    if ! DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${to_install[@]}"; then
        log_warn "Some Podman dependencies failed to install; continuing"
    else
        for p in "${to_install[@]}"; do
            record_package_installation "$p"
        done
    fi

    # Enable startup socket
    _podman_enable_startup

    log_success "Podman $version installation completed"
    return 0
}

# Verification - check that podman is working and at expected version
podman_plugin_verify() {
    if ! command -v podman >/dev/null 2>&1; then
        log_error "❌ Podman command not found"
        return 1
    fi

    local required
    required=$(_podman_required_version)

    if ! podman --version >/dev/null 2>&1; then
        log_error "❌ Podman exists but failed to run"
        return 1
    fi

    local installed
    installed=$(podman --version 2>/dev/null | awk '{print $3}' || echo "unknown")

    if [ -n "$required" ] && [ "$required" != "latest" ] && ! version_compare "$installed" eq "$required"; then
        log_error "❌ Podman version mismatch. Installed: $installed, Required: $required"
        return 1
    fi

    # Basic runtime sanity check
    if ! podman info >/dev/null 2>&1; then
        log_warn "Podman info failed; runtime may not be fully configured yet"
    fi

    log_success "✅ Podman verified (version: $installed)"
    return 0
}

# Uninstallation - remove podman and cleanup repo and services
podman_plugin_uninstall() {
    log_warn "Uninstalling Podman and cleaning up"

    if [ "$EUID" -ne 0 ]; then
        log_error "Podman uninstallation requires root privileges"
        return 1
    fi

    # Stop/disable socket if present
    if command -v systemctl >/dev/null 2>&1; then
        systemctl disable --now podman.socket >/dev/null 2>&1 || true
    fi

    # Remove packages
    local pkgs=(podman podman-plugins conmon crun runc netavark aardvark-dns slirp4netns)
    DEBIAN_FRONTEND=noninteractive apt-get purge -y -qq "${pkgs[@]}" >/dev/null 2>&1 || true
    apt-get autoremove -y -qq >/dev/null 2>&1 || true

    # Remove repo files if they were created by us
    if [ -f "$PODMAN_APT_LIST" ]; then
        rm -f "$PODMAN_APT_LIST"
        log_info "Removed repo list: $PODMAN_APT_LIST"
    fi
    if [ -f "$PODMAN_APT_KEYRING" ]; then
        rm -f "$PODMAN_APT_KEYRING"
        log_info "Removed repo keyring: $PODMAN_APT_KEYRING"
    fi

    log_success "Podman uninstalled"
    return 0
}

# Get latest version (fallback to GitHub API, then apt)
podman_plugin_get_latest_version() {
    local latest
    latest=$(curl -sL https://api.github.com/repos/containers/podman/releases/latest | grep -oP '"tag_name"\s*:\s*"v?\K[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
    if [ -n "$latest" ]; then
        echo "$latest"
        return 0
    fi
    # Fallback to apt policy
    apt-cache show podman 2>/dev/null | grep -oP 'Version: \K[^-]+' | head -1 || echo "not-found"
}
