#!/usr/bin/env bash

source "./.github/workflows/scripts/assert.sh"

e2e_assert_eq() {
    if ! assert_eq "$@"; then
        exit 1
    fi
}

e2e_assert_not_eq() {
    if ! assert_not_eq "$@"; then
        exit 1
    fi
}

assert_command_success() {
    if ! "$@"; then
        log_failure "$*"
        return 1
    fi
    return 0
}

e2e_assert_command_success() {
    if ! assert_command_success "$@"; then
        exit 1
    fi
}

assert_command_failure() {
    if "$@"; then
        log_failure "$*"
        return 1
    fi
    return 0
}

e2e_assert_command_failure() {
    if ! assert_command_failure "$@"; then
        exit 1
    fi
}
