#!/bin/bash

# Unit tests for configuration system
source "$(dirname "$0")/../../lib/config.sh"
source "$(dirname "$0")/../framework.sh"

test_get_config_value() {
    # Initialize config
    init_config

    # Test getting existing config values
    local log_level
    log_level=$(get_config_value "global.log_level")
    assert_equal "info" "$log_level"

    local ubuntu_version
    ubuntu_version=$(get_config_value "platform.min_ubuntu_version")
    assert_equal "24.04" "$ubuntu_version"

    # Test default fallback
    local nonexistent
    nonexistent=$(get_config_value "nonexistent.key" "default_value")
    assert_equal "default_value" "$nonexistent"
}

test_set_config_value() {
    # Initialize config
    init_config

    # Set a config value
    set_config_value "test.key" "test_value"

    # Verify it was set
    local value
    value=$(get_config_value "test.key")
    assert_equal "test_value" "$value"
}

test_config_key_exists() {
    # Initialize config
    init_config

    # Test existing keys
    assert "config_key_exists 'global.log_level'"
    assert "config_key_exists 'platform.min_ubuntu_version'"

    # Test non-existing key
    assert_failure "config_key_exists 'nonexistent.key'"
}

test_get_config_keys() {
    # Initialize config
    init_config

    # Test getting keys with pattern
    local global_keys
    global_keys=$(get_config_keys "global.*")
    assert_success "echo '$global_keys' | grep -q 'global.log_level'"
    assert_success "echo '$global_keys' | grep -q 'global.cache_dir'"

    # Test platform keys
    local platform_keys
    platform_keys=$(get_config_keys "platform.*")
    assert_success "echo '$platform_keys' | grep -q 'platform.min_ubuntu_version'"
}

test_config_validation() {
    # Initialize config
    init_config

    # Test that validation passes with valid config
    assert "validate_config"

    # Test invalid log level
    set_config_value "global.log_level" "invalid"
    assert_failure "validate_config"

    # Reset to valid value
    set_config_value "global.log_level" "info"
    assert "validate_config"

    # Test invalid parallel downloads
    set_config_value "global.parallel_downloads" "not_a_number"
    assert_failure "validate_config"

    # Reset to valid value
    set_config_value "global.parallel_downloads" "3"
    assert "validate_config"
}

test_yaml_parsing() {
    # Test that YAML parsing works
    init_config

    # Test various data types
    local log_level
    log_level=$(get_config_value "global.log_level")
    assert_equal "info" "$log_level"

    local parallel_downloads
    parallel_downloads=$(get_config_value "global.parallel_downloads")
    assert_equal "3" "$parallel_downloads"

    local verify_checksums
    verify_checksums=$(get_config_value "security.verify_checksums")
    assert_equal "false" "$verify_checksums"

    # Test array parsing
    local architectures
    architectures=$(get_config_value "platform.architectures")
    assert_success "echo '$architectures' | grep -q 'x86_64'"
}

test_config_initialization() {
    # Test that config initialization works
    assert "init_config"

    # Test that required environment variables are set
    assert "[ -n '$CONFIG_DIR' ]"
    assert "[ -d '$CONFIG_DIR' ]"

    # Test that config file exists
    assert "[ -f '$CONFIG_DIR/default.yaml' ]"
}