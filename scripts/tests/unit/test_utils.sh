#!/bin/bash

# Unit tests for utility functions
source "$(dirname "$0")/../../lib/utils.sh"
source "$(dirname "$0")/../framework.sh"

test_command_exists() {
    # Test existing command
    assert "command_exists 'ls'"
    assert "command_exists 'bash'"

    # Test non-existing command
    assert_failure "command_exists 'nonexistent_command_12345'"
}

test_executable_exists() {
    # Test existing executable
    assert "executable_exists '/bin/ls'"
    assert "executable_exists '/bin/bash'"

    # Test non-existing file
    assert_failure "executable_exists '/nonexistent/file'"
}

test_ensure_dir() {
    local test_dir="$TEST_TMP_DIR/test_dir"

    # Directory should not exist initially
    assert_failure "[ -d '$test_dir' ]"

    # Create directory
    ensure_dir "$test_dir"

    # Directory should now exist
    assert "[ -d '$test_dir' ]"
}

test_get_absolute_path() {
    local test_file="$TEST_TMP_DIR/test.txt"
    echo "test" > "$test_file"

    # Test absolute path of existing file
    local abs_path
    abs_path=$(get_absolute_path "$test_file")
    assert "[ '$abs_path' = '$test_file' ]"

    # Test relative path
    cd "$TEST_TMP_DIR"
    abs_path=$(get_absolute_path "test.txt")
    assert "[ '$abs_path' = '$test_file' ]"
}

test_array_contains() {
    local test_array=("apple" "banana" "cherry")

    # Test existing elements
    assert "array_contains 'apple' '${test_array[*]}'"
    assert "array_contains 'banana' '${test_array[*]}'"
    assert "array_contains 'cherry' '${test_array[*]}'"

    # Test non-existing element
    assert_failure "array_contains 'orange' '${test_array[*]}'"
}

test_validate_version() {
    # Test valid versions
    assert "validate_version '1.0.0'"
    assert "validate_version '2.1.3'"
    assert "validate_version '1.0'"
    assert "validate_version '1.0.0-alpha'"

    # Test invalid versions
    assert_failure "validate_version '1'"
    assert_failure "validate_version '1.0.0.0'"
    assert_failure "validate_version 'abc'"
    assert_failure "validate_version ''"
}

test_version_compare() {
    # Test equality
    assert "version_compare '1.0.0' '=' '1.0.0'"
    assert "version_compare '2.1.0' 'eq' '2.1.0'"

    # Test greater than
    assert "version_compare '2.0.0' '>' '1.9.9'"
    assert "version_compare '1.1.0' 'gt' '1.0.9'"

    # Test less than
    assert "version_compare '1.0.0' '<' '1.0.1'"
    assert "version_compare '2.0.0' 'lt' '2.1.0'"

    # Test greater than or equal
    assert "version_compare '1.0.0' '>=' '1.0.0'"
    assert "version_compare '1.1.0' 'ge' '1.0.0'"

    # Test less than or equal
    assert "version_compare '1.0.0' '<=' '1.0.0'"
    assert "version_compare '1.0.0' 'le' '1.1.0'"
}

test_url_encode() {
    # Test simple string
    local encoded
    encoded=$(url_encode "hello world")
    assert_equal "hello%20world" "$encoded"

    # Test special characters
    encoded=$(url_encode "test@example.com")
    assert_equal "test%40example.com" "$encoded"

    # Test already encoded characters
    encoded=$(url_encode "test-_.~")
    assert_equal "test-_.~" "$encoded"
}

test_generate_random_string() {
    # Test default length (32)
    local str1
    str1=$(generate_random_string)
    assert_equal 32 "${#str1}"

    # Test custom length
    local str2
    str2=$(generate_random_string 16)
    assert_equal 16 "${#str2}"

    # Test that strings are different
    assert_not_equal "$str1" "$str2"

    # Test that strings contain only valid characters
    assert_success "echo '$str1' | grep -E '^[a-zA-Z0-9]+$'"
}

test_is_dry_run() {
    # Test default (should be false)
    assert_failure "is_dry_run"

    # Test when set to true
    DRY_RUN=true
    assert "is_dry_run"

    # Reset
    DRY_RUN=false
}

test_is_force_mode() {
    # Test default (should be false)
    assert_failure "is_force_mode"

    # Test when set to true
    FORCE_MODE=true
    assert "is_force_mode"

    # Reset
    FORCE_MODE=false
}