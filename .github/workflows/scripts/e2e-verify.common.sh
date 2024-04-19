#!/usr/bin/env bash
#
# This file contains tests for common fields of Github Actions provenance.

# shellcheck source=/dev/null
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
    # Script Inputs
    local gh_actor=${GITHUB_ACTOR:-}
    local gh_event_name=${GITHUB_EVENT_NAME:-}
    local gh_ref=${GITHUB_REF:-}
    local gh_ref_type=${GITHUB_REF_TYPE:-}
    local gh_repo=${GITHUB_REPOSITORY:-}
    local gh_repo_owner=${GITHUB_REPOSITORY_OWNER:-}
    local gh_run_attempt=${GITHUB_RUN_ATTEMPT:-}
    local gh_run_id=${GITHUB_RUN_ID:-}
    local gh_run_number=${GITHUB_RUN_NUMBER:-}
    local gh_sha=${GITHUB_SHA:-}

    e2e_verify_predicate_invocation_configSource "$1" "{\"uri\":\"git+https://github.com/${gh_repo}@${gh_ref}\",\"digest\":{\"sha1\":\"${gh_sha}\"},\"entryPoint\":\".github/workflows/$(e2e_this_file)\"}"

    e2e_verify_predicate_invocation_environment "$1" "github_actor" "${gh_actor}"
    e2e_verify_predicate_invocation_environment "$1" "github_sha1" "${gh_sha}"
    e2e_verify_predicate_invocation_environment "$1" "github_event_name" "${gh_event_name}"
    e2e_verify_predicate_invocation_environment "$1" "github_ref" "${gh_ref}"
    e2e_verify_predicate_invocation_environment "$1" "github_ref_type" "${gh_ref_type}"
    e2e_verify_predicate_invocation_environment "$1" "github_run_id" "${gh_run_id}"
    e2e_verify_predicate_invocation_environment "$1" "github_run_number" "${gh_run_number}"
    e2e_verify_predicate_invocation_environment "$1" "github_run_attempt" "${gh_run_attempt}"
    local actor_id owner_id repo_id
    actor_id=$(gh api -H "Accept: application/vnd.github.v3+json" /users/"${gh_actor}" | jq -r '.id')
    owner_id=$(gh api -H "Accept: application/vnd.github.v3+json" /users/"${gh_repo_owner}" | jq -r '.id')
    repo_id=$(gh api -H "Accept: application/vnd.github.v3+json" /repos/"${gh_repo}" | jq -r '.id')
    e2e_verify_predicate_invocation_environment "$1" "github_actor_id" "${actor_id}"
    e2e_verify_predicate_invocation_environment "$1" "github_repository_owner_id" "${owner_id}"
    e2e_verify_predicate_invocation_environment "$1" "github_repository_id" "${repo_id}"
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

e2e_verify_common_all_v02() {
    e2e_verify_common_builder "$1"
    e2e_verify_common_invocation_v02 "$1"
    e2e_verify_common_metadata_v02 "$1"
    e2e_verify_common_materials "$1"
}

e2e_verify_common_invocation_v02() {
    local gh_event_name=${GITHUB_EVENT_NAME:-}
    local gh_actor_id=${GITHUB_ACTOR_ID:-}
    local gh_repo=${GITHUB_REPOSITORY:-}
    local gh_repo_id=${GITHUB_REPOSITORY_ID:-}
    local gh_repo_owner_id=${GITHUB_REPOSITORY_OWNER_ID:-}
    local gh_ref=${GITHUB_REF:-}
    local gh_ref_type=${GITHUB_REF_TYPE:-}
    local gh_run_attempt=${GITHUB_RUN_ATTEMPT:-}
    local gh_run_id=${GITHUB_RUN_ID:-}
    local gh_run_number=${GITHUB_RUN_NUMBER:-}
    local gh_sha=${GITHUB_SHA:-}
    local gh_workflow_ref=${GITHUB_WORKFLOW_REF:-}
    local gh_workflow_sha=${GITHUB_WORKFLOW_SHA:-}

    # This does not include buildType since it is not common to all.
    e2e_verify_predicate_invocation_configSource "$1" "{\"uri\":\"git+https://github.com/${gh_repo}@${gh_ref}\",\"digest\":{\"sha1\":\"${gh_sha}\"},\"entryPoint\":\".github/workflows/$(e2e_this_file)\"}"

    e2e_verify_predicate_invocation_environment "$1" "GITHUB_EVENT_NAME" "${gh_event_name}"
    e2e_verify_predicate_invocation_environment "$1" "GITHUB_REF" "${gh_ref}"
    e2e_verify_predicate_invocation_environment "$1" "GITHUB_REF_TYPE" "${gh_ref_type}"
    e2e_verify_predicate_invocation_environment "$1" "GITHUB_REPOSITORY" "${gh_repo}"
    e2e_verify_predicate_invocation_environment "$1" "GITHUB_RUN_ATTEMPT" "${gh_run_attempt}"
    e2e_verify_predicate_invocation_environment "$1" "GITHUB_RUN_ID" "${gh_run_id}"
    e2e_verify_predicate_invocation_environment "$1" "GITHUB_RUN_NUMBER" "${gh_run_number}"
    e2e_verify_predicate_invocation_environment "$1" "GITHUB_SHA" "${gh_sha}"
    e2e_verify_predicate_invocation_environment "$1" "GITHUB_ACTOR_ID" "${gh_actor_id}"
    e2e_verify_predicate_invocation_environment "$1" "GITHUB_REPOSITORY_ID" "${gh_repo_id}"
    e2e_verify_predicate_invocation_environment "$1" "GITHUB_REPOSITORY_OWNER_ID" "${gh_repo_owner_id}"
    e2e_verify_predicate_invocation_environment "$1" "GITHUB_WORKFLOW_REF" "${gh_workflow_ref}"
    e2e_verify_predicate_invocation_environment "$1" "GITHUB_WORKFLOW_SHA" "${gh_workflow_sha}"
}

