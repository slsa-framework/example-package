#!/bin/bash

source "./.github/workflows/scripts/assert.sh"

exit_if_fail() {
    local actual="$1"
    if [ "$actual" != "0" ]; then
        exit 1
    fi
}

go env -w GOFLAGS=-mod=mod

# Install from HEAD
go install github.com/slsa-framework/slsa-verifier@latest
    
# Default parameters.
RES=$(slsa-verifier --artifact-path $BINARY --provenance $PROVENANCE --source github.com/$GITHUB_REPOSITORY)
assert_eq "$RES" "0" "default parameters"
exit_if_fail "$?"

# Main branch
RES=$(slsa-verifier --branch main --artifact-path $BINARY --provenance $PROVENANCE --source github.com/$GITHUB_REPOSITORY)
assert_eq "$RES" "0" "main branch"
exit_if_fail "$?"

# Wrong branch
RES=$(slsa-verifier --branch not-main --artifact-path $BINARY --provenance $PROVENANCE --source github.com/$GITHUB_REPOSITORY)
assert_not_eq "$RES" "0" "wrong branch"
exit_if_fail "$?"

# Wrong tag
RES=$(slsa-verifier --tag v1.2.3 --artifact-path $BINARY --provenance $PROVENANCE --source github.com/$GITHUB_REPOSITORY)
assert_not_eq "$RES" "0" "wrong tag"
exit_if_fail "$?"

# Wrong versioned-tag
RES=$(slsa-verifier --versioned-tag v1.2.3 --artifact-path $BINARY --provenance $PROVENANCE --source github.com/$GITHUB_REPOSITORY)
assert_not_eq "$RES" "0" "wrong versioned-tag"
exit_if_fail "$?"

#TODO: read out the provenance information once we print it
#TODO: previous releases, curl the $BINARY directly. We should list the releases and run all commands automatically
