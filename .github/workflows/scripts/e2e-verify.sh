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

source "./.github/workflows/scripts/e2e-utils.sh"

# Function used to verify provenance.
verify_provenance() {
    local verifier="$1"
    local version="$2"
    
    # Default parameters.
    if [[ "$BRANCH" == "main" ]]; then
        echo "  **** Default parameters (main) *****"
        $verifier --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_eq "$?" "0" "main default parameters"
    else
        echo "  **** Default parameters *****"
        $verifier --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "not main default parameters"
    fi

    # Correct branch
    echo "  **** Correct branch *****"
    $verifier --branch "$BRANCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_eq "$?" "0" "should be branch $BRANCH"

    # Wrong branch
    echo "  **** Wrong branch *****"
    $verifier --branch "not-$GITHUB_REF_NAME" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "wrong branch"

    # Wrong tag
    echo "  **** Wrong branch *****"
    $verifier --tag v1.2.3 --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "wrong tag"

    if [[ "$GITHUB_REF_TYPE" == "tag" ]]; then
        #TODO: try several versioned-tags and tags.
        SEMVER="$GITHUB_REF_NAME"
        PATCH=$(echo "$SEMVER" | cut -d '.' -f3)
        MINOR=$(echo "$SEMVER" | cut -d '.' -f2)
        MAJOR=$(echo "$SEMVER" | cut -d '.' -f1)

        M="${MAJOR:1}"
        MAJOR_LESS_ONE="v$((M - 1))"
        MINOR_LESS_ONE=$((MINOR - 1))
        PATCH_LESS_ONE=$((PATCH - 1))
        MAJOR_PLUS_ONE="v$((M + 1))"
        MINOR_PLUS_ONE=$((MINOR + 1))
        PATCH_PLUS_ONE=$((PATCH + 1))

        # Correct vM.N.P
        echo "  **** Correct vM.N.P *****"
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR.$PATCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_eq "$?" "0" "$MAJOR.$MINOR.$PATCH versioned-tag vM.N.P ($MAJOR.$MINOR.$PATCH) should be correct"

        # Correct vM.N
        echo "  **** Correct vM.N *****"
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_eq "$?" "0" "$MAJOR.$MINOR versioned-tag vM.N ($MAJOR.$MINOR) should be correct"

        # Correct vM
        echo "  **** Correct vM *****"
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_eq "$?" "0" "$MAJOR versioned-tag vm ($MAJOR) should be correct"

        # Incorrect v(M-1)
        echo "  **** Incorrect v(M-1) *****"
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR_LESS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_LESS_ONE versioned-tag should be incorrect"

        # Incorrect v(M-1).N
        echo "  **** Incorrect v(M-1).N *****"
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR_LESS_ONE.$MINOR" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_LESS_ONE.$MINOR versioned-tag should be incorrect"

        # Incorrect v(M-1).N.P
        echo "  **** Incorrect v(M-1).N.P *****"
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR_LESS_ONE.$MINOR.$PATCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_LESS_ONE.$MINOR.$PATCH versioned-tag should be incorrect"

        # Incorrect vM.(N-1)
        echo "  **** Incorrect vM.(N-1) *****"
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR_LESS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_LESS_ONE versioned-tag should be incorrect"

        # Incorrect vM.(N-1).P
        echo "  **** Incorrect vM.(N-1).P *****"
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR_LESS_ONE.$PATCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_LESS_ONE.$PATCH versioned-tag should be incorrect"

        # Incorrect vM.N.(P-1)
        echo "  **** Incorrect vM.N.(P-1) *****"
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR.$PATCH_LESS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR.$PATCH_LESS_ONE versioned-tag should be incorrect"

        # Incorrect v(M+1)
        echo "  **** Incorrect v(M+1) *****"
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR_PLUS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_PLUS_ONE versioned-tag should be incorrect"

        # Incorrect v(M+1).N
        echo "  **** Incorrect v(M+1).N *****"
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR_PLUS_ONE.$MINOR" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_PLUS_ONE.$MINOR versioned-tag should be incorrect"

        # Incorrect v(M+1).N.P
        echo "  **** Incorrect v(M+1).N.P *****"
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR_PLUS_ONE.$MINOR.$PATCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_PLUS_ONE.$MINOR.$PATCH versioned-tag should be incorrect"

        # Incorrect vM.(N+1)
        echo "  **** Incorrect vM.(N+1) *****"
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR_PLUS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_PLUS_ONE versioned-tag should be incorrect"

        # Incorrect vM.(N+1).P
        echo "  **** Incorrect vM.(N+1).P *****"
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR_PLUS_ONE.$PATCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_PLUS_ONE.$PATCH versioned-tag should be incorrect"

        # Incorrect vM.N.(P+1)
        echo "  **** Incorrect vM.N.(P+1) *****"
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR.$PATCH_PLUS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR.$PATCH_PLUS_ONE versioned-tag should be incorrect"
    else
        # Wrong versioned-tag
        echo "  **** Wrong versioned-tag *****"
        $verifier --branch "$BRANCH" --versioned-tag v1.2.3 --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "wrong versioned-tag"
    fi

    # Provenance content verification.
    ATTESTATION=$(cat "$PROVENANCE" | jq -r '.payload' | base64 -d)
    #TRIGGER=$(echo "$THIS_FILE" | cut -d '.' -f3)
    #BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
    LDFLAGS=$(echo "$THIS_FILE" | cut -d '.' -f5 | grep -v noldflags)
    #DIR=$(echo "$THIS_FILE" | cut -d '.' -f5 | grep '\-dir')
    ASSETS=$(echo "$THIS_FILE" | cut -d '.' -f5 | grep -v noassets)
    # Note GO_MAIN and GO_DIR are set in the workflows as env variables.
    DIR="$PWD"
    if [[ -n "$GO_DIR" ]]; then
        DIR="$DIR/$GO_DIR"
    fi

    echo "  **** Provenance content verification *****"
    e2e_verify_predicate_subject_name "$ATTESTATION" "$BINARY"
    e2e_verify_predicate_builder_id "$ATTESTATION" "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml@refs/heads/main"
    e2e_verify_predicate_builderType "$ATTESTATION" "https://github.com/slsa-framework/slsa-github-generator/go@v1" 

    e2e_verify_predicate_invocation_configSource "$ATTESTATION" "{\"uri\":\"git+https://github.com/$GITHUB_REPOSITORY@$GITHUB_REF\",\"digest\":{\"sha1\":\"$GITHUB_SHA\"},\"entryPoint\":\".github/workflows/$THIS_FILE\"}"

    e2e_verify_predicate_invocation_environment "$ATTESTATION" "github_actor" "$GITHUB_ACTOR"
    e2e_verify_predicate_invocation_environment "$ATTESTATION" "github_sha1" "$GITHUB_SHA"
    e2e_verify_predicate_invocation_environment "$ATTESTATION" "os" "ubuntu20"
    e2e_verify_predicate_invocation_environment "$ATTESTATION" "arch" "X64"
    e2e_verify_predicate_invocation_environment "$ATTESTATION" "github_event_name" "$GITHUB_EVENT_NAME"
    e2e_verify_predicate_invocation_environment "$ATTESTATION" "github_ref" "$GITHUB_REF"
    e2e_verify_predicate_invocation_environment "$ATTESTATION" "github_ref_type" "$GITHUB_REF_TYPE"

    ACTOR_ID=$(gh api -H "Accept: application/vnd.github.v3+json" /users/"$GITHUB_ACTOR" | jq -r '.id')
    OWNER_ID=$(gh api -H "Accept: application/vnd.github.v3+json" /users/"$GITHUB_REPOSITORY_OWNER" | jq -r '.id')
    REPO_ID=$(gh api -H "Accept: application/vnd.github.v3+json"  /repos/"$GITHUB_REPOSITORY" | jq -r '.id')
    e2e_verify_predicate_invocation_environment "$ATTESTATION" "github_actor_id" "$ACTOR_ID"
    e2e_verify_predicate_invocation_environment "$ATTESTATION" "github_repository_owner_id" "$OWNER_ID"
    e2e_verify_predicate_invocation_environment "$ATTESTATION" "github_repository_id" "$REPO_ID"

    # First step is vendoring
    e2e_verify_predicate_buildConfig_step_command "0" "$ATTESTATION" "[\"mod\",\"vendor\"]"
    e2e_verify_predicate_buildConfig_step_env "0" "$ATTESTATION" "[]"
    e2e_verify_predicate_buildConfig_step_workingDir "0" "$ATTESTATION" "$DIR"

    # Second step is the actual compilation.
    e2e_verify_predicate_buildConfig_step_env "1" "$ATTESTATION" "[\"GOOS=linux\",\"GOARCH=amd64\",\"GO111MODULE=on\",\"CGO_ENABLED=0\"]"
    e2e_verify_predicate_buildConfig_step_workingDir "1" "$ATTESTATION" "$DIR"

    if [[ -z "$LDFLAGS" ]]; then
        e2e_verify_predicate_buildConfig_step_command "1" "$ATTESTATION" "[\"build\",\"-mod=vendor\",\"-trimpath\",\"-tags=netgo\",\"-o\",\"$BINARY\"]"
    else
        chmod a+x ./"$BINARY"
    
        if [[ -z "$GO_MAIN" ]]; then
            e2e_verify_predicate_buildConfig_step_command "1" "$ATTESTATION" "[\"build\",\"-mod=vendor\",\"-trimpath\",\"-tags=netgo\",\"-ldflags=-X main.gitVersion=v1.2.3 -X main.gitCommit=abcdef -X main.gitBranch=$BRANCH\",\"-o\",\"$BINARY\"]"
        else
            e2e_verify_predicate_buildConfig_step_command "1" "$ATTESTATION" "[\"build\",\"-mod=vendor\",\"-trimpath\",\"-tags=netgo\",\"-ldflags=-X main.gitVersion=v1.2.3 -X main.gitCommit=abcdef -X main.gitBranch=$BRANCH -X main.gitMain=$GO_MAIN\",\"-o\",\"$BINARY\",\"$GO_MAIN\"]"
            M=$(./"$BINARY" | grep "GitMain: $GO_MAIN")
            e2e_assert_not_eq "$M" "" "GitMain should not be empty"
        fi

        V=$(./"$BINARY" | grep 'GitVersion: v1.2.3')
        C=$(./"$BINARY" | grep 'GitCommit: abcdef')
        B=$(./"$BINARY" | grep "GitBranch: $BRANCH")
        e2e_assert_not_eq "$V" "" "GitVersion should not be empty"
        e2e_assert_not_eq "$C" "" "GitCommit should not be empty"
        e2e_assert_not_eq "$B" "" "GitBranch should not be empty"
    fi

    e2e_verify_predicate_metadata "$ATTESTATION" "{\"buildInvocationID\":\"$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT\",\"completeness\":{\"parameters\":true,\"environment\":false,\"materials\":false},\"reproducible\":false}"
    e2e_verify_predicate_materials "$ATTESTATION" "{\"uri\":\"git+https://github.com/$GITHUB_REPOSITORY@$GITHUB_REF\",\"digest\":{\"sha1\":\"$GITHUB_SHA\"}}"

    if [[ "$GITHUB_REF_TYPE" == "tag" ]]; then
        A=$(gh release view --json assets "$GITHUB_REF_NAME" | jq -r '.assets | .[0].name, .[1].name' | jq -R -s -c 'split("\n") | map(select(length > 0))')
        if [[ -z "$ASSETS" ]]; then
            e2e_assert_eq "$A" "[\"null\",\"null\"]" "there should be no assets"
        else
            e2e_assert_eq "$A" "[\"$BINARY\",\"$BINARY.intoto.jsonl\"]" "there should be assets"
        fi
    fi

    #TODO: read out the provenance information once we print it
}