e2e_verify_common_metadata_v02() {
    e2e_verify_predicate_metadata "$1" "{\"buildInvocationId\":\"$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT\",\"completeness\":{\"parameters\":true}}"
}

# Verifies common fields of the SLSA v1.0 predicate.
# $1: the predicate content
e2e_verify_common_all_v1() {
    e2e_verify_common_buildDefinition_v1 "$1"
    e2e_verify_common_runDetails_v1 "$1"
    e2e_verify_common_builder "$1"
}

# Verifies common fields of the SLSA v1.0 predicate buildDefinition.
# $1: the predicate content
e2e_verify_common_buildDefinition_v1() {
    # Script Inputs.
    local checkout_sha1=${CHECKOUT_SHA1:-}
    local gh_actor_id=${GITHUB_ACTOR_ID:-}
    local gh_event_name=${GITHUB_EVENT_NAME:-}
    local gh_ref=${GITHUB_REF:-}
    local gh_ref_type=${GITHUB_REF_TYPE:-}
    local gh_repo=${GITHUB_REPOSITORY:-}
    local gh_repo_id=${GITHUB_REPOSITORY_ID:-}
    local gh_repo_owner_id=${GITHUB_REPOSITORY_OWNER_ID:-}
    local gh_run_attempt=${GITHUB_RUN_ATTEMPT:-}
    local gh_run_id=${GITHUB_RUN_ID:-}
    local gh_run_number=${GITHUB_RUN_NUMBER:-}
    local gh_sha=${GITHUB_SHA:-}
    local gh_workflow_ref=${GITHUB_WORKFLOW_REF:-}
    local gh_workflow_sha=${GITHUB_WORKFLOW_SHA:-}

    # This does not include buildType since it is not common to all.
    e2e_verify_predicate_v1_buildDefinition_internalParameters "$1" "GITHUB_EVENT_NAME" "${gh_event_name}"
    e2e_verify_predicate_v1_buildDefinition_internalParameters "$1" "GITHUB_REF" "${gh_ref}"
    e2e_verify_predicate_v1_buildDefinition_internalParameters "$1" "GITHUB_REF_TYPE" "$gh_ref_type"
    e2e_verify_predicate_v1_buildDefinition_internalParameters "$1" "GITHUB_REPOSITORY" "${gh_repo}"
    e2e_verify_predicate_v1_buildDefinition_internalParameters "$1" "GITHUB_RUN_ATTEMPT" "${gh_run_attempt}"
    e2e_verify_predicate_v1_buildDefinition_internalParameters "$1" "GITHUB_RUN_ID" "${gh_run_id}"
    e2e_verify_predicate_v1_buildDefinition_internalParameters "$1" "GITHUB_RUN_NUMBER" "${gh_run_number}"
    e2e_verify_predicate_v1_buildDefinition_internalParameters "$1" "GITHUB_SHA" "${gh_sha}"
    e2e_verify_predicate_v1_buildDefinition_internalParameters "$1" "GITHUB_ACTOR_ID" "${gh_actor_id}"
    e2e_verify_predicate_v1_buildDefinition_internalParameters "$1" "GITHUB_REPOSITORY_ID" "${gh_repo_id}"
    e2e_verify_predicate_v1_buildDefinition_internalParameters "$1" "GITHUB_REPOSITORY_OWNER_ID" "${gh_repo_owner_id}"
    e2e_verify_predicate_v1_buildDefinition_internalParameters "$1" "GITHUB_WORKFLOW_REF" "${gh_workflow_ref}"
    e2e_verify_predicate_v1_buildDefinition_internalParameters "$1" "GITHUB_WORKFLOW_SHA" "${gh_workflow_sha}"
    triggering_actor_id=$(gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "/repos/${gh_repo}/actions/runs/${gh_run_id}" | jq -r '.actor.id')
    e2e_verify_predicate_v1_buildDefinition_internalParameters "$1" "GITHUB_TRIGGERING_ACTOR_ID" "${triggering_actor_id}"
    if [[ -n ${checkout_sha1:-} ]]; then
        # If the checkout sha was defined, then verify that there is no ref.
        e2e_verify_predicate_v1_buildDefinition_resolvedDependencies "$1" "[{\"uri\":\"git+https://github.com/${gh_repo}\",\"digest\":{\"gitCommit\":\"${checkout_sha1}\"}}]"
    else
        build_type=$(e2e_this_file | cut -d '.' -f2)
        # The container-based builder uses 2 entries, one for the repo and one for the builder.
        # It also uses sha1 instead of gitCommit.
        if [[ "$build_type" == "container-based" ]]; then
            e2e_verify_predicate_v1_buildDefinition_resolvedDependencies0 "$1" "{\"uri\":\"git+https://github.com/${gh_repo}@${gh_ref}\",\"digest\":{\"sha1\":\"${gh_sha}\"}}"
        else
            e2e_verify_predicate_v1_buildDefinition_resolvedDependencies "$1" "[{\"uri\":\"git+https://github.com/${gh_repo}@${gh_ref}\",\"digest\":{\"gitCommit\":\"${gh_sha}\"}}]"
        fi
    fi
}

