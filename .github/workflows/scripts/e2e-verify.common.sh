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
    jq -c ".payload = \"$(echo "$2" | base64 -w0)\"" <"$1"
}

# verify_provenance_authenticity is a function that verifies the authenticity of
# the provenance using slsa-verifier.
# $1: The path to the slsa-verifier binary.
# $2: The slsa-verifier version's git tag.
verify_provenance_authenticity() {
    local verifier="$1"
    local tag="$2"
    local annotated_tags
    annotated_tags=$(echo "$THIS_FILE" | cut -d '.' -f5 | grep annotated || true)

    # TODO: Currently we only support $BINARY artifacts, not containers.
    verifierCmd="$verifier"
    if [[ "$tag" == HEAD ]] || version_gt "$tag" "v1.3.0"; then
        verifierCmd="$verifier verify-artifact"
    fi
    # This transforms the argument name depending on the verifier tag.
    argr=$(e2e_verifier_arg_transformer "$tag")
    read -ra artifactArg <<<"$($argr "artifact-path")"
    read -ra provenanceArg <<<"$($argr "provenance")"
    read -ra sourceArg <<<"$($argr "source")"
    read -ra tagArg <<<"$($argr "tag")"
    read -ra branchArg <<<"$($argr "branch")"
    read -ra vTagArg <<<"$($argr "versioned-tag")"
    read -ra workflowInputArg <<<"$($argr "workflow-input")"

    if version_le "$tag" "v1.0.0"; then
        if [[ "$GITHUB_EVENT_NAME" == "release" ]]; then
            echo "  INFO: release trigger at v1.0.0: skipping authenticity verification due to lack of support (https://github.com/slsa-framework/slsa-verifier/pull/89)"
            return 0
        fi
    fi

    multi_subjects=$(echo "$THIS_FILE" | cut -d '.' -f5 | grep multi-subjects)
    if [[ -n "$multi_subjects" ]] && version_lt "$tag" "v1.2.0"; then
        echo "  INFO: multiple subject verification at $tag: skipping due to lack of support (https://github.com/slsa-framework/slsa-verifier/pull/112)"
        return 0
    fi

    # Default parameters.
    # After v1.2.0, branch verification is optional, so we can always verify,
    # regardless of the branch value.
    # https://github.com/slsa-framework/slsa-verifier/pull/192
    if [[ "$tag" == "HEAD" ]] || version_gt "$tag" "v1.2.0"; then
        echo "  **** Default parameters (annotated tags) *****"
        $verifierCmd "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_eq "$?" "0" "not main default parameters"
    elif [[ -z "$annotated_tags" ]]; then
        # Until v1.2.0, we verified the default branch as "main".
        if [[ "$BRANCH" == "main" ]]; then
            echo "  **** Default parameters (main) *****"
            $verifierCmd "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_eq "$?" "0" "main default parameters"
        else
            echo "  **** Default parameters *****"
            $verifierCmd "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
            e2e_assert_not_eq "$?" "0" "not main default parameters"
        fi
    fi

    branchOpts=("${branchArgs[@]}")
    branchOpts+=("$BRANCH")
    if [[ -n "$annotated_tags" ]]; then
        branchOpts=()
        # Annotated tags don't have a branch to verify, so we bail early for versions that always verify the branch.
        # See https://github.com/slsa-framework/slsa-verifier/issues/193.
        if version_le "$tag" "v1.2.0"; then
            echo "  INFO: annotated tag verification at $tag: skipping due to lack of support (https://github.com/slsa-framework/slsa-verifier/issues/193)"
            return 0
        fi
    fi

    # Workflow inputs
    workflow_inputs=$(echo "$THIS_FILE" | cut -d '.' -f5 | grep workflow_inputs)
    if [[ -n "$workflow_inputs" ]] && version_gt "$tag" "v1.2.0"; then
        echo "  **** Correct Workflow Inputs *****"
        $verifierCmd "${branchOpts[@]}" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY" "${workflowInputArg[@]}" test=true
        e2e_assert_eq "$?" "0" "should be workflow inputs"

        echo "  **** Wrong Workflow Inputs *****"
        $verifierCmd "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY" "${workflowInputArg[@]}" test=false
        e2e_assert_not_eq "$?" "0" "wrong workflow inputs"
    fi

    # Correct branch.
    echo "  **** Correct branch *****"
    $verifierCmd "${branchOpts[@]}" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
    e2e_assert_eq "$?" "0" "should be branch $BRANCH"

    # Wrong branch
    echo "  **** Wrong branch *****"
    $verifierCmd "${branchArg[@]}" "not-$GITHUB_REF_NAME" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "wrong branch"

    # Wrong tag
    echo "  **** Wrong tag *****"
    $verifierCmd "${tagArg[@]}" v1.2.3 "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "wrong tag"

    echo "  **** Wrong payload *****"
    local BAD_PROV
    BAD_PROV="$(mktemp -t slsa-e2e.XXXXXXXX)"
    e2e_set_payload "$PROVENANCE" '{"foo": "bar"}' >"$BAD_PROV"
    $verifierCmd "${branchOpts[@]}" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$BAD_PROV" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "wrong payload"

    if [[ "$GITHUB_REF_TYPE" == "tag" ]]; then
        #TODO: try several versioned-tags and tags.
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
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR.$PATCH" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_eq "$?" "0" "$MAJOR.$MINOR.$PATCH versioned-tag vM.N.P ($MAJOR.$MINOR.$PATCH) should be correct"

        # Correct vM.N
        echo "  **** Correct vM.N *****"
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_eq "$?" "0" "$MAJOR.$MINOR versioned-tag vM.N ($MAJOR.$MINOR) should be correct"

        # Correct vM
        echo "  **** Correct vM *****"
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_eq "$?" "0" "$MAJOR versioned-tag vm ($MAJOR) should be correct"

        # Incorrect v(M-1)
        echo "  **** Incorrect v(M-1) *****"
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR_LESS_ONE" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_LESS_ONE versioned-tag should be incorrect"

        # Incorrect v(M-1).N
        echo "  **** Incorrect v(M-1).N *****"
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR_LESS_ONE.$MINOR" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_LESS_ONE.$MINOR versioned-tag should be incorrect"

        # Incorrect v(M-1).N.P
        echo "  **** Incorrect v(M-1).N.P *****"
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR_LESS_ONE.$MINOR.$PATCH" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_LESS_ONE.$MINOR.$PATCH versioned-tag should be incorrect"

        # Incorrect vM.(N-1)
        echo "  **** Incorrect vM.(N-1) *****"
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR_LESS_ONE" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_LESS_ONE versioned-tag should be incorrect"

        # Incorrect vM.(N-1).P
        echo "  **** Incorrect vM.(N-1).P *****"
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR_LESS_ONE.$PATCH" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_LESS_ONE.$PATCH versioned-tag should be incorrect"

        # Incorrect vM.N.(P-1)
        echo "  **** Incorrect vM.N.(P-1) *****"
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR.$PATCH_LESS_ONE" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR.$PATCH_LESS_ONE versioned-tag should be incorrect"

        # Incorrect v(M+1)
        echo "  **** Incorrect v(M+1) *****"
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR_PLUS_ONE" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_PLUS_ONE versioned-tag should be incorrect"

        # Incorrect v(M+1).N
        echo "  **** Incorrect v(M+1).N *****"
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR_PLUS_ONE.$MINOR" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_PLUS_ONE.$MINOR versioned-tag should be incorrect"

        # Incorrect v(M+1).N.P
        echo "  **** Incorrect v(M+1).N.P *****"
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR_PLUS_ONE.$MINOR.$PATCH" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_PLUS_ONE.$MINOR.$PATCH versioned-tag should be incorrect"

        # Incorrect vM.(N+1)
        echo "  **** Incorrect vM.(N+1) *****"
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR_PLUS_ONE" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_PLUS_ONE versioned-tag should be incorrect"

        # Incorrect vM.(N+1).P
        echo "  **** Incorrect vM.(N+1).P *****"
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR_PLUS_ONE.$PATCH" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_PLUS_ONE.$PATCH versioned-tag should be incorrect"

        # Incorrect vM.N.(P+1)
        echo "  **** Incorrect vM.N.(P+1) *****"
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" "v$MAJOR.$MINOR.$PATCH_PLUS_ONE" "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR.$PATCH_PLUS_ONE versioned-tag should be incorrect"
    else
        # Wrong versioned-tag
        echo "  **** Wrong versioned-tag *****"
        $verifierCmd "${branchOpts[@]}" "${vTagArg[@]}" v1.2.3 "${artifactArg[@]}" "$BINARY" "${provenanceArg[@]}" "$PROVENANCE" "${sourceArg[@]}" "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "wrong versioned-tag"
    fi
}

