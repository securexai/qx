#!/bin/bash

# Rollback functionality for QX installation script
# Provides ability to undo installations and restore system state
#
# Description:
# This module implements comprehensive rollback capabilities for the QX installation script.
# It tracks all installation actions and provides automatic or manual rollback functionality
# to restore the system to its previous state in case of installation failures.
#
# Key Features:
# - Automatic rollback on installation failures
# - Manual rollback execution
# - State persistence to disk
# - Support for package removal, file restoration, and custom commands
# - Comprehensive rollback action tracking
#
# Rollback Actions Supported:
# - remove_package: Uninstall system packages
# - remove_file: Remove installed files and restore backups
# - restore_file: Restore modified files from backups
# - run_command: Execute custom rollback commands
#
# Usage:
# The rollback system is automatically initialized during installation and tracks
# all changes. On failure, perform_rollback() can be called to undo all recorded actions.

# Rollback state tracking
declare -A ROLLBACK_ACTIONS
declare -A INSTALLED_PACKAGES
declare -A INSTALLED_FILES
declare -A MODIFIED_FILES

# Initialize rollback system
init_rollback() {
    log_debug "Initializing rollback system"
    ROLLBACK_ACTIONS=()
    INSTALLED_PACKAGES=()
    INSTALLED_FILES=()
    MODIFIED_FILES=()
}

# Register a rollback action
register_rollback_action() {
    local action_id="$1"
    local action_type="$2"
    local action_data="$3"

    ROLLBACK_ACTIONS["$action_id"]="$action_type:$action_data"
    log_debug "Registered rollback action: $action_id ($action_type)"
}

# Record package installation for rollback
record_package_installation() {
    local package_name="$1"
    local timestamp
    timestamp=$(date +%s)

    INSTALLED_PACKAGES["$package_name"]="$timestamp"
    register_rollback_action "pkg_$package_name" "remove_package" "$package_name"
}

# Record file installation for rollback
record_file_installation() {
    local file_path="$1"
    local backup_path="${2:-}"

    if [ -z "$backup_path" ]; then
        # Create backup if file exists
        if [ -f "$file_path" ]; then
            backup_path=$(create_temp_file "backup")
            cp "$file_path" "$backup_path"
            log_debug "Created backup of $file_path to $backup_path"
        fi
    fi

    INSTALLED_FILES["$file_path"]="$backup_path"
    register_rollback_action "file_$file_path" "remove_file" "$file_path:$backup_path"
}

# Record file modification for rollback
record_file_modification() {
    local file_path="$1"
    local backup_path

    # Create backup of original file
    backup_path=$(create_temp_file "backup")
    if [ -f "$file_path" ]; then
        cp "$file_path" "$backup_path"
        log_debug "Created backup of modified file $file_path to $backup_path"
    fi

    MODIFIED_FILES["$file_path"]="$backup_path"
    register_rollback_action "mod_$file_path" "restore_file" "$file_path:$backup_path"
}

# Execute rollback action
execute_rollback_action() {
    local action_id="$1"
    local action_data="${ROLLBACK_ACTIONS[$action_id]}"

    if [ -z "$action_data" ]; then
        log_error "Rollback action not found: $action_id"
        return 1
    fi

    local action_type="${action_data%%:*}"
    local action_params="${action_data#*:}"

    log_debug "Executing rollback action: $action_id ($action_type)"

    case "$action_type" in
        remove_package)
            rollback_remove_package "$action_params"
            ;;
        remove_file)
            rollback_remove_file "$action_params"
            ;;
        restore_file)
            rollback_restore_file "$action_params"
            ;;
        run_command)
            rollback_run_command "$action_params"
            ;;
        *)
            log_error "Unknown rollback action type: $action_type"
            return 1
            ;;
    esac
}

# Rollback: Remove installed package
rollback_remove_package() {
    local package_name="$1"

    log_info "Rolling back package installation: $package_name"

    if [ "$EUID" -ne 0 ]; then
        log_error "Package removal requires root privileges"
        return 1
    fi

    if apt-get remove -y -qq "$package_name"; then
        # Remove any automatically installed dependencies
        apt-get autoremove -y -qq >/dev/null 2>&1 || true
        log_success "Successfully removed package: $package_name"
        return 0
    else
        log_error "Failed to remove package: $package_name"
        return 1
    fi
}

# Rollback: Remove installed file
rollback_remove_file() {
    local params="$1"
    local file_path="${params%%:*}"
    local backup_path="${params#*:}"

    log_info "Rolling back file installation: $file_path"

    # Remove the installed file
    if [ -f "$file_path" ]; then
        rm -f "$file_path"
        log_success "Removed installed file: $file_path"
    fi

    # Restore backup if it exists
    if [ -n "$backup_path" ] && [ -f "$backup_path" ]; then
        mv "$backup_path" "$file_path"
        log_success "Restored backup file: $file_path"
    fi

    return 0
}

