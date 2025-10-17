#!/bin/bash

# Integration tests for dry-run functionality
source "$(dirname "$0")/../framework.sh"

test_dry_run_minimal_profile() {
    # Test dry-run with minimal profile
    local output
    output=$("$SCRIPT_DIR/install-prereqs.sh" --dry-run --profile minimal 2>&1)

    # Should contain dry-run indicators
    assert_success "echo '$output' | grep -q 'minimal'"
    assert_success "echo '$output' | grep -q 'bun'"
    assert_success "echo '$output' | grep -q 'Dry run completed'"

    # Should not contain actual installation messages
    assert_failure "echo '$output' | grep -q 'downloading'"
    assert_failure "echo '$output' | grep -q 'installing'"
}

test_dry_run_development_profile() {
    # Test dry-run with development profile
    local output
    output=$("$SCRIPT_DIR/install-prereqs.sh" --dry-run --profile development 2>&1)

    # Should contain development profile indicators
    assert_success "echo '$output' | grep -q 'development'"
    assert_success "echo '$output' | grep -q 'bun'"
    assert_success "echo '$output' | grep -q 'kubectl'"
    assert_success "echo '$output' | grep -q 'kind'"
    assert_success "echo '$output' | grep -q 'Dry run completed'"
}

test_dry_run_full_profile() {
    # Test dry-run with full profile
    local output
    output=$("$SCRIPT_DIR/install-prereqs.sh" --dry-run --profile full 2>&1)

    # Should contain all tools
    assert_success "echo '$output' | grep -q 'full'"
    assert_success "echo '$output' | grep -q 'bun'"
    assert_success "echo '$output' | grep -q 'podman'"
    assert_success "echo '$output' | grep -q 'kubectl'"
    assert_success "echo '$output' | grep -q 'kind'"
    assert_success "echo '$output' | grep -q 'Dry run completed'"
}

test_dry_run_specific_tools() {
    # Test dry-run with specific tools
    local output
    output=$("$SCRIPT_DIR/install-prereqs.sh" --dry-run --tools bun,kubectl 2>&1)

    # Should contain specified tools
    assert_success "echo '$output' | grep -q 'bun'"
    assert_success "echo '$output' | grep -q 'kubectl'"
    assert_success "echo '$output' | grep -q 'Dry run completed'"

    # Should not contain other tools
    assert_failure "echo '$output' | grep -q 'podman'"
    assert_failure "echo '$output' | grep -q 'kind'"
}

test_dry_run_force_mode() {
    # Test dry-run with force mode
    local output
    output=$("$SCRIPT_DIR/install-prereqs.sh" --dry-run --force --profile minimal 2>&1)

    # Should show force mode in plan
    assert_success "echo '$output' | grep -q 'Force mode: true'"
    assert_success "echo '$output' | grep -q 'Would install: bun'"
    assert_success "echo '$output' | grep -q 'Dry run completed'"
}

test_dry_run_quiet_mode() {
    # Test dry-run with quiet mode
    local output
    output=$("$SCRIPT_DIR/install-prereqs.sh" --quiet --dry-run --profile minimal 2>&1)

    # Should have minimal output (only errors if any)
    # In quiet mode, successful dry-run should produce very little output
    assert_success "echo '$output' | grep -q 'minimal'"
}

test_dry_run_with_logging() {
    # Test dry-run with file logging
    local log_file="$TEST_TMP_DIR/test.log"
    local output
    output=$("$SCRIPT_DIR/install-prereqs.sh" --dry-run --log-file "$log_file" --profile minimal 2>&1)

    # Log file should exist and contain log entries
    assert_exists "$log_file"
    assert_success "grep -q 'INFO' '$log_file'"
    assert_success "grep -q 'minimal' '$log_file'"
    assert_success "grep -q 'Dry run completed' '$log_file'"
}