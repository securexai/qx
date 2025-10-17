#!/bin/bash

# QX Prerequisites Installation Script - Enhanced Version
# Modern, secure, and extensible installation script for QX project prerequisites

# Fail fast and treat unset variables as errors
set -euo pipefail

# Get script directory and set up paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/$(get_config_value "paths.lib_dir" "lib")"
CONFIG_DIR="$SCRIPT_DIR/$(get_config_value "paths.config_dir" "config")"
PLUGINS_DIR="$SCRIPT_DIR/$(get_config_value "paths.plugins_dir" "plugins")"

# Source core library modules
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/logger.sh"
source "$LIB_DIR/platform.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/downloader.sh"
source "$LIB_DIR/rollback.sh"
source "$LIB_DIR/plugin_manager.sh"

# Global variables
DRY_RUN=false
FORCE_MODE=false
QUIET_MODE=false
PROFILE="full"
SELECTED_TOOLS=()
LOG_LEVEL="info"
LOG_FILE=""
CONFIG_FILE="default.yaml"
CHANNEL="stable"
UNINSTALL_MODE=false

# CLI argument parsing
parse_arguments() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --dry-run|--check|-n)
                DRY_RUN=true
                shift
                ;;
            --force|-f)
                FORCE_MODE=true
                shift
                ;;
            --quiet|-q)
                QUIET_MODE=true
                LOG_LEVEL="error"
                shift
                ;;
            --verbose|-v)
                LOG_LEVEL="debug"
                shift
                ;;
            --profile|-p)
                PROFILE="$2"
                shift 2
                ;;
            --tools|-t)
                IFS=',' read -ra SELECTED_TOOLS <<< "$2"
                shift 2
                ;;
            --log-file|-l)
                LOG_FILE="$2"
                shift 2
                ;;
            --config|-c)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --version|-V)
                show_version
                exit 0
                ;;
            --channel)
                CHANNEL="$2"
                shift 2
                ;;
            --uninstall)
                UNINSTALL_MODE=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help information
show_help() {
    cat << EOF
QX Prerequisites Installation Script

USAGE:
    $0 [OPTIONS] [TOOLS...]

OPTIONS:
    -h, --help              Show this help message
    -n, --dry-run, --check  Run in dry-run mode (no actual installation)
    -f, --force             Force reinstallation of already installed tools
    -q, --quiet             Quiet mode (only errors)
    -v, --verbose           Verbose logging
    -p, --profile PROFILE   Use installation profile (minimal, development, full)
    -t, --tools TOOLS       Comma-separated list of tools to install
    -l, --log-file FILE     Log to specified file
    -c, --config FILE       Use specified config file
    --channel CHANNEL     Use specified channel (stable, latest)
    --uninstall             Uninstall specified tools
    -V, --version           Show version information

PROFILES:
    minimal     - Bun only
    development - Bun, kubectl, kind
    full        - All tools (Bun, Podman, kubectl, kind)

TOOLS:
    bun         - JavaScript runtime and bundler
    podman      - Container runtime
    kubectl     - Kubernetes CLI
    kind        - Kubernetes in Docker

EXAMPLES:
    $0                          # Install all tools with full profile
    $0 --dry-run                # Check what would be installed
    $0 --profile development    # Install development tools only
    $0 --tools bun,kubectl      # Install specific tools
    $0 --force --quiet          # Force reinstall all, minimal output

CONFIGURATION:
    Configuration files are located in: $CONFIG_DIR
    Default config: $CONFIG_DIR/default.yaml

TESTING WITH PODMAN:
    To test this script in a clean, isolated environment, you can use a disposable Podman container.
    This command runs the script in dry-run mode within a container, ensuring no changes are made to your local system:

    podman run --rm -it -v "$PWD:/workspace:ro" ubuntu:24.04 bash -c "apt-get update -qq && apt-get install -y -qq curl unzip bc && bash /workspace/development/scripts/install-prereqs.sh --dry-run"

For more information, see: https://github.com/securexai/qx
EOF
}

