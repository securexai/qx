#!/bin/bash

# Utility functions for QX installation script

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if file exists and is executable
executable_exists() {
    [ -x "$1" ]
}

# Create directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        log_debug "Created directory: $dir"
    fi
}

# Get absolute path
get_absolute_path() {
    local path="$1"
    if [ -d "$path" ]; then
        (cd "$path" && pwd)
    else
        echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
    fi
}

# Check if array contains element
array_contains() {
    local element="$1"
    shift
    local array=("$@")

    for item in "${array[@]}"; do
        if [ "$item" = "$element" ]; then
            return 0
        fi
    done
    return 1
}

# Get file size in human readable format
get_file_size() {
    local file="$1"
    if [ -f "$file" ]; then
        local size
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        if command_exists numfmt; then
            numfmt --to=iec-i --suffix=B "$size"
        else
            echo "${size}B"
        fi
    else
        echo "N/A"
    fi
}

# Generate temporary file with proper cleanup
create_temp_file() {
    local prefix="${1:-qx}"
    local temp_file
    temp_file=$(mktemp -t "${prefix}.XXXXXX")
    chmod 600 "$temp_file"

    # Add to cleanup list
    TEMP_FILES+=("$temp_file")

    echo "$temp_file"
}

# Cleanup temporary files
cleanup_temp_files() {
    for file in "${TEMP_FILES[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
            log_debug "Cleaned up temporary file: $file"
        fi
    done
    TEMP_FILES=()
}

# Set up signal handlers for cleanup
setup_signal_handlers() {
    trap cleanup_temp_files EXIT INT TERM HUP
}

# Check if running in dry-run mode
is_dry_run() {
    [ "${DRY_RUN:-false}" = "true" ]
}

# Check if force mode is enabled
is_force_mode() {
    [ "${FORCE_MODE:-false}" = "true" ]
}

# Validate version string
validate_version() {
    local version="$1"
    local pattern="^[0-9]+\.[0-9]+(\.[0-9]+)?(-[a-zA-Z0-9.-]+)?$"

    if [[ $version =~ $pattern ]]; then
        return 0
    else
        return 1
    fi
}

# Compare versions (simple implementation)
version_compare() {
    local version1="$1"
    local operator="$2"
    local version2="$3"

    # Simple version comparison using sort
    local result
    result=$(printf '%s\n%s\n' "$version1" "$version2" | sort -V | head -n1)

    case "$operator" in
        "eq"| "=")
            [ "$version1" = "$version2" ]
            ;;
        "ne"| "!=")
            [ "$version1" != "$version2" ]
            ;;
        "gt"| ">")
            [ "$result" != "$version1" ]
            ;;
        "ge"| ">=")
            [ "$result" = "$version1" ] || [ "$version1" = "$version2" ]
            ;;
        "lt"| "<")
            [ "$result" = "$version1" ] && [ "$version1" != "$version2" ]
            ;;
        "le"| "<=")
            [ "$result" = "$version1" ]
            ;;
        *)
            log_error "Unknown operator: $operator"
            return 1
            ;;
    esac
}

# URL encode string
url_encode() {
    local string="$1"
    local encoded=""

    for ((i=0; i<${#string}; i++)); do
        local char="${string:i:1}"
        case "$char" in
            [a-zA-Z0-9.~_-])
                encoded+="$char"
                ;;
            *)
                printf -v encoded '%s%%%02X' "$encoded" "'$char"
                ;;
        esac
    done

    echo "$encoded"
}

# Generate random string
generate_random_string() {
    local length="${1:-32}"
    local chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    local result=""
    for ((i=0; i<length; i++)); do
        result+=${chars:RANDOM%${#chars}:1}
    done

    echo "$result"
}

# Check if port is available
check_port() {
    local port="$1"
    local host="${2:-localhost}"

    if command_exists nc; then
        nc -z "$host" "$port" >/dev/null 2>&1
        return $?
    elif command_exists ss; then
        ss -ln | grep -q ":$port "
        return $?
    else
        # Fallback to lsof if available
        if command_exists lsof; then
            lsof -i :"$port" >/dev/null 2>&1
            return $?
        fi
    fi

    # If no tools available, assume port is available
    return 1
}

# Initialize utility module
init_utils() {
    # Initialize temporary files array
    TEMP_FILES=()

    # Set up signal handlers
    setup_signal_handlers

    log_debug "Utility functions initialized"
}

# Export utility functions
export TEMP_FILES