# Verifies common fields of the SLSA v1.0 predicate runDetails.
# $1: the predicate content
e2e_verify_common_runDetails_v1() {
    local gh_repo=${GITHUB_REPOSITORY:-}
    local gh_run_attempt=${GITHUB_RUN_ATTEMPT:-}
    local gh_run_id=${GITHUB_RUN_ID:-}

    # This does not include the builder ID since it is not common to all.
    e2e_verify_predicate_v1_runDetails_metadata_invocationId "$1" "https://github.com/${gh_repo}/actions/runs/${gh_run_id}/attempts/${gh_run_attempt}"
}

# e2e_get_payload prints the provenance payload in JSON format.
# $1: File containing the DSSE envelope.
e2e_get_payload() {
    jq -r '.payload' <"$1" | base64 -d
}

# e2e_set_payload overwrites the provenance payload with other provenance and
# prints it.
# $1: File containing the DSSE envelope.
# $2: The new provenance payload.
e2e_set_payload() {
    local this_builder
    this_builder=$(e2e_this_builder)
    if [[ "${this_builder}" == "gcb" ]]; then
        jq -c ".provenance_summary.provenance[0].envelope.payload = \"$(echo "$2" | base64 -w0)\"" <"$1" > tmp.json && mv tmp.json "$1"
    else
        jq -c ".payload = \"$(echo "$2" | base64 -w0)\"" <"$1"
    fi
}

# get_builder_id returns the build ID used for the test.
get_builder_id() {
    # Script Inputs.
    local full_builder_id=${BUILDER_ID:-}

    this_builder=$(e2e_this_builder)
    builder_id=""
    case ${this_builder} in
    "go")
        builder_id="https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml@refs/heads/main"
        ;;
    "generic")
        builder_id="https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@refs/heads/main"
        ;;
    "gcb")
        builder_id="https://cloudbuild.googleapis.com/GoogleHostedWorker"
        ;;
    "container")
        builder_id="https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/heads/main"
        ;;
    "container-based")
        builder_id="https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_container-based_slsa3.yml@refs/heads/main"
        ;;
    "nodejs")
        builder_id="https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_nodejs_slsa3.yml@refs/heads/main"
        ;;
    "maven")
        builder_id="https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_maven_slsa3.yml@refs/heads/main"
        ;;
    "gradle")
        builder_id="https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_gradle_slsa3.yml@refs/heads/main"
        ;;
    "bazel")
        builder_id="https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_bazel_slsa3.yml@refs/heads/main"
        ;;
    "delegator-generic" | "delegator-lowperms")
        # The builder ID is set by the workflow.
        # NOTE: the TRW is referenced at a tag, but the BYOB is referenced at HEAD.
        builder_id="${full_builder_id}"
        ;;
    *)
        echo "unknown build_type: ${this_builder}"
        exit 1
        ;;
    esac
    echo "${builder_id}"
}

# assemble_minimum_builder_args assembles the minimum arguments
# number of arguments for the build ID.
assemble_minimum_builder_args() {
    local this_builder builder_id
    this_builder=$(e2e_this_builder)
    builder_id=$(get_builder_id)
    if [[ "${this_builder}" == "gcb" ]]; then
        echo "--builder-id=${builder_id}"
    elif [[ "${this_builder}" == "nodejs" ]]; then
        echo "--builder-id=${builder_id}"
    elif [[ "${this_builder}" == "delegator-generic" ]]; then
        echo "--builder-id=${builder_id}"
    elif [[ "${this_builder}" == "delegator-lowperms" ]]; then
        echo "--builder-id=${builder_id}"
    elif [[ "${this_builder}" == "maven" ]]; then
        echo "--builder-id=${builder_id}"
    elif [[ "${this_builder}" == "gradle" ]]; then
        echo "--builder-id=${builder_id}"
    elif [[ "${this_builder}" == "bazel" ]]; then
        echo "--builder-id=${builder_id}"
    fi
    # NOTE: There is no default value we retun if
    # not one of the buidlers above. This is on purpose,
    # the caller will check the result whether it's non-empty.
}

# assemble_raw_builder_args assembles
# builder ID with the builder.id but without the tag.
assemble_raw_builder_args() {
    local this_builder builder_id builder_raw_id
    this_builder=$(e2e_this_builder)
    builder_id=$(get_builder_id)
    builder_raw_id=$(echo "${builder_id}" | cut -f1 -d '@')
    if [[ "${this_builder}" == "gcb" ]]; then
        echo "--builder-id=${builder_id}"
    elif [[ "${this_builder}" == "nodejs" ]]; then
        echo "--builder-id=${builder_id}"
    else
        echo "--builder-id=${builder_raw_id}"
    fi
}

# assemble_full_builder_args assembles
# builder ID with the builder.id@tag.
assemble_full_builder_args() {
    local builder_id
    builder_id=$(get_builder_id)
    echo "--builder-id=${builder_id}"
}

# Dynamically toggle the assertion function
# to adapt to BYOB with checkout-sha1 option used.
assert_fn() {
    local branchDefined="$1"
    # If a branch is defined and checkout sha1 is used,
    # verification must fail.
    if [[ -n ${CHECKOUT_SHA1:-} ]] && [[ "${branchDefined}" != "0" ]]; then
        echo e2e_assert_not_eq
    else
        echo e2e_assert_eq
    fi
}