# Show version information
show_version() {
    echo "QX Prerequisites Installation Script v2.0.0"
    echo "Enhanced version with modular architecture and security features"
}

# Initialize the script
initialize() {
    # Initialize utility functions
    init_utils

    # Initialize logging
    log_init "$LOG_LEVEL" "$LOG_FILE"

    # Disable colors if quiet mode or not a terminal
    if [ "$QUIET_MODE" = true ] || [ ! -t 1 ]; then
        COLOR_OUTPUT=false
    fi

    # Initialize platform detection
    init_platform

    # Initialize configuration
    if ! init_config; then
        log_error "Failed to initialize configuration"
        exit 1
    fi

    # Initialize plugin manager
    init_plugin_manager

    log_info "QX Prerequisites Installation Script initialized"
    log_debug "Script directory: $SCRIPT_DIR"
    log_debug "Profile: $PROFILE"
    log_debug "Dry run: $DRY_RUN"
    log_debug "Force mode: $FORCE_MODE"
}

# Validate prerequisites
validate_prerequisites() {
    log_info "Validating prerequisites..."

    # Check platform compatibility
    local min_ubuntu_version
    min_ubuntu_version=$(get_config_value "platform.min_ubuntu_version" "24.04")

    if ! validate_platform "ubuntu" "$min_ubuntu_version" "x86_64"; then
        log_error "Platform validation failed"
        exit 1
    fi

    # Check system requirements
    local required_packages
    required_packages=$(get_config_value "platform.required_system_packages" "curl ca-certificates unzip bc")

    if ! check_system_requirements $required_packages; then
        log_error "System requirements not met"
        exit 1
    fi

    # Check privileges for installation
    if [ "$DRY_RUN" = false ] && [ "$EUID" -ne 0 ]; then
        log_error "Installation requires root privileges (use sudo)"
        exit 1
    fi

    log_success "Prerequisites validation passed"
}

# Determine tools to install
determine_tools_to_install() {
    if [ ${#SELECTED_TOOLS[@]} -gt 0 ]; then
        # Use explicitly specified tools
        log_info "Using explicitly specified tools: ${SELECTED_TOOLS[*]}"
        return
    fi

    # Use profile-based selection
    local profile_tools
    case "$PROFILE" in
        minimal)
            profile_tools=$(get_config_value "profiles.minimal" "bun")
            ;;
        development)
            profile_tools=$(get_config_value "profiles.development" "bun,kubectl,kind")
            ;;
        full)
            profile_tools=$(get_config_value "profiles.full" "bun,podman,kubectl,kind")
            ;;
        *)
            log_error "Unknown profile: $PROFILE"
            exit 1
            ;;
    esac

    log_info "Using profile 	'$PROFILE': $profile_tools"
    IFS=',' read -ra SELECTED_TOOLS <<< "$profile_tools"
}