# =====================================
# ===== main execution starts =========
# =====================================

# Get the filename. Note: requires GH_TOKEN to be set in the workflows.
THIS_FILE=$(gh api -H "Accept: application/vnd.github.v3+json" "/repos/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID" | jq -r '.path' | cut -d '/' -f3)

BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)

echo "branch is $BRANCH"
echo "GITHUB_REF_NAME: $GITHUB_REF_NAME"
echo "GITHUB_REF_TYPE: $GITHUB_REF_TYPE"
echo "GITHUB_REF: $GITHUB_REF"
echo "DEBUG: file is $THIS_FILE"

VERIFIER_REPOSITORY="slsa-framework/slsa-verifier"
VERIFIER_BINARY="slsa-verifier-linux-amd64"

# First, verify provenance with the verifier at HEAD.
go env -w GOFLAGS=-mod=mod
go install "github.com/$VERIFIER_REPOSITORY@latest"
echo "**** Verifying provenance with verifier at HEAD *****"
verify_provenance "slsa-verifier" "HEAD"

# Second, retrieve all previous versions of the verifier,
# and verify the provenance. This is essentially regression tests.
RELEASE_LIST=$(gh release -R "$VERIFIER_REPOSITORY" -L 100 list)
echo "Releases found:"
echo "$RELEASE_LIST"
echo

while read line; do
    TAG=$(echo "$line" | cut -f1)

    # Always remove the binary, because `gh release download` fails if the file already exists.
    rm "$VERIFIER_BINARY*" 2>/dev/null
    gh release -R "$VERIFIER_REPOSITORY" download "$TAG" -p "$VERIFIER_BINARY*" || exit 10

    # Use the compiled verifier to verify the provenance (Optional)
    slsa-verifier --branch "main" \
                    --tag "$TAG" \
                    --artifact-path "$VERIFIER_BINARY" \
                    --provenance "$VERIFIER_BINARY.intoto.jsonl" \
                    --source "github.com/$VERIFIER_REPOSITORY" || exit 6

    echo "**** Verifying provenance with verifier at $TAG ****"
    chmod a+x "./$VERIFIER_BINARY"
    verify_provenance "./$VERIFIER_BINARY" "$TAG"

done <<< "$RELEASE_LIST"