# verify_provenance_authenticity is a function that verifies the authenticity of
# the provenance using slsa-verifier.
# $1: The path to the slsa-verifier binary.
# $2: The slsa-verifier version's git tag.
verify_provenance_authenticity() {
    # Script Inputs.
    ATTESTATIONS=${ATTESTATIONS:-}
    BINARY=${BINARY:-}
    CONTAINER=${CONTAINER:-}
    GITHUB_REF_NAME=${GITHUB_REF_NAME:-}
    PROVENANCE=${PROVENANCE:-}
    PROVENANCE_REPOSITORY=${PROVENANCE_REPOSITORY:-}

    local verifier="$1"
    local tag="$2"
    local annotated_tags
    local build_type
    local this_branch
    annotated_tags=$(e2e_this_options | grep annotated || true)
    build_type=$(e2e_this_builder)
    this_branch=$(e2e_this_branch)

    verifierCmd="$verifier"
    # After version v1.3.X, we split into subcommands for artifacts and images
    if [[ "$tag" == "HEAD" ]] || version_ge "$tag" "v1.4"; then
        if [[ "$build_type" == "container" || "$build_type" == "gcb" ]]; then
            verifierCmd="$verifier verify-image"
        elif [[ "$build_type" == "nodejs" ]]; then
            verifierCmd="$verifier verify-npm-package"
        else
            verifierCmd="$verifier verify-artifact"
        fi
    fi

    # This transforms the argument name depending on the verifier tag.
    argr="$(e2e_verifier_arg_transformer "$tag")"
    read -ra sourceArg <<<"$($argr "source")"
    read -ra tagArg <<<"$($argr "tag")"
    read -ra branchArg <<<"$($argr "branch")"
    read -ra vTagArg <<<"$($argr "versioned-tag")"
    read -ra workflowInputArg <<<"$($argr "workflow-input")"

    # Only versions v1.4+ of the verifier can verify containers.
    if [[ "$build_type" == "container" || "$build_type" == "gcb" ]] && version_lt "$tag" "v1.4" && [[ "$tag" != "HEAD" ]]; then
        echo "  INFO: image verification at $tag: skipping due to lack of support"
        return 0
    fi

    if version_le "$tag" "v1.0.0" && [[ "$tag" != "HEAD" ]]; then
        if [[ "$GITHUB_EVENT_NAME" == "release" ]]; then
            echo "  INFO: release trigger at v1.0.0: skipping authenticity verification due to lack of support (https://github.com/slsa-framework/slsa-verifier/pull/89)"
            return 0
        fi
    fi

    multi_subjects=$(e2e_this_file | cut -d '.' -f5 | grep multi-subjects)
    if [[ -n "$multi_subjects" ]] && version_lt "$tag" "v1.2.0" && [[ "$tag" != "HEAD" ]]; then
        echo "  INFO: multiple subject verification at $tag: skipping due to lack of support (https://github.com/slsa-framework/slsa-verifier/pull/112)"
        return 0
    fi

    # Assemble artifact args depending on whether this is a container or binary artifact.
    if [[ "$build_type" == "container" || "$build_type" == "gcb" ]]; then
        read -ra artifactArg <<<"${CONTAINER}"
    else
        read -ra artifactArg <<<"$($argr "artifact-path") ${BINARY}"
    fi

    # Assemble the provenance args: for container builds it is attached.
    provenanceArg=()
    if [[ "$build_type" == "nodejs" ]]; then
        read -ra provenanceArg <<<"--attestations-path ${ATTESTATIONS}"
    elif [[ "$build_type" == "container" ]]; then
        if [ -n "${PROVENANCE_REPOSITORY}" ]; then
            if version_gt "$tag" "v2.4.1" || [ "$tag" == "HEAD" ] ; then
                read -ra provenanceArg <<<"$($argr "provenance-repository") ${PROVENANCE_REPOSITORY}"
            fi
        fi
    elif [[ "$build_type" != "container" ]]; then
        read -ra provenanceArg <<<"$($argr "provenance") ${PROVENANCE}"
    fi

    packageArg=()
    if [[ "$build_type" == "nodejs" ]]; then
        packageArg+=("--package-name" "${PACKAGE_NAME}")
        packageArg+=("--package-version" "$(version_major "$PACKAGE_VERSION").$(version_minor "$PACKAGE_VERSION").$(version_patch "$PACKAGE_VERSION")")
    fi

    # Assemble the builder arguments.
    artifactAndbuilderMinArgs=("${artifactArg[@]}")
    artifactAndbuilderRawArgs=("${artifactArg[@]}")
    artifactAndbuilderFullArgs=("${artifactArg[@]}")
    # We added support for builder id in v2 or so, but definitely for GCB.
    if version_ge "$tag" "v2" || [[ "$tag" == "HEAD" ]]; then
        echo "Testing against builder args"
        tmp_min=$(assemble_minimum_builder_args)
        if [[ -n "$tmp_min" ]]; then
            artifactAndbuilderMinArgs+=("$tmp_min")
        fi
        tmp_raw=$(assemble_raw_builder_args)
        if [[ -n "$tmp_raw" ]]; then
            artifactAndbuilderRawArgs+=("$tmp_raw")
        fi
        tmp_full=$(assemble_full_builder_args)
        if [[ -n "$tmp_full" ]]; then
            artifactAndbuilderFullArgs+=("$tmp_full")
        fi
    fi

    # Default parameters.
    # After v1.2, branch verification is optional, so we can always verify,
    # regardless of the branch value.
    # https://github.com/slsa-framework/slsa-verifier/pull/192
    if [[ "$tag" == "HEAD" ]] || version_ge "$tag" "v1.3"; then
        echo "  **** Default parameters (annotated tags) *****"
        $verifierCmd "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_eq "$?" "0" "not main default parameters (annotated_tags)"
    elif [[ -z "$annotated_tags" ]]; then
        # Up until v1.3, we verified the default branch as "main".
        if [[ "${this_branch}" == "main" ]]; then
            echo "  **** Default parameters (main) *****"
            $verifierCmd "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_eq "$?" "0" "main default parameters"
        else
            echo "  **** Default parameters *****"
            $verifierCmd "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_not_eq "$?" "0" "not main default parameters"
        fi
    fi

    branchOpts=("${branchArg[@]}")
    branchOpts+=("${this_branch}")
    if [[ -n "$annotated_tags" ]]; then
        branchOpts=()
        # Annotated tags don't have a branch to verify, so we bail early for versions that always verify the branch.
        # See https://github.com/slsa-framework/slsa-verifier/issues/193.
        if version_lt "$tag" "v1.3" && [[ "$tag" != "HEAD" ]]; then
            echo "  INFO: annotated tag verification at $tag: skipping due to lack of support (https://github.com/slsa-framework/slsa-verifier/issues/193)"
            return 0
        fi
    fi
    if [[ "$build_type" == "gcb" ]]; then
        # GCB does not support branch verification.
        branchOpts=()
    fi

    if [[ "$GITHUB_EVENT_NAME" == "create" ]]; then
        # This trigger does not support branch verification.
        # The GitHub event only seems to contain: "master_branch": "main" and "default_branch": "main".
        branchArg=()
        branchOpts=()
    fi

    if [[ "$build_type" == "nodejs" ]]; then
        # Node.js does not support branch verification.
        branchArg=()
        branchOpts=()
        tagArg=()
        vTagArg=()
    fi

    # Set the assert function dynamically.
    # This lets us toggle the assertion from e2e_assert_eq to e2e_assert_not_eq
    # if BYOB is used with checkout-sha1 argument.
    assert_fn=$(assert_fn "${#branchOpts[@]}")

    # Workflow inputs
    workflow_inputs=$(e2e_this_file | cut -d '.' -f5 | grep workflow_inputs)
    if [[ -n "$workflow_inputs" ]] && (version_ge "$tag" "v1.3" || [[ "$tag" == "HEAD" ]]); then
        echo "  **** Correct Workflow Inputs *****"
        $verifierCmd "${branchOpts[@]}" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY" "${workflowInputArg[@]}" test=true
        e2e_assert_eq "$?" "0" "should be workflow inputs"

        echo "  **** Wrong Workflow Inputs *****"
        $verifierCmd "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY" "${workflowInputArg[@]}" test=false
        e2e_assert_not_eq "$?" "0" "wrong workflow inputs"
    fi

    # Correct branch.
    echo "  **** Correct branch *****"
    if [[ "${#branchOpts[@]}" != "0" ]]; then
        $verifierCmd "${artifactAndbuilderMinArgs[@]}" "${branchOpts[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        # The assert function is dynamically set. If it's BYOB with checkout-sha1 set
        # this needs to fail.
        "${assert_fn}" "$?" "0" "should be branch ${this_branch}"
    fi

    # Wrong branch
    if [[ "${#branchArg[@]}" != "0" ]]; then
        echo "  **** Wrong branch *****"
        $verifierCmd "${branchArg[@]}" "not-$GITHUB_REF_NAME" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "wrong branch"
    fi

    # Wrong tag
    if [[ "${#tagArg[@]}" != "0" ]]; then
        echo "  **** Wrong tag *****"
        $verifierCmd "${tagArg[@]}" v1.2.3 "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "wrong tag"
    fi

    # Correct raw builder ID verification
    echo "  **** Correct raw builder.id *****"
    $verifierCmd "${artifactAndbuilderRawArgs[@]}" "${branchOpts[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
    "${assert_fn}" "$?" "0" "correct raw builder id"

    # Wrong raw builder ID verification
    echo "  **** Wrong raw builder.id *****"
    # shellcheck disable=SC2145 # We intend to alter the builder ID.
    $verifierCmd "${artifactAndbuilderRawArgs[@]}a" "${branchOpts[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "wrong raw builder id"

    # Correct full builder ID verification
    echo "  **** Correct full builder.id *****"
    $verifierCmd "${artifactAndbuilderFullArgs[@]}" "${branchOpts[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
    "${assert_fn}" "$?" "0" "correct full builder id"

    # Wrong full builder ID verification
    echo "  **** Wrong full builder.id *****"
    # shellcheck disable=SC2145 # We intend to alter the builder ID.
    $verifierCmd "${artifactAndbuilderFullArgs[@]}a" "${branchOpts[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "wrong full builder id"

    # Note that for containers with attached provenance, we will skip this test.
    # TODO(#108):
    # Add a malicious container test that attaches bad provenance.
    if [[ "$build_type" != "container" ]] && [[ "$build_type" != "nodejs" ]]; then
        echo "  **** Wrong payload *****"
        local bad_prov
        bad_prov="$(mktemp -t slsa-e2e.XXXXXXXX)"
        e2e_set_payload "$PROVENANCE" '{"foo": "bar"}' >"${bad_prov}"
        read -ra badProvenanceArg <<<"$($argr "provenance") ${bad_prov}"
        $verifierCmd "${artifactAndbuilderMinArgs[@]}" "${branchOpts[@]}" "${badProvenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "wrong payload"
    elif [[ "$build_type" == "nodejs" ]]; then
        echo "  **** Wrong payload *****"
        local bad_prov
        bad_prov="$(mktemp -t slsa-e2e.XXXXXXXX)"
        e2e_set_payload "$ATTESTATIONS" '{"foo": "bar"}' >"${bad_prov}"
        read -ra badProvenanceArg <<<"$($argr "provenance") ${bad_prov}"
        $verifierCmd "${artifactAndbuilderMinArgs[@]}" "${branchOpts[@]}" "${badProvenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "wrong payload"
    fi

    if [[ "$build_type" == "nodejs" ]]; then
        echo "  **** Wrong package-name *****"
        read -ra badPackageNameArg <<<"--package-name bad-package-name"
        read -ra badPackageNameArg <<<"--package-version ${MAJOR}.${MINOR}.${PATCH}"
        $verifierCmd "${artifactAndbuilderMinArgs[@]}" "${branchOpts[@]}" "${badProvenanceArg[@]}" "${sourceArg[@]}" "${badPackageNameArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "wrong package-name"

        # Bad Package version
        # TODO: Test more bad versions.
        read -ra badPackageVersionArg <<<"--package-name ${PACKAGE_NAME}"
        read -ra badPackageVersionArg <<<"--package-version 0.0.0"
        echo "  **** Wrong package-version *****"
        $verifierCmd "${artifactAndbuilderMinArgs[@]}" "${branchOpts[@]}" "${badProvenanceArg[@]}" "${sourceArg[@]}" "${badPackageVersionArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "wrong package-version"
    fi

    if [[ "${#vTagArg[@]}" != "0" ]] && [[ "${#branchOpts[@]}" != "0" ]]; then
        if [[ "$GITHUB_REF_TYPE" == "tag" ]]; then
            local SEMVER MAJOR MINOR PATCH
            SEMVER="$GITHUB_REF_NAME"
            MAJOR=$(version_major "$SEMVER")
            MINOR=$(version_minor "$SEMVER")
            PATCH=$(version_patch "$SEMVER")

            local MAJOR_LESS_ONE MINOR_LESS_ONE PATCH_LESS_ONE
            MAJOR_LESS_ONE=$((${MAJOR:-1} - 1))
            MINOR_LESS_ONE=$((${MINOR:-1} - 1))
            PATCH_LESS_ONE=$((${PATCH:-1} - 1))

            local MAJOR_PLUS_ONE MINOR_PLUS_ONE PATCH_PLUS_ONE
            MAJOR_PLUS_ONE=$((${MAJOR:-0} + 1))
            MINOR_PLUS_ONE=$((${MINOR:-0} + 1))
            PATCH_PLUS_ONE=$((${PATCH:-0} + 1))

            # Correct vM.N.P
            echo "  **** Correct vM.N.P *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR.$PATCH" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            # The assert function is dynamically set. If it's BYOB with checkout-sha1 set
            # this needs to fail.
            "${assert_fn}" "$?" "0" "$MAJOR.$MINOR.$PATCH versioned-tag vM.N.P ($MAJOR.$MINOR.$PATCH) should be correct"

            # Correct vM.N
            echo "  **** Correct vM.N *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            # The assert function is dynamically set. If it's BYOB with checkout-sha1 set
            # this needs to fail.
            "${assert_fn}" "$?" "0" "$MAJOR.$MINOR versioned-tag vM.N ($MAJOR.$MINOR) should be correct"

            # Correct vM
            echo "  **** Correct vM *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            # The assert function is dynamically set. If it's BYOB with checkout-sha1 set
            # this needs to fail.
            "${assert_fn}" "$?" "0" "$MAJOR versioned-tag vm ($MAJOR) should be correct"

            # Incorrect v(M-1)
            echo "  **** Incorrect v(M-1) *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR_LESS_ONE" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_not_eq "$?" "0" "$MAJOR_LESS_ONE versioned-tag should be incorrect"

            # Incorrect v(M-1).N
            echo "  **** Incorrect v(M-1).N *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR_LESS_ONE.$MINOR" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_not_eq "$?" "0" "$MAJOR_LESS_ONE.$MINOR versioned-tag should be incorrect"

            # Incorrect v(M-1).N.P
            echo "  **** Incorrect v(M-1).N.P *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR_LESS_ONE.$MINOR.$PATCH" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_not_eq "$?" "0" "$MAJOR_LESS_ONE.$MINOR.$PATCH versioned-tag should be incorrect"

            # Incorrect vM.(N-1)
            echo "  **** Incorrect vM.(N-1) *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR_LESS_ONE" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_LESS_ONE versioned-tag should be incorrect"

            # Incorrect vM.(N-1).P
            echo "  **** Incorrect vM.(N-1).P *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR_LESS_ONE.$PATCH" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_LESS_ONE.$PATCH versioned-tag should be incorrect"

            # Incorrect vM.N.(P-1)
            echo "  **** Incorrect vM.N.(P-1) *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR.$PATCH_LESS_ONE" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR.$PATCH_LESS_ONE versioned-tag should be incorrect"

            # Incorrect v(M+1)
            echo "  **** Incorrect v(M+1) *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR_PLUS_ONE" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_not_eq "$?" "0" "$MAJOR_PLUS_ONE versioned-tag should be incorrect"

            # Incorrect v(M+1).N
            echo "  **** Incorrect v(M+1).N *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR_PLUS_ONE.$MINOR" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_not_eq "$?" "0" "$MAJOR_PLUS_ONE.$MINOR versioned-tag should be incorrect"

            # Incorrect v(M+1).N.P
            echo "  **** Incorrect v(M+1).N.P *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR_PLUS_ONE.$MINOR.$PATCH" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_not_eq "$?" "0" "$MAJOR_PLUS_ONE.$MINOR.$PATCH versioned-tag should be incorrect"

            # Incorrect vM.(N+1)
            echo "  **** Incorrect vM.(N+1) *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR_PLUS_ONE" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_PLUS_ONE versioned-tag should be incorrect"

            # Incorrect vM.(N+1).P
            echo "  **** Incorrect vM.(N+1).P *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR_PLUS_ONE.$PATCH" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_PLUS_ONE.$PATCH versioned-tag should be incorrect"

            # Incorrect vM.N.(P+1)
            echo "  **** Incorrect vM.N.(P+1) *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR.$PATCH_PLUS_ONE" "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR.$PATCH_PLUS_ONE versioned-tag should be incorrect"
        else
            # Wrong versioned-tag
            echo "  **** Wrong versioned-tag *****"
            $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" v1.2.3 "${artifactAndbuilderMinArgs[@]}" "${provenanceArg[@]}" "${packageArg[@]}" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_not_eq "$?" "0" "wrong versioned-tag"
        fi
    fi
}

