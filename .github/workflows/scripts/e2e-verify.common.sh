#!/usr/bin/env bash
#
# This file contains tests for common fields of Github Actions provenance.

source "./.github/workflows/scripts/e2e-utils.sh"

# Runs all generic SLSA checks that shouldn't change on a per-builder basis.
# $1: the attestation content
e2e_verify_common_all() {
    e2e_verify_common_builder "$1"
    e2e_verify_common_invocation "$1"
    e2e_verify_common_metadata "$1"
    e2e_verify_common_materials "$1"
}

# Verifies the builder for generic provenance.
# $1: the attestation content
e2e_verify_common_builder() {
    :
}

# Verifies the invocation for generic provenance.
# $1: the attestation content
e2e_verify_common_invocation() {
    # NOTE: We set GITHUB_WORKFLOW to the entryPoint for pull_requests.
    # TODO(github.com/slsa-framework/slsa-github-generator/issues/131): support retrieving entryPoint in pull requests.
    e2e_verify_predicate_invocation_configSource "$1" "{\"uri\":\"git+https://github.com/$GITHUB_REPOSITORY@$GITHUB_REF\",\"digest\":{\"sha1\":\"$GITHUB_SHA\"},\"entryPoint\":\".github/workflows/$(e2e_this_file)\"}"

    e2e_verify_predicate_invocation_environment "$1" "github_actor" "$GITHUB_ACTOR"
    e2e_verify_predicate_invocation_environment "$1" "github_sha1" "$GITHUB_SHA"
    # e2e_verify_predicate_invocation_environment "$1" "os" "ubuntu20"
    # e2e_verify_predicate_invocation_environment "$1" "arch" "X64"
    e2e_verify_predicate_invocation_environment "$1" "github_event_name" "$GITHUB_EVENT_NAME"
    e2e_verify_predicate_invocation_environment "$1" "github_ref" "$GITHUB_REF"
    e2e_verify_predicate_invocation_environment "$1" "github_ref_type" "$GITHUB_REF_TYPE"
    e2e_verify_predicate_invocation_environment "$1" "github_run_id" "$GITHUB_RUN_ID"
    e2e_verify_predicate_invocation_environment "$1" "github_run_number" "$GITHUB_RUN_NUMBER"
    e2e_verify_predicate_invocation_environment "$1" "github_run_attempt" "$GITHUB_RUN_ATTEMPT"
    ACTOR_ID=$(gh api -H "Accept: application/vnd.github.v3+json" /users/"$GITHUB_ACTOR" | jq -r '.id')
    OWNER_ID=$(gh api -H "Accept: application/vnd.github.v3+json" /users/"$GITHUB_REPOSITORY_OWNER" | jq -r '.id')
    REPO_ID=$(gh api -H "Accept: application/vnd.github.v3+json" /repos/"$GITHUB_REPOSITORY" | jq -r '.id')
    e2e_verify_predicate_invocation_environment "$1" "github_actor_id" "$ACTOR_ID"
    e2e_verify_predicate_invocation_environment "$1" "github_repository_owner_id" "$OWNER_ID"
    e2e_verify_predicate_invocation_environment "$1" "github_repository_id" "$REPO_ID"
}

# Verifies the expected metadata.
# $1: the attestation content
e2e_verify_common_metadata() {
    e2e_verify_predicate_metadata "$1" "{\"buildInvocationID\":\"$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT\",\"completeness\":{\"parameters\":true,\"environment\":false,\"materials\":false},\"reproducible\":false}"
}

# Verifies the materials include the GitHub repository.
# $1: the attestation content
e2e_verify_common_materials() {
    e2e_verify_predicate_materials "$1" "{\"uri\":\"git+https://github.com/$GITHUB_REPOSITORY@$GITHUB_REF\",\"digest\":{\"sha1\":\"$GITHUB_SHA\"}}"
}

# Runs a verification command for each version of slsa-verifier.
# $1: command to run. The command should take the verifier binary as an
#     argument.
e2e_run_verifier_all_releases() {
    VERIFIER_REPOSITORY="slsa-framework/slsa-verifier"
    VERIFIER_BINARY="slsa-verifier-linux-amd64"
    VERIFY_COMMAND=$1

    # First, verify provenance with the verifier at HEAD.
    go env -w GOFLAGS=-mod=mod
    go install "github.com/$VERIFIER_REPOSITORY@latest"
    echo "**** Verifying provenance with verifier at HEAD *****"
    verify_provenance "slsa-verifier"

    # Second, retrieve all previous versions of the verifier,
    # and verify the provenance. This is essentially regression tests.
    RELEASE_LIST=$(gh release -R "$VERIFIER_REPOSITORY" -L 100 list)
    while read -r line; do
        TAG=$(echo "$line" | cut -f1)
        gh release -R "$VERIFIER_REPOSITORY" download "$TAG" -p "$VERIFIER_BINARY*" || exit 10

        # Use the compiled verifier to verify the provenance (Optional)
        slsa-verifier --branch "main" \
            --tag "$TAG" \
            --artifact-path "$VERIFIER_BINARY" \
            --provenance "$VERIFIER_BINARY.intoto.jsonl" \
            --source "github.com/$VERIFIER_REPOSITORY" || exit 6

        echo "**** Verifying provenance with verifier at $TAG ****"
        chmod a+x "./$VERIFIER_BINARY"
        $VERIFY_COMMAND "./$VERIFIER_BINARY"

    done <<<"$RELEASE_LIST"
}