# Runs a verification command for each version of slsa-verifier.
# $1: The minimum verifier version to check. The minimum version can be "HEAD".
# $2: The maximum verifier version to check.
e2e_run_verifier_all_releases() {
    local VERIFIER_REPOSITORY="slsa-framework/slsa-verifier"
    local VERIFIER_BINARY="slsa-verifier-linux-amd64"

    # First, verify provenance with the verifier at HEAD.
    go env -w GOFLAGS=-mod=mod
    go install "github.com/$VERIFIER_REPOSITORY/cli/slsa-verifier@main"
    echo "**** Verifying provenance authenticity with verifier at HEAD *****"
    verify_provenance_authenticity "slsa-verifier" "HEAD"

    # If the minimum version is HEAD then we are done.
    if [ "$1" == "HEAD" ]; then
        return 0
    fi

    # Second, retrieve all previous versions of the verifier,
    # and verify the provenance. This is essentially regression tests.
    local RELEASE_LIST
    RELEASE_LIST=$(gh release -R "$VERIFIER_REPOSITORY" -L 100 list)
    echo "Releases found:"
    echo "$RELEASE_LIST"
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

        # Check if a greater patch version exists
        MAJOR=$(version_major "$TAG")
        MINOR=$(version_minor "$TAG")
        PATCH=$(version_patch "$TAG")
        PATCH_PLUS_ONE=$((${PATCH:-0} + 1))
        if grep -q "v$MAJOR.$MINOR.$PATCH_PLUS_ONE" <<<"$RELEASE_LIST"; then
            continue
        fi

        echo "  *** Starting with verifier at $TAG ****"

        # Always remove the binary, because `gh release download` fails if the file already exists.
        if [[ -f "$VERIFIER_BINARY" ]]; then
            # Note: Don't quote `$VERIFIER_BINARY*`, as it will cause new lines to be inserted and
            # deletion will fail.
            rm $VERIFIER_BINARY*
        fi

        gh release -R "$VERIFIER_REPOSITORY" download "$TAG" -p "$VERIFIER_BINARY*" || exit 10

        # Use the compiled verifier at main to verify the provenance (Optional)
        slsa-verifier verify-artifact "$VERIFIER_BINARY" \
            --source-branch "main" \
            --source-tag "$TAG" \
            --provenance-path "$VERIFIER_BINARY.intoto.jsonl" \
            --source-uri "github.com/$VERIFIER_REPOSITORY" ||
            slsa-verifier verify-artifact "$VERIFIER_BINARY" \
                --source-branch "release/v$MAJOR.$MINOR" \
                --source-tag "$TAG" \
                --provenance-path "$VERIFIER_BINARY.intoto.jsonl" \
                --source-uri "github.com/$VERIFIER_REPOSITORY" || exit 6

        echo "**** Verifying provenance authenticity with verifier at $TAG ****"
        chmod a+x "./$VERIFIER_BINARY"
        verify_provenance_authenticity "./$VERIFIER_BINARY" "$TAG"
    done <<<"$RELEASE_LIST"
}

# e2e_verifier_arg_transformer returns an argument transformer
# $1
e2e_verifier_arg_transformer() {
    local tag="$1"
    if [[ "$tag" == HEAD ]] || version_gt "$tag" "v1.3.0"; then
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
    source) echo '--source-uri' ;;
    tag) echo '--source-tag' ;;
    versioned-tag) echo '--source-versioned-tag' ;;
    workflow-input) echo '--build-orkflow-input' ;;
    branch) echo '--source-branch' ;;
    esac
}
