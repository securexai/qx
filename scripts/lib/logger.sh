#!/bin/bash

# Logging system for QX installation script
# Provides structured logging with levels, timestamps, and optional file output

# Logging levels
declare -A LOG_LEVELS=([debug]=0 [info]=1 [warn]=2 [error]=3)
CURRENT_LOG_LEVEL=${LOG_LEVELS[info]}
LOG_FILE=""
COLOR_OUTPUT=true

# Color codes
declare -A COLORS=(
    [debug]='\033[0;36m'    # Cyan
    [info]='\033[0;32m'     # Green
    [warn]='\033[0;33m'     # Yellow
    [error]='\033[0;31m'    # Red
    [reset]='\033[0m'       # Reset
)

# Initialize logging
log_init() {
    local level="${1:-info}"
    local file="${2:-}"

    CURRENT_LOG_LEVEL=${LOG_LEVELS[$level]}
    LOG_FILE="$file"

    if [ -n "$LOG_FILE" ]; then
        mkdir -p "$(dirname "$LOG_FILE")"
        touch "$LOG_FILE"
    fi
}

# Generic logging function
log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Check if we should log this level
    if [ ${LOG_LEVELS[$level]} -lt $CURRENT_LOG_LEVEL ]; then
        return 0
    fi

    # Format message
    local formatted_message
    if [ "$COLOR_OUTPUT" = true ] && [ -t 1 ]; then
        formatted_message="${COLORS[$level]}[${timestamp}] [${level^^}] ${message}${COLORS[reset]}"
    else
        formatted_message="[${timestamp}] [${level^^}] ${message}"
    fi

    # Output to console
    echo -e "$formatted_message"

    # Output to file if configured
    if [ -n "$LOG_FILE" ]; then
        echo "[${timestamp}] [${level^^}] ${message}" >> "$LOG_FILE"
    fi
}

# Convenience functions
log_debug() { log_message "debug" "$@"; }
log_info() { log_message "info" "$@"; }
log_warn() { log_message "warn" "$@"; }
log_error() { log_message "error" "$@"; }

# Progress logging
log_progress() {
    local current="$1"
    local total="$2"
    local message="$3"

    printf "\r[%3d%%] %s" "$percent" "$message"

    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}

# Success logging
log_success() { log_message "info" "✅ $@"; }

# Failure logging
log_failure() { log_message "error" "❌ $@"; }