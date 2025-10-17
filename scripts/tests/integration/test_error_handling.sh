#!/bin/bash

# Integration tests for error handling
source "/workspace/scripts/tests/framework.sh"

test_err_trap_in_subshell() {
    local output
    output=$(bash tests/integration/test_script.sh 2>&1)

    output=$(echo "$output" | tr -d "'")
    assert_equal "ERR trap triggered" "$output"
}
