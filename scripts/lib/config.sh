#!/bin/bash

# Configuration management module for QX installation script
# Supports YAML configuration files with fallback defaults

# Configuration variables
declare -A CONFIG_CACHE
CONFIG_DIR="${CONFIG_DIR:-$(dirname "$0")/../config}"
CONFIG_FILE="${CONFIG_FILE:-default.yaml}"

# Default configuration values
declare -A DEFAULT_CONFIG=(
    # Global settings
    ["global.log_level"]="info"
    ["global.log_file"]=""
    ["global.cache_dir"]="/var/cache/qx-install"
    ["global.temp_dir"]="/tmp/qx-install"
    ["global.parallel_downloads"]="3"
    ["global.download_timeout"]="300"
    ["global.retry_attempts"]="3"
    ["global.retry_delay"]="2"

    # Platform requirements
    ["platform.min_ubuntu_version"]="24.04"
    ["platform.architectures"]="x86_64"
    ["platform.required_system_packages"]="curl ca-certificates unzip bc"

    # Security settings
    ["security.verify_checksums"]="true"
    ["security.require_https"]="true"
    ["security.allow_insecure_downloads"]="false"
    ["security.temp_file_permissions"]="600"

    # UI settings
    ["ui.show_progress"]="true"
    ["ui.show_summary"]="true"
    ["ui.interactive_mode"]="false"
    ["ui.color_output"]="true"

    # Tool versions
    ["tools.bun.version"]="1.2.23"
    ["tools.bun.install_path"]="/usr/local"
    ["tools.podman.version"]="4.9.4"
    ["tools.kubectl.version"]="1.30.0"
    ["tools.kind.version"]="0.30.0"
)

# Load YAML configuration file
load_yaml_config() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        log_warn "Configuration file not found: $config_file"
        return 1
    fi

    log_debug "Loading configuration from: $config_file"

    # Simple YAML parser (basic implementation)
    local current_section=""
    local -a yaml_lines

    # Read file line by line
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ $line =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Remove leading/trailing whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Check for section headers (lines ending with ':')
        if [[ $line =~ ^[a-zA-Z_][a-zA-Z0-9_]*:$ ]]; then
            current_section="${line%:}"
            continue
        fi

        # Parse key-value pairs
        if [[ $line =~ ^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*(.+)$ ]]; then
            local key="${BASH_REMATCH[1]%%:*}"
            local value="${BASH_REMATCH[1]#*:}"

            # Remove quotes if present
            value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/;s/^'\''\(.*\)'\''$/\1/')

            # Build full key path
            local full_key="$current_section.$key"
            if [ -n "$current_section" ]; then
                full_key="$current_section.$key"
            else
                full_key="$key"
            fi

            CONFIG_CACHE["$full_key"]="$value"
            log_debug "Loaded config: $full_key = $value"
        fi
    done < "$config_file"

    return 0
}

# Get configuration value with fallback to defaults
get_config_value() {
    local key="$1"
    local default_value="${2:-}"

    # Check cache first
    if [ -n "${CONFIG_CACHE[$key]:-}" ]; then
        echo "${CONFIG_CACHE[$key]}"
        return 0
    fi

    # Check defaults
    if [ -n "${DEFAULT_CONFIG[$key]:-}" ]; then
        echo "${DEFAULT_CONFIG[$key]}"
        return 0
    fi

    # Return provided default or empty string
    echo "$default_value"
}

# Set configuration value
set_config_value() {
    local key="$1"
    local value="$2"

    CONFIG_CACHE["$key"]="$value"
    log_debug "Set config: $key = $value"
}

# Check if configuration key exists
config_key_exists() {
    local key="$1"

    [ -n "${CONFIG_CACHE[$key]:-}" ] || [ -n "${DEFAULT_CONFIG[$key]:-}" ]
}

# Get all configuration keys matching pattern
get_config_keys() {
    local pattern="$1"
    local -a matching_keys=()

    # Check cache
    for key in "${!CONFIG_CACHE[@]}"; do
        if [[ $key =~ $pattern ]]; then
            matching_keys+=("$key")
        fi
    done

    # Check defaults
    for key in "${!DEFAULT_CONFIG[@]}"; do
        if [[ $key =~ $pattern ]] && ! array_contains "$key" "${matching_keys[@]}"; then
            matching_keys+=("$key")
        fi
    done

    echo "${matching_keys[@]}"
}

# Validate configuration
validate_config() {
    local errors=()

    log_info "Validating configuration..."

    # Validate log level
    local log_level
    log_level=$(get_config_value "global.log_level")
    case "$log_level" in
        debug|info|warn|error)
            ;;
        *)
            errors+=("Invalid log_level: $log_level (must be debug, info, warn, or error)")
            ;;
    esac

    # Validate parallel downloads
    local parallel_downloads
    parallel_downloads=$(get_config_value "global.parallel_downloads")
    if ! [[ $parallel_downloads =~ ^[1-9][0-9]*$ ]]; then
        errors+=("Invalid parallel_downloads: $parallel_downloads (must be positive integer)")
    fi

    # Validate timeout
    local timeout
    timeout=$(get_config_value "global.download_timeout")
    if ! [[ $timeout =~ ^[1-9][0-9]*$ ]]; then
        errors+=("Invalid download_timeout: $timeout (must be positive integer)")
    fi

    # Validate retry attempts
    local retry_attempts
    retry_attempts=$(get_config_value "global.retry_attempts")
    if ! [[ $retry_attempts =~ ^[0-9]+$ ]]; then
        errors+=("Invalid retry_attempts: $retry_attempts (must be non-negative integer)")
    fi

    # Validate boolean values
    local boolean_keys=("security.verify_checksums" "security.require_https" "security.allow_insecure_downloads" "ui.show_progress" "ui.show_summary" "ui.interactive_mode" "ui.color_output")
    for key in "${boolean_keys[@]}"; do
        local value
        value=$(get_config_value "$key")
        if [[ ! $value =~ ^(true|false)$ ]]; then
            errors+=("Invalid boolean value for $key: $value (must be true or false)")
        fi
    done

    # Report errors
    if [ ${#errors[@]} -gt 0 ]; then
        log_error "Configuration validation failed:"
        for error in "${errors[@]}"; do
            log_error "  - $error"
        done
        return 1
    else
        log_success "Configuration validation passed"
        return 0
    fi
}

# Initialize configuration system
init_config() {
    local config_file="${CONFIG_DIR}/${CONFIG_FILE}"

    log_debug "Initializing configuration system"
    log_debug "Config directory: $CONFIG_DIR"
    log_debug "Config file: $config_file"

    # Load configuration file if it exists
    if [ -f "$config_file" ]; then
        if ! load_yaml_config "$config_file"; then
            log_warn "Failed to load configuration file, using defaults"
        fi
    else
        log_debug "Configuration file not found, using defaults"
    fi

    # Validate configuration
    if ! validate_config; then
        log_error "Configuration validation failed"
        return 1
    fi

    log_debug "Configuration system initialized"
    return 0
}

# Get tool version from channel
get_tool_version_from_channel() {
    local tool_name="$1"
    local channel="$2"

    get_config_value "channels.$channel.$tool_name"
}

# Export configuration functions
export CONFIG_CACHE CONFIG_DIR CONFIG_FILE