# Show installation plan
show_installation_plan() {
    log_info "Installation Plan:"
    log_info "=================="
    log_info "Profile: $PROFILE"
    log_info "Tools to process: ${SELECTED_TOOLS[*]}"
    log_info "Dry run: $DRY_RUN"
    log_info "Force mode: $FORCE_MODE"
    log_info ""

    local will_install=()
    local already_installed=()

    for tool in "${SELECTED_TOOLS[@]}"; do
        if is_plugin_available "$tool"; then
            if [ "$FORCE_MODE" = true ] || ! detect_plugin_tool "$tool"; then
                will_install+=("$tool")
            else
                local version
                version=$(execute_plugin_function "$tool" "plugin_version")
                already_installed+=("$tool ($version)")
            fi
        else
            log_warn "Plugin not available: $tool"
        fi
    done

    if [ ${#already_installed[@]} -gt 0 ]; then
        log_info "Already installed (skipping): ${already_installed[*]}"
    fi

    if [ ${#will_install[@]} -gt 0 ]; then
        if [ "$DRY_RUN" = true ]; then
            log_info "Would install: ${will_install[*]}"
        else
            log_info "Will install: ${will_install[*]}"
        fi
    else
        log_info "All tools are already installed"
    fi
}

# Install tools
install_tools() {
    local installed_count=0
    local failed_count=0

    log_info "Starting tool installation..."

    for tool in "${SELECTED_TOOLS[@]}"; do
        if ! is_plugin_available "$tool"; then
            log_error "Plugin not available: $tool"
            ((failed_count++))
            continue
        fi

        log_info "Processing tool: $tool"

        local version
        version=$(get_tool_version_from_channel "$tool" "$CHANNEL")

        if ! install_plugin_tool "$tool" "$FORCE_MODE" "$version"; then
            log_error "Failed to install: $tool"
            ((failed_count++))
        else
            ((installed_count++))
        fi
    done

    log_info "Installation completed: $installed_count successful, $failed_count failed"
    return $failed_count
}

# Uninstall tools
uninstall_tools() {
    local uninstalled_count=0
    local failed_count=0

    log_info "Starting tool uninstallation..."

    for tool in "${SELECTED_TOOLS[@]}"; do
        if ! is_plugin_available "$tool"; then
            log_error "Plugin not available: $tool"
            ((failed_count++))
            continue
        fi

        log_info "Processing tool: $tool"

        if ! uninstall_plugin_tool "$tool"; then
            log_error "Failed to uninstall: $tool"
            ((failed_count++))
        else
            ((uninstalled_count++))
        fi
    done

    log_info "Uninstallation completed: $uninstalled_count successful, $failed_count failed"
    return $failed_count
}

# Generate installation summary
generate_summary() {
    log_info ""
    log_info "Installation Summary"
    log_info "==================="

    local total_tools=${#SELECTED_TOOLS[@]}
    local installed_tools=()
    local failed_tools=()

    for tool in "${SELECTED_TOOLS[@]}"; do
        if is_plugin_available "$tool" && detect_plugin_tool "$tool"; then
            local version
            version=$(execute_plugin_function "$tool" "plugin_version")
            installed_tools+=("$tool ($version)")
        else
            failed_tools+=("$tool")
        fi
    done

    log_info "Total tools processed: $total_tools"
    log_info "Successfully installed: ${#installed_tools[@]}"

    if [ ${#installed_tools[@]} -gt 0 ]; then
        for tool_info in "${installed_tools[@]}"; do
            log_success "✓ $tool_info"
        done
    fi

    if [ ${#failed_tools[@]} -gt 0 ]; then
        log_error "Failed installations: ${#failed_tools[@]}"
        for tool in "${failed_tools[@]}"; do
            log_error "✗ $tool"
        done
    fi

    # Show system information
    if [ "$QUIET_MODE" = false ]; then
        log_info ""
        log_info "System Information:"
        get_system_info
    fi
}

# Main execution flow
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Initialize script
    initialize

    # Validate prerequisites
    validate_prerequisites

    # Determine tools to install
    determine_tools_to_install

    # Show installation plan
    show_installation_plan

    if [ "$DRY_RUN" = true ]; then
        log_info "Dry run completed - no changes made"
        exit 0
    fi

    if [ "$UNINSTALL_MODE" = true ]; then
        if uninstall_tools; then
            log_success "All uninstallations completed successfully"
        else
            log_error "Some uninstallations failed"
            exit 1
        fi
        exit 0
    fi

    # Initialize rollback system
    init_rollback

    # Install tools
    if install_tools; then
        log_success "All installations completed successfully"
    else
        log_error "Some installations failed"
        log_warn "You can attempt to rollback changes using rollback functionality"
        exit 1
    fi

    # Generate summary
    generate_summary

    log_success "QX prerequisites installation completed!"
}

# Run main function with all arguments
main "$@"