#!/usr/bin/env bash
# Comment out the line below to be able to verify failure of certain commands.
#set -euo pipefail

# To test:
# export GITHUB_SHA=6f3b6435f5a17a25ad6cf2704d0c192bcef8193f
# export GITHUB_RUN_ID=2272442563
# export GITHUB_ACTOR=laurentsimon
# export GITHUB_RUN_ATTEMPT=1
# export GITHUB_REF=refs/heads/branch-name or refs/tags/tag-name
# export GITHUB_REF_TYPE=branch or tag
# export GITHUB_REPOSITORY=slsa-framework/example-package
# export GITHUB_REF_NAME=v1.2.3
# export GITHUB_WORKFLOW=go schedule main SLSA3 config-noldflags
# export THIS_FILE=e2e.go.workflow_dispatch.main.config-noldflags.slsa3.yml
# export BINARY=binary-linux-amd64
# export PROVENANCE=example.intoto.jsonl

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-verify.common.sh"

# Script Inputs
GITHUB_REF=${GITHUB_REF:-}
GITHUB_REF_NAME=${GITHUB_REF_NAME:-}
GITHUB_REF_TYPE=${GITHUB_REF_TYPE:-}
BINARY=${BINARY:-}
PROVENANCE=${PROVENANCE:-}
GO_MAIN=${GO_MAIN:-}
GO_DIR=${GO_DIR:-}
RUNNER_DEBUG=${RUNNER_DEBUG:-}
if [[ -n "${RUNNER_DEBUG}" ]]; then
    set -x
fi

