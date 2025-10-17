#!/bin/bash

# Integration tests for rollback functionality
source "/workspace/scripts/tests/framework.sh"

test_automatic_rollback_on_failure() {
    # Test that rollback is triggered automatically on installation failure
    local output
    output=$(bash -c 'set -x; source "$SCRIPT_DIR/lib/utils.sh"; source "$SCRIPT_DIR/lib/logger.sh"; source "$SCRIPT_DIR/lib/config.sh"; source "$SCRIPT_DIR/lib/rollback.sh"; function perform_rollback() { echo "Rollback triggered"; }; export -f perform_rollback; bash "$SCRIPT_DIR/install-prereqs.sh" --profile minimal --tools non_existent_tool' 2>&1)

    # Should contain rollback trigger message
    assert_success "echo \"$output\" | grep -q 'Rollback triggered'"
}