# Rollback: Restore modified file
rollback_restore_file() {
    local params="$1"
    local file_path="${params%%:*}"
    local backup_path="${params#*:}"

    log_info "Rolling back file modification: $file_path"

    # Remove the modified file
    if [ -f "$file_path" ]; then
        rm -f "$file_path"
    fi

    # Restore backup if it exists
    if [ -n "$backup_path" ] && [ -f "$backup_path" ]; then
        mv "$backup_path" "$file_path"
        log_success "Restored original file: $file_path"
        return 0
    else
        log_warn "No backup available for: $file_path"
        return 1
    fi
}

# Rollback: Run custom command
rollback_run_command() {
    local command="$1"

    log_info "Running rollback command: $command"

    if eval "$command"; then
        log_success "Rollback command executed successfully"
        return 0
    else
        log_error "Rollback command failed: $command"
        return 1
    fi
}

# Perform full rollback
perform_rollback() {
    local failed_actions=()

    log_warn "Starting rollback of all recorded actions..."

    # Execute rollback actions in reverse order
    for action_id in "${!ROLLBACK_ACTIONS[@]}"; do
        log_info "Rolling back: $action_id"
        if ! execute_rollback_action "$action_id"; then
            failed_actions+=("$action_id")
        fi
    done

    # Clean up rollback data
    ROLLBACK_ACTIONS=()
    INSTALLED_PACKAGES=()
    INSTALLED_FILES=()
    MODIFIED_FILES=()

    if [ ${#failed_actions[@]} -eq 0 ]; then
        log_success "Rollback completed successfully"
        return 0
    else
        log_error "Rollback completed with failures: ${failed_actions[*]}"
        return 1
    fi
}

# Save rollback state to file
save_rollback_state() {
    local state_file="$1"

    log_debug "Saving rollback state to: $state_file"

    {
        echo "# QX Installation Rollback State"
        echo "# Generated on: $(date)"
        echo ""

        echo "# Installed packages"
        for pkg in "${!INSTALLED_PACKAGES[@]}"; do
            echo "INSTALLED_PACKAGE:$pkg:${INSTALLED_PACKAGES[$pkg]}"
        done

        echo ""
        echo "# Installed files"
        for file in "${!INSTALLED_FILES[@]}"; do
            echo "INSTALLED_FILE:$file:${INSTALLED_FILES[$file]}"
        done

        echo ""
        echo "# Modified files"
        for file in "${!MODIFIED_FILES[@]}"; do
            echo "MODIFIED_FILE:$file:${MODIFIED_FILES[$file]}"
        done

        echo ""
        echo "# Rollback actions"
        for action in "${!ROLLBACK_ACTIONS[@]}"; do
            echo "ROLLBACK_ACTION:$action:${ROLLBACK_ACTIONS[$action]}"
        done

    } > "$state_file"

    log_debug "Rollback state saved"
}

# Load rollback state from file
load_rollback_state() {
    local state_file="$1"

    if [ ! -f "$state_file" ]; then
        log_error "Rollback state file not found: $state_file"
        return 1
    fi

    log_debug "Loading rollback state from: $state_file"

    while IFS=: read -r type key value extra; do
        case "$type" in
            INSTALLED_PACKAGE)
                INSTALLED_PACKAGES["$key"]="$value"
                ;;
            INSTALLED_FILE)
                INSTALLED_FILES["$key"]="$value"
                ;;
            MODIFIED_FILE)
                MODIFIED_FILES["$key"]="$value"
                ;;
            ROLLBACK_ACTION)
                ROLLBACK_ACTIONS["$key"]="$value:$extra"
                ;;
            \#*)
                # Skip comments
                ;;
            "")
                # Skip empty lines
                ;;
            *)
                log_warn "Unknown rollback state entry: $type"
                ;;
        esac
    done < "$state_file"

    log_debug "Rollback state loaded"
}

# Check if rollback is possible
can_rollback() {
    [ ${#ROLLBACK_ACTIONS[@]} -gt 0 ]
}

# Get rollback summary
get_rollback_summary() {
    cat << EOF
Rollback Summary:
================
Packages to remove: ${#INSTALLED_PACKAGES[@]}
Files to remove/restore: $((${#INSTALLED_FILES[@]} + ${#MODIFIED_FILES[@]}))
Rollback actions: ${#ROLLBACK_ACTIONS[@]}

Installed packages: ${!INSTALLED_PACKAGES[*]:-none}
Modified files: ${!MODIFIED_FILES[*]:-none}
EOF
}

# Export rollback functions
export ROLLBACK_ACTIONS INSTALLED_PACKAGES INSTALLED_FILES MODIFIED_FILES