# Runs a verification command for each version of slsa-verifier.
# $1: The minimum verifier version to check. The minimum version can be "HEAD".
# $2: The maximum verifier version to check.
e2e_run_verifier_all_releases() {
    local verifier_repository="slsa-framework/slsa-verifier"
    local verifier_binary="slsa-verifier-linux-amd64"

    # First, verify provenance with the verifier at HEAD.
    # TODO: Verify provenance with verifier at v1 HEAD?
    go env -w GOFLAGS=-mod=mod

    # NOTE: clean the cache to avoid "module github.com/slsa-framework/slsa-verifier@main found" errors.
    # See: https://stackoverflow.com/questions/62974985/go-module-latest-found-but-does-not-contain-package
    # TODO(#212): remove once we understand why go install doesn't work.
    go clean -cache
    go clean -modcache

    # TODO(#212): remove retries once we understand why go install doesn't work.
    for _ in 1 2 3 4 5; do
        if go install "github.com/${verifier_repository}/v2/cli/slsa-verifier@main"; then
            break
        fi
        echo "ERROR: Failed to go-install slsa-verifier. retrying...."
    done
    echo "**** Verifying provenance authenticity with verifier at HEAD *****"
    verify_provenance_authenticity "slsa-verifier" "HEAD"

    # If the minimum version is HEAD then we are done.
    if [ "$1" == "HEAD" ]; then
        return 0
    fi

    # Second, retrieve all previous versions of the verifier,
    # and verify the provenance. This is essentially regression tests.
    local release_list
    release_list=$(gh release -R "${verifier_repository}" -L 100 list)
    echo "Releases found:"
    echo "${release_list}"
    echo

    while read -r line; do
        local TAG
        TAG=$(echo "$line" | cut -f1)

        # Check minimum verifier version
        if [ "$1" != "" ] && version_lt "$TAG" "$1"; then
            continue
        fi

        # Check maximum verifier version
        if [ "$2" != "" ] && version_gt "$TAG" "$2"; then
            continue
        fi

        # Check pre-release status
        local PRE_RELEASE
        PRE_RELEASE=$(echo "$line" | cut -f2)
        if [ "$PRE_RELEASE" == "Pre-release" ] || [ "$(version_pre "$TAG")" != "" ]; then
            continue
        fi

        # Check if a greater patch version exists
        MAJOR=$(version_major "$TAG")
        MINOR=$(version_minor "$TAG")
        PATCH=$(version_patch "$TAG")
        PATCH_PLUS_ONE=$((${PATCH:-0} + 1))
        if grep -q "v$MAJOR.$MINOR.$PATCH_PLUS_ONE" <<<"${release_list}"; then
            continue
        fi

        echo "  *** Starting with verifier at $TAG ****"

        # Always remove the binary, because `gh release download` fails if the file already exists.
        if [[ -f "${verifier_binary}" ]]; then
            # Note: Don't quote `$VERIFIER_BINARY*`, as it will cause new lines to be inserted and
            # deletion will fail.
            rm ${verifier_binary}*
        fi

        gh release -R "${verifier_repository}" download "$TAG" -p "${verifier_binary}*" || exit 10

        # Use the compiled verifier at main to verify the provenance (Optional)
        slsa-verifier verify-artifact "${verifier_binary}" \
            --source-branch "main" \
            --source-tag "$TAG" \
            --provenance-path "${verifier_binary}.intoto.jsonl" \
            --source-uri "github.com/${verifier_repository}" ||
            slsa-verifier verify-artifact "${verifier_binary}" \
                --source-branch "release/v$MAJOR.$MINOR" \
                --source-tag "$TAG" \
                --provenance-path "${verifier_binary}.intoto.jsonl" \
                --source-uri "github.com/${verifier_repository}" || exit 6

        echo "**** Verifying provenance authenticity with verifier at $TAG ****"
        chmod a+x "./${verifier_binary}"
        verify_provenance_authenticity "./${verifier_binary}" "$TAG"
    done <<<"${release_list}"
}