# Function used to verify the content of the provenance.
verify_provenance_content() {
    attestation=$(jq -r '.payload' <"$PROVENANCE" | base64 -d)
    #TRIGGER=$(echo "$THIS_FILE" | cut -d '.' -f3)
    #BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
    this_file=$(e2e_this_file)
    this_branch=$(e2e_this_branch)
    ldflags=$(echo "${this_file}" | cut -d '.' -f5 | grep -v noldflags || true)
    #DIR=$(echo "$THIS_FILE" | cut -d '.' -f5 | grep '\-dir')
    has_assets=$(echo "${this_file}" | cut -d '.' -f5 | grep -v noassets || true)
    is_prerelease=$(echo "${this_file}" | cut -d '.' -f5 | grep prerelease || true)
    is_draft=$(echo "${this_file}" | cut -d '.' -f5 | grep draft || true)
    tag=$(echo "${this_file}" | cut -d '.' -f5 | grep tag || true)
    # Note GO_MAIN and GO_DIR are set in the workflows as env variables.
    dir="$PWD/__PROJECT_CHECKOUT_DIR__"
    if [[ -n "$GO_DIR" ]]; then
        dir="${dir}/$GO_DIR"
    fi

    echo "  **** Provenance content verification *****"

    # Verify all common provenance fields.
    e2e_verify_common_all "${attestation}"

    e2e_verify_predicate_subject_name "${attestation}" "$BINARY"
    e2e_verify_predicate_builder_id "${attestation}" "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml@refs/heads/main"
    e2e_verify_predicate_buildType "${attestation}" "https://github.com/slsa-framework/slsa-github-generator/go@v1"

    e2e_verify_predicate_invocation_environment "${attestation}" "os" "ubuntu22"
    e2e_verify_predicate_invocation_environment "${attestation}" "arch" "X64"

    # First step is vendoring
    e2e_verify_predicate_buildConfig_step_command "0" "${attestation}" "[\"mod\",\"vendor\"]"
    e2e_verify_predicate_buildConfig_step_env "0" "${attestation}" "[]"
    e2e_verify_predicate_buildConfig_step_workingDir "0" "${attestation}" "${dir}"

    # Second step is the actual compilation.
    e2e_verify_predicate_buildConfig_step_env "1" "${attestation}" "[\"GOOS=linux\",\"GOARCH=amd64\",\"GO111MODULE=on\",\"CGO_ENABLED=0\"]"
    e2e_verify_predicate_buildConfig_step_workingDir "1" "${attestation}" "${dir}"

    if [[ -z "${ldflags}" ]]; then
        e2e_verify_predicate_buildConfig_step_command "1" "${attestation}" "[\"build\",\"-mod=vendor\",\"-trimpath\",\"-tags=netgo\",\"-o\",\"$BINARY\"]"
    else
        chmod a+x ./"$BINARY"

        if [[ -z "$GO_MAIN" ]]; then
            # Note: Tests with tag don't use the `main:` field in config file.
            if [[ "$GITHUB_REF_TYPE" == "tag" ]] && [[ -n "${tag}" ]]; then
                e2e_verify_predicate_buildConfig_step_command "1" "${attestation}" "[\"build\",\"-mod=vendor\",\"-trimpath\",\"-tags=netgo\",\"-ldflags=-X main.gitVersion=v1.2.3 -X main.gitCommit=abcdef -X main.gitBranch=${this_branch} -X main.gitTag=$GITHUB_REF_NAME\",\"-o\",\"$BINARY\"]"
            else
                e2e_verify_predicate_buildConfig_step_command "1" "${attestation}" "[\"build\",\"-mod=vendor\",\"-trimpath\",\"-tags=netgo\",\"-ldflags=-X main.gitVersion=v1.2.3 -X main.gitCommit=abcdef -X main.gitBranch=${this_branch}\",\"-o\",\"$BINARY\"]"
            fi
        else
            e2e_verify_predicate_buildConfig_step_command "1" "${attestation}" "[\"build\",\"-mod=vendor\",\"-trimpath\",\"-tags=netgo\",\"-ldflags=-X main.gitVersion=v1.2.3 -X main.gitCommit=abcdef -X main.gitBranch=${this_branch} -X main.gitMain=$GO_MAIN\",\"-o\",\"$BINARY\",\"$GO_MAIN\"]"
            M=$(./"$BINARY" | grep "GitMain: $GO_MAIN")
            e2e_assert_not_eq "$M" "" "GitMain should not be empty"
        fi

        V=$(./"$BINARY" | grep 'GitVersion: v1.2.3')
        C=$(./"$BINARY" | grep 'GitCommit: abcdef')
        B=$(./"$BINARY" | grep "GitBranch: ${this_branch}")
        e2e_assert_not_eq "$V" "" "GitVersion should not be empty"
        e2e_assert_not_eq "$C" "" "GitCommit should not be empty"
        e2e_assert_not_eq "$B" "" "GitBranch should not be empty"

        # Verify the GitTag is set to the dynamic version using {{ .Version }}.
        # and that the name of the binary is set properly.
        if [[ "$GITHUB_REF_TYPE" == "tag" ]] && [[ -n "${tag}" ]]; then
            T=$(./"$BINARY" | grep "GitTag: $GITHUB_REF_NAME")
            e2e_assert_not_eq "$T" "" "GitTag should not be empty"

            e2e_assert_eq "$BINARY" "binary-linux-amd64-$GITHUB_REF_NAME"
        elif [[ "$GITHUB_REF_TYPE" != "tag" ]] && [[ -n "${tag}" ]]; then
            ./"$BINARY"
            T=$(./"$BINARY" | grep "GitTag: unknown")
            e2e_assert_not_eq "$T" "" "GitTag should contain unknown"

            e2e_assert_eq "$BINARY" "binary-linux-amd64-unknown"
        else
            ./"$BINARY"
            # NOTE: grep -z option is used in order to match newline.
            T=$(./"$BINARY" | grep -zoP "GitTag: \n")
            e2e_assert_not_eq "$T" "" "GitTag should be empty"

            e2e_assert_eq "$BINARY" "binary-linux-amd64"
        fi
    fi

    if [[ "$GITHUB_REF_TYPE" == "tag" ]]; then
        assets=$(e2e_get_release_assets_filenames "$GITHUB_REF_NAME")
        isPrerelease=$(e2e_is_prerelease "$GITHUB_REF_NAME")
        isDraft=$(e2e_is_draft "$GITHUB_REF_NAME")
        if [[ -z "$has_assets" ]]; then
            e2e_assert_eq "$assets" "[\"null\",\"null\"]" "there should be no assets"
        else
            e2e_assert_eq "$assets" "[\"$BINARY\",\"$BINARY.intoto.jsonl\"]" "there should be assets"
        fi

        if [[ -n "$is_prerelease" ]]; then
            if ! assert_true "$isPrerelease" "expected prerelease"; then
                exit 1
            fi
        fi

        if [[ -n "$is_draft" ]]; then
            if ! assert_true "$isDraft" "expected draft"; then
                exit 1
            fi
        fi
    fi
}

# =====================================
# ===== main execution starts =========
# =====================================

this_file=$(e2e_this_file)
branch=$(e2e_this_branch)
echo "branch is ${branch}"
echo "GITHUB_REF_NAME: $GITHUB_REF_NAME"
echo "GITHUB_REF_TYPE: $GITHUB_REF_TYPE"
echo "GITHUB_REF: $GITHUB_REF"
echo "DEBUG: file is ${this_file}"
echo "BINARY: file is $BINARY"

export SLSA_VERIFIER_TESTING="true"

# Verify provenance authenticity with min version at release v2.5.1
# Due to the breaking change below, we only need to verify starting at v2.51
# https://github.com/slsa-framework/slsa-github-generator/issues/3350
e2e_run_verifier_all_releases "v2.5.1"

# Verify the provenance content.
verify_provenance_content
