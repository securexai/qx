#!/bin/bash

# Platform detection and validation module for QX installation script

# Global platform variables
PLATFORM_OS=""
PLATFORM_ARCH=""
PLATFORM_DISTRO=""
PLATFORM_VERSION=""
PLATFORM_CODENAME=""

# Detect operating system
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        PLATFORM_OS="${ID:-unknown}"
        PLATFORM_DISTRO="${PRETTY_NAME:-$PLATFORM_OS}"
        PLATFORM_VERSION="${VERSION_ID:-unknown}"
        PLATFORM_CODENAME="${VERSION_CODENAME:-unknown}"
    elif [ -f /etc/redhat-release ]; then
        PLATFORM_OS="rhel"
        PLATFORM_DISTRO=$(cat /etc/redhat-release)
        PLATFORM_VERSION=$(rpm -q --qf "%{VERSION}" "$(rpm -q --whatprovides redhat-release)")
    elif [ -f /etc/debian_version ]; then
        PLATFORM_OS="debian"
        PLATFORM_DISTRO="Debian $(cat /etc/debian_version)"
        PLATFORM_VERSION=$(cat /etc/debian_version)
    else
        PLATFORM_OS="unknown"
        PLATFORM_DISTRO="Unknown Linux Distribution"
        PLATFORM_VERSION="unknown"
    fi

    log_debug "Detected OS: $PLATFORM_OS ($PLATFORM_DISTRO)"
    log_debug "Version: $PLATFORM_VERSION"
}

# Detect architecture
detect_arch() {
    PLATFORM_ARCH=$(uname -m)

    # Normalize architecture names
    case "$PLATFORM_ARCH" in
        x86_64|amd64)
            PLATFORM_ARCH="x86_64"
            ;;
        aarch64|arm64)
            PLATFORM_ARCH="arm64"
            ;;
        armv7l|armv7)
            PLATFORM_ARCH="armv7"
            ;;
        *)
            log_warn "Unsupported architecture: $PLATFORM_ARCH"
            ;;
    esac

    log_debug "Detected architecture: $PLATFORM_ARCH"
}

# Validate platform compatibility
validate_platform() {
    local required_os="${1:-ubuntu}"
    local required_version="${2:-24.04}"
    local required_arch="${3:-x86_64}"

    log_info "Validating platform compatibility..."

    # Check OS
    if [ "$PLATFORM_OS" != "$required_os" ]; then
        log_failure "This script requires $required_os, but detected: $PLATFORM_OS"
        return 1
    fi

    # Check version (for Ubuntu/Debian-like systems)
    if [ "$PLATFORM_OS" = "ubuntu" ] && [ -n "$PLATFORM_VERSION" ]; then
        if ! dpkg --compare-versions "$PLATFORM_VERSION" ge "$required_version"; then
            log_failure "This script requires $required_os $required_version+, but detected: $PLATFORM_VERSION"
            return 1
        fi
    fi

    # Check architecture
    if [ "$PLATFORM_ARCH" != "$required_arch" ]; then
        log_failure "This script requires $required_arch architecture, but detected: $PLATFORM_ARCH"
        return 1
    fi

    log_success "Platform validation passed: $PLATFORM_DISTRO ($PLATFORM_ARCH)"
    return 0
}

# Check if running as root/admin
check_privileges() {
    if [ "$EUID" -eq 0 ]; then
        log_debug "Running with root privileges"
        return 0
    else
        log_debug "Running as regular user"
        return 1
    fi
}

# Get system information
get_system_info() {
    cat << EOF
System Information:
==================
OS: $PLATFORM_DISTRO
Architecture: $PLATFORM_ARCH
Kernel: $(uname -r)
Shell: $SHELL
User: $(whoami)
Privileges: $(check_privileges && echo "root" || echo "user")
EOF
}

# Check system requirements
check_system_requirements() {
    local requirements=("$@")
    local missing=()

    log_info "Checking system requirements..."

    for req in "${requirements[@]}"; do
        case "$req" in
            curl)
                if ! command -v curl >/dev/null 2>&1; then
                    missing+=("curl")
                fi
                ;;
            wget)
                if ! command -v wget >/dev/null 2>&1; then
                    missing+=("wget")
                fi
                ;;
            ca-certificates)
                if ! dpkg -l ca-certificates >/dev/null 2>&1; then
                    missing+=("ca-certificates")
                fi
                ;;
            unzip)
                if ! command -v unzip >/dev/null 2>&1; then
                    missing+=("unzip")
                fi
                ;;
            bc)
                if ! command -v bc >/dev/null 2>&1; then
                    missing+=("bc")
                fi
                ;;
            *)
                log_warn "Unknown requirement: $req"
                ;;
        esac
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_warn "Missing system requirements: ${missing[*]}"
        return 1
    else
        log_success "All system requirements satisfied"
        return 0
    fi
}

# Initialize platform detection
init_platform() {
    detect_os
    detect_arch
    log_info "Platform initialized: $PLATFORM_OS $PLATFORM_VERSION ($PLATFORM_ARCH)"
}

# Export platform information for use by other modules
export PLATFORM_OS PLATFORM_ARCH PLATFORM_DISTRO PLATFORM_VERSION PLATFORM_CODENAME