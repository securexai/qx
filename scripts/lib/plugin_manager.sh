#!/bin/bash

# Plugin manager module for QX installation script
# Manages loading, validation, and execution of tool plugins

# Plugin registry
declare -A PLUGINS
declare -A PLUGIN_STATES

# Load all plugins from plugins directory
load_plugins() {
    local plugin_dir="${SCRIPT_DIR}/plugins"

    log_info "Loading plugins from: $plugin_dir"

    if [ ! -d "$plugin_dir" ]; then
        log_warn "Plugin directory not found: $plugin_dir"
        return 0
    fi

    local plugin_count=0

    for plugin_file in "$plugin_dir"/*.sh; do
        if [ -f "$plugin_file" ]; then
            local plugin_name
            plugin_name=$(basename "$plugin_file" .sh)

            log_debug "Loading plugin: $plugin_name"

            # Source plugin file
            if source "$plugin_file"; then
                # Validate plugin interface
                if validate_plugin "$plugin_name"; then
                    PLUGINS["$plugin_name"]="$plugin_file"
                    PLUGIN_STATES["$plugin_name"]="loaded"
                    plugin_count=$((plugin_count + 1))
                    log_debug "✅ Loaded plugin: $plugin_name"
                else
                    log_error "❌ Invalid plugin interface: $plugin_name"
                    PLUGIN_STATES["$plugin_name"]="invalid"
                fi
            else
                log_error "❌ Failed to load plugin: $plugin_name"
                PLUGIN_STATES["$plugin_name"]="failed"
            fi
        fi
    done

    log_info "Loaded $plugin_count plugins successfully"
}

# Validate plugin interface - check for required functions
validate_plugin() {
    local plugin_name="$1"
    local required_functions=(
        "${plugin_name}_plugin_name"
        "${plugin_name}_plugin_version"
        "${plugin_name}_plugin_detect"
        "${plugin_name}_plugin_dependencies"
        "${plugin_name}_plugin_install"
        "${plugin_name}_plugin_verify"
        "${plugin_name}_plugin_uninstall"
        "${plugin_name}_plugin_info"
        "${plugin_name}_plugin_get_latest_version"
    )

    for func in "${required_functions[@]}"; do
        if ! command -v "$func" >/dev/null 2>&1; then
            log_error "Missing required function: $func"
            return 1
        fi
    done

    return 0
}

# Execute plugin function with error handling
execute_plugin_function() {
    local plugin_name="$1"
    local function="$2"
    shift 2

    local full_function="${plugin_name}_${function}"

    if command -v "$full_function" >/dev/null 2>&1; then
        "$full_function" "$@"
        return $?
    else
        log_error "Plugin function not found: $full_function"
        return 1
    fi
}

# Get plugin information
get_plugin_info() {
    local plugin_name="$1"

    if [ -z "${PLUGINS[$plugin_name]:-}" ]; then
        log_error "Plugin not found: $plugin_name"
        return 1
    fi

    execute_plugin_function "$plugin_name" "info"
}

# Detect if plugin tool is installed
detect_plugin_tool() {
    local plugin_name="$1"

    if [ -z "${PLUGINS[$plugin_name]:-}" ]; then
        return 1
    fi

    execute_plugin_function "$plugin_name" "plugin_detect"
}

# Get plugin dependencies
get_plugin_dependencies() {
    local plugin_name="$1"

    if [ -z "${PLUGINS[$plugin_name]:-}" ]; then
        log_error "Plugin not found: $plugin_name"
        return 1
    fi

    execute_plugin_function "$plugin_name" "dependencies"
}

# Install plugin tool
install_plugin_tool() {
    local plugin_name="$1"
    local force="${2:-false}"
    local version="${3:-}"

    if [ -z "${PLUGINS[$plugin_name]:-}" ]; then
        log_error "Plugin not found: $plugin_name"
        return 1
    fi

    # Check if already installed (unless force mode)
    if [ "$force" != "true" ] && detect_plugin_tool "$plugin_name"; then
        local installed_version
        installed_version=$(execute_plugin_function "$plugin_name" "plugin_version")
        log_info "✅ $plugin_name already installed (version: $installed_version) — skipping (use --force to reinstall)"
        return 0
    fi

    # Resolve version if not provided or is 'latest'
    if [ -z "$version" ] || [ "$version" = "latest" ]; then
        log_info "Resolving latest version for $plugin_name..."
        version=$(execute_plugin_function "$plugin_name" "plugin_get_latest_version")
        if [ -z "$version" ]; then
            log_error "Failed to resolve latest version for $plugin_name"
            return 1
        fi
        log_info "Latest version for $plugin_name is $version"
    fi

    # Install system dependencies first
    local dependencies
    dependencies=$(get_plugin_dependencies "$plugin_name")

    if [ -n "$dependencies" ]; then
        log_info "Installing system dependencies for $plugin_name: $dependencies"
        if ! install_system_packages $dependencies; then
            log_error "Failed to install system dependencies for $plugin_name"
            return 1
        fi
    fi

    # Install tool
    log_info "Installing $plugin_name version $version..."
    PLUGIN_STATES["$plugin_name"]="installing"

    if execute_plugin_function "$plugin_name" "install" "$version"; then
        # Verify installation
        if execute_plugin_function "$plugin_name" "plugin_verify"; then
            PLUGIN_STATES["$plugin_name"]="installed"
            local installed_version
            installed_version=$(execute_plugin_function "$plugin_name" "plugin_version")
            log_success "✅ $plugin_name successfully installed (version: $installed_version)"
            return 0
        else
            PLUGIN_STATES["$plugin_name"]="failed"
            log_error "❌ $plugin_name installation verification failed"
            return 1
        fi
    else
        PLUGIN_STATES["$plugin_name"]="failed"
        log_error "❌ $plugin_name installation failed"
        return 1
    fi
}

# Uninstall plugin tool
uninstall_plugin_tool() {
    local plugin_name="$1"

    if [ -z "${PLUGINS[$plugin_name]:-}" ]; then
        log_error "Plugin not found: $plugin_name"
        return 1
    fi

    log_info "Uninstalling $plugin_name..."
    PLUGIN_STATES["$plugin_name"]="uninstalling"

    if execute_plugin_function "$plugin_name" "uninstall"; then
        PLUGIN_STATES["$plugin_name"]="uninstalled"
        log_success "✅ $plugin_name successfully uninstalled"
        return 0
    else
        PLUGIN_STATES["$plugin_name"]="failed"
        log_error "❌ $plugin_name uninstallation failed"
        return 1
    fi
}

# Get list of available plugins
get_available_plugins() {
    echo "${!PLUGINS[@]}"
}

# Get plugin state
get_plugin_state() {
    local plugin_name="$1"
    echo "${PLUGIN_STATES[$plugin_name]:-unknown}"
}

# Check if plugin is available
is_plugin_available() {
    local plugin_name="$1"
    [ -n "${PLUGINS[$plugin_name]:-}" ]
}

# Install system packages (helper function)
install_system_packages() {
    local packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi

    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "System package installation requires root privileges"
        return 1
    fi

    log_debug "Installing system packages: ${packages[*]}"

    # Update package list
    if ! apt-get update -qq; then
        log_error "Failed to update package list"
        return 1
    fi

    # Install packages
    if DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${packages[@]}"; then
        log_debug "Successfully installed system packages"
        return 0
    else
        log_error "Failed to install system packages: ${packages[*]}"
        return 1
    fi
}

# Initialize plugin manager
init_plugin_manager() {
    log_debug "Initializing plugin manager"
    load_plugins
    log_debug "Plugin manager initialized with ${#PLUGINS[@]} plugins"
}

# Export plugin manager functions and variables
export PLUGINS PLUGIN_STATES