# e2e_verifier_arg_transformer returns an argument transformer
# $1
e2e_verifier_arg_transformer() {
    local tag="$1"
    if [[ "$tag" == "HEAD" ]] || version_ge "$tag" "v1.4"; then
        echo "_new_verifier_args"
    else
        echo "_old_verifier_args"
    fi
}

_old_verifier_args() {
    local arg="$1"
    case $arg in
    artifact-path) echo '--artifact-path' ;;
    provenance) echo '--provenance' ;;
    source) echo '--source' ;;
    tag) echo '--tag' ;;
    versioned-tag) echo '--versioned-tag' ;;
    workflow-input) echo '--workflow-input' ;;
    branch) echo '--branch' ;;
    esac
}

_new_verifier_args() {
    local arg="$1"
    case $arg in
    artifact-path) echo '' ;;
    provenance) echo '--provenance-path' ;;
    provenance-repository) echo '--provenance-repository' ;;
    source) echo '--source-uri' ;;
    tag) echo '--source-tag' ;;
    versioned-tag) echo '--source-versioned-tag' ;;
    workflow-input) echo '--build-workflow-input' ;;
    branch) echo '--source-branch' ;;
    esac
}

# Verifies the content of a decoded slsa token.
# $1: The decoded token
# $2: A boolean whether masked inputs are used
e2e_verify_decoded_token() {
    local decoded_token="$1"

    # Script Inputs
    CHECKOUT_FETCH_DEPTH=${CHECKOUT_FETCH_DEPTH:-}
    CHECKOUT_SHA1=${CHECKOUT_SHA1:-}

    GITHUB_ACTOR_ID=${GITHUB_ACTOR_ID:-}
    GITHUB_EVENT_NAME=${GITHUB_EVENT_NAME:-}
    GITHUB_REF=${GITHUB_REF:-}
    GITHUB_REF_TYPE=${GITHUB_REF_TYPE:-}
    GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-}
    GITHUB_REPOSITORY_ID=${GITHUB_REPOSITORY_ID:-}
    GITHUB_REPOSITORY_OWNER=${GITHUB_REPOSITORY_OWNER:-}
    GITHUB_RUN_ATTEMPT=${GITHUB_RUN_ATTEMPT:-}
    GITHUB_RUN_ID=${GITHUB_RUN_ID:-}
    GITHUB_RUN_NUMBER=${GITHUB_RUN_NUMBER:-}
    GITHUB_SHA=${GITHUB_SHA:-}
    GITHUB_WORKFLOW_REF=${GITHUB_WORKFLOW_REF:-}
    GITHUB_WORKFLOW_SHA=${GITHUB_WORKFLOW_SHA:-}

    # Non-GitHub's information.
    _e2e_verify_query "$decoded_token" "delegator_generic_slsa3.yml" '.builder.audience'
    _e2e_verify_query "$decoded_token" "ubuntu-latest" '.builder.runner_label'
    _e2e_verify_query "$decoded_token" "true" '.builder.rekor_log_public'
    _e2e_verify_query "$decoded_token" "./actions/build-artifacts-composite" '.tool.actions.build_artifacts.path'
    _e2e_verify_query "$decoded_token" "${CHECKOUT_FETCH_DEPTH}" '.source.checkout.fetch_depth'
    _e2e_verify_query "$decoded_token" "${CHECKOUT_SHA1}" '.source.checkout.sha1'
    _e2e_verify_query "$decoded_token" '{"name1":"value1","name2":"value2","name3":"value3","name4":"","name5":"value5","name6":"value6","private-repository":true}' '.tool.inputs'

    # GitHub's information.
    _e2e_verify_query "$decoded_token" "$GITHUB_ACTOR_ID" '.github.actor_id'
    _e2e_verify_query "$decoded_token" "$GITHUB_EVENT_NAME" '.github.event_name'
    _e2e_verify_query "$decoded_token" "$GITHUB_REF" '.github.ref'
    _e2e_verify_query "$decoded_token" "$GITHUB_REF_TYPE" '.github.ref_type'
    _e2e_verify_query "$decoded_token" "$GITHUB_REPOSITORY" '.github.repository'
    _e2e_verify_query "$decoded_token" "$GITHUB_REPOSITORY_ID" '.github.repository_id'
    _e2e_verify_query "$decoded_token" "$GITHUB_REPOSITORY_OWNER_ID" '.github.repository_owner_id'
    _e2e_verify_query "$decoded_token" "$GITHUB_RUN_ATTEMPT" '.github.run_attempt'
    _e2e_verify_query "$decoded_token" "$GITHUB_RUN_ID" '.github.run_id'
    _e2e_verify_query "$decoded_token" "$GITHUB_RUN_NUMBER" '.github.run_number'
    _e2e_verify_query "$decoded_token" "$GITHUB_SHA" '.github.sha'
    _e2e_verify_query "$decoded_token" "$GITHUB_WORKFLOW_REF" '.github.workflow_ref'
    _e2e_verify_query "$decoded_token" "$GITHUB_WORKFLOW_SHA" '.github.workflow_sha'
}
