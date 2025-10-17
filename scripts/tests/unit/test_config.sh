#!/bin/bash

# Unit tests for configuration system
# Source the script to be tested and the framework
source "$(dirname "$0")/../../lib/utils.sh"
source "$(dirname "$0")/../../lib/logger.sh"
source "$(dirname "$0")/../../lib/config.sh"
source "$(dirname "$0")/../framework.sh"

# --- Test Cases ---

test_get_default_values() {
    # Test getting values that should exist in the default map
    local val
    val=$(get_config_value "platform.min_ubuntu_version" "default")
    assert_equal "24.04" "$val" "Should retrieve min_ubuntu_version from defaults"

    val=$(get_config_value "security.verify_checksums" "default")
    assert_equal "true" "$val" "Should retrieve verify_checksums from defaults"
}

test_get_fallback_value() {
    # Test the fallback mechanism for a non-existent key
    local val
    val=$(get_config_value "nonexistent.key" "expected_fallback")
    assert_equal "expected_fallback" "$val" "Should return the provided fallback for a nonexistent key"
}

test_set_and_get_value() {
    # Test setting a new value and retrieving it
    set_config_value "new.runtime.value" "is_set"
    local val
    val=$(get_config_value "new.runtime.value")
    assert_equal "is_set" "$val" "Should retrieve a value set at runtime"
}

test_key_existence() {
    # Test if keys exist in default or runtime config
    assert "config_key_exists 'global.log_level'" "Default key 'global.log_level' should exist"
    
    set_config_value "runtime.key" "exists"
    assert "config_key_exists 'runtime.key'" "Runtime key 'runtime.key' should exist"

    assert_failure "config_key_exists 'nonexistent.key'" "A nonexistent key should not exist"
}

test_get_keys_by_pattern() {
    # Test finding keys that match a regex pattern
    set_config_value "platform.custom.setting" "foo"
    local keys
    keys=$(get_config_keys "platform.*")
    
    assert_success "echo '$keys' | grep -q 'platform.min_ubuntu_version'" "Pattern should find default platform keys"
    assert_success "echo '$keys' | grep -q 'platform.custom.setting'" "Pattern should find runtime platform keys"
}

test_comprehensive_validation() {
    # Test various validation scenarios
    init_config
    assert "validate_config" "Initial default config should be valid"

    # Test invalid log level
    set_config_value "global.log_level" "critical"
    assert_failure "validate_config" "Should fail with invalid log_level"
    set_config_value "global.log_level" "info" # Reset

    # Test invalid parallel downloads
    set_config_value "global.parallel_downloads" "zero"
    assert_failure "validate_config" "Should fail with non-integer parallel_downloads"
    set_config_value "global.parallel_downloads" "4" # Reset

    # Test invalid boolean
    set_config_value "ui.color_output" "maybe"
    assert_failure "validate_config" "Should fail with invalid boolean"
    set_config_value "ui.color_output" "true" # Reset

    assert "validate_config" "Config should be valid after resetting values"
}

test_yaml_override_and_parsing() {
    # Create a custom YAML file for this test
    local test_yaml_path="$TEST_TMP_DIR/test.yaml"
    cat > "$test_yaml_path" << 'EOF'
# Test config
global:
  log_level: "warn" # Override default
  new_global: "hello"

# Empty section
empty_section:

tools:
  bun:
    version: "9.9.9" # Override default

channels:
  stable:
    bun: "1.0.0"
  latest:
    bun: "1.1.0"
EOF

    # Point config loader to our test file
    CONFIG_FILE="$test_yaml_path"
    
    # Initialize config, which should load the file
    init_config

    # 1. Test override: global.log_level should be 'warn', not 'info'
    local val
    val=$(get_config_value "global.log_level")
    assert_equal "warn" "$val" "YAML should override default log_level"

    # 2. Test new value: new_global should be loaded
    val=$(get_config_value "global.new_global")
    assert_equal "hello" "$val" "Should load new key from YAML"

    # 3. Test nested override
    val=$(get_config_value "tools.bun.version")
    assert_equal "9.9.9" "$val" "YAML should override nested tool version"

    # 4. Test that default values not in the YAML still exist
    val=$(get_config_value "platform.min_ubuntu_version")
    assert_equal "24.04" "$val" "Should still have access to defaults not in custom YAML"
}

test_get_tool_version() {
    # This test relies on the YAML created in the previous test
    test_yaml_override_and_parsing

    # Test getting version from 'stable' channel
    local version
    version=$(get_tool_version_from_channel "bun" "stable")
    assert_equal "1.0.0" "$version" "Should get bun version for stable channel"

    # Test getting version from 'latest' channel
    version=$(get_tool_version_from_channel "bun" "latest")
    assert_equal "1.1.0" "$version" "Should get bun version for latest channel"

    # Test fallback for non-existent tool
    version=$(get_tool_version_from_channel "nonexistent" "latest")
    assert_equal "" "$version" "Should return empty for a non-existent tool in a channel"
}


# --- Test Suite Runner ---

main() {
    run_test_suite "Configuration System" \
        test_get_default_values \
        test_get_fallback_value \
        test_set_and_get_value \
        test_key_existence \
        test_get_keys_by_pattern \
        test_comprehensive_validation \
        test_yaml_override_and_parsing \
        test_get_tool_version
}

# Execute main function
main
