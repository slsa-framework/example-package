#!/usr/bin/env bash

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

go env -w GOFLAGS=-mod=mod

# Install from HEAD
go install github.com/slsa-framework/slsa-verifier@latest
    
# Default parameters.
if [[ "$GITHUB_REF_NAME" == "main" ]] && [[ "$GITHUB_REF_TYPE" == "branch" ]]; then
    slsa-verifier --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_eq "$?" "0" "default parameters"
fi 

# Correct branch
BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
slsa-verifier --branch "$BRANCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
e2e_assert_eq "$?" "0" "should be $BRANCH branch"

# Wrong branch
slsa-verifier --branch "not-$GITHUB_REF_NAME" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
e2e_assert_not_eq "$?" "0" "wrong branch"

# Wrong tag
slsa-verifier --tag v1.2.3 --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
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
    slsa-verifier --versioned-tag "$MAJOR.$MINOR.$PATCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_eq "$?" "0" "$MAJOR.$MINOR.$PATCH versioned-tag should be correct"

    # Correct vM.N
    slsa-verifier --versioned-tag "$MAJOR.$MINOR" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_eq "$?" "0" "$MAJOR.$MINOR versioned-tag should be correct"

    # Correct vM
    slsa-verifier --versioned-tag "$MAJOR" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_eq "$?" "0" "$MAJOR versioned-tag should be correct"

    # Incorrect v(M-1)
    slsa-verifier --versioned-tag "$MAJOR_LESS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "$MAJOR_LESS_ONE versioned-tag should be incorrect"

    # Incorrect v(M-1).N
    slsa-verifier --versioned-tag "$MAJOR_LESS_ONE.$MINOR" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "$MAJOR_LESS_ONE.$MINOR versioned-tag should be incorrect"

    # Incorrect v(M-1).N.P
    slsa-verifier --versioned-tag "$MAJOR_LESS_ONE.$MINOR.$PATCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "$MAJOR_LESS_ONE.$MINOR.$PATCH versioned-tag should be incorrect"

    # Incorrect vM.(N-1)
    slsa-verifier --versioned-tag "$MAJOR.$MINOR_LESS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_LESS_ONE versioned-tag should be incorrect"

    # Incorrect vM.(N-1).P
    slsa-verifier --versioned-tag "$MAJOR.$MINOR_LESS_ONE.$PATCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_LESS_ONE.$PATCH versioned-tag should be incorrect"

    # Incorrect vM.N.(P-1)
    slsa-verifier --versioned-tag "$MAJOR.$MINOR.$PATCH_LESS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR.$PATCH_LESS_ONE versioned-tag should be incorrect"

    # Incorrect v(M+1)
    slsa-verifier --versioned-tag "$MAJOR_PLUS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "$MAJOR_PLUS_ONE versioned-tag should be incorrect"

    # Incorrect v(M+1).N
    slsa-verifier --versioned-tag "$MAJOR_PLUS_ONE.$MINOR" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "$MAJOR_PLUS_ONE.$MINOR versioned-tag should be incorrect"

    # Incorrect v(M+1).N.P
    slsa-verifier --versioned-tag "$MAJOR_PLUS_ONE.$MINOR.$PATCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "$MAJOR_PLUS_ONE.$MINOR.$PATCH versioned-tag should be incorrect"

    # Incorrect vM.(N+1)
    slsa-verifier --versioned-tag "$MAJOR.$MINOR_PLUS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_PLUS_ONE versioned-tag should be incorrect"

    # Incorrect vM.(N+1).P
    slsa-verifier --versioned-tag "$MAJOR.$MINOR_PLUS_ONE.$PATCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_PLUS_ONE.$PATCH versioned-tag should be incorrect"

    # Incorrect vM.N.(P+1)
    slsa-verifier --versioned-tag "$MAJOR.$MINOR.$PATCH_PLUS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR.$PATCH_PLUS_ONE versioned-tag should be incorrect"
else
    # Wrong versioned-tag
    slsa-verifier --versioned-tag v1.2.3 --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "wrong versioned-tag"
fi

# Provenance content verification.
ATTESTATION=$(cat ""$PROVENANCE"" | jq -r '.payload' | base64 -d)
#TRIGGER=$(echo "$THIS_FILE" | cut -d '.' -f3)
#BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
LDFLAGS=$(echo "$THIS_FILE" | cut -d '.' -f5 | grep -v noldflags)
ASSETS=$(echo "$THIS_FILE" | cut -d '.' -f5 | grep -v noassets)

e2e_verify_predicate_subject_name "$ATTESTATION" "binary-linux-amd64"
e2e_verify_predicate_builder_id "$ATTESTATION" "https://github.com/slsa-framework/slsa-github-generator-go/.github/workflows/slsa3_builder.yml@refs/heads/main"
e2e_verify_predicate_builderType "$ATTESTATION" "https://github.com/slsa-framework/slsa-github-generator-go@v1"

e2e_verify_predicate_invocation_configSource "$ATTESTATION" "{\"uri\":\"git+https://"github.com/$GITHUB_REPOSITORY"@$GITHUB_REF\",\"digest\":{\"sha1\":\"$GITHUB_SHA\"},\"entryPoint\":\"$GITHUB_WORKFLOW\"}"
e2e_verify_predicate_invocation_environment "$ATTESTATION" "[\"$GITHUB_ACTOR\",\"$GITHUB_SHA\",\"ubuntu20\",\"X64\",\"$GITHUB_REF_NAME\",\"$GITHUB_REF\",\"$GITHUB_REF_TYPE\"]"

if [[ -z "$LDFLAGS" ]]; then
    e2e_verify_predicate_buildConfig_command "$ATTESTATION" "[\"build\",\"-mod=vendor\",\"-trimpath\",\"-tags=netgo\",\"-o\",\"binary-linux-amd64\"]"
else
    e2e_verify_predicate_buildConfig_command "$ATTESTATION" "[\"build\",\"-mod=vendor\",\"-trimpath\",\"-tags=netgo\",\"-ldflags=-X main.gitVersion=v1.2.3 -X main.gitCommit=abcdef\",\"-o\",\"binary-linux-amd64\"]"
    chmod a+x ./"$BINARY"
    V=$(./"$BINARY" | grep 'GitVersion: v1.2.3')
    C=$(./"$BINARY" | grep 'GitCommit: abcdef')
    e2e_assert_not_eq "$V" "" "GitVersion should not be empty"
    e2e_assert_not_eq "$C" "" "GitCommit should not be empty"
fi

e2e_verify_predicate_buildConfig_env "$ATTESTATION" "[\"GOOS=linux\",\"GOARCH=amd64\",\"GO111MODULE=on\",\"CGO_ENABLED=0\"]"

e2e_verify_predicate_metadata "$ATTESTATION" "{\"buildInvocationID\":\"$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT\",\"completeness\":{\"parameters\":true,\"environment\":false,\"materials\":false},\"reproducible\":false}"
e2e_verify_predicate_materials "$ATTESTATION" "{\"uri\":\"git+https://"github.com/$GITHUB_REPOSITORY"@$GITHUB_REF\",\"digest\":{\"sha1\":\"$GITHUB_SHA\"}}"

# TODO: if tag, check assets
if [[ "$GITHUB_REF_TYPE" == "tag" ]]; then
    A=$(gh release view --json assets "$GITHUB_REF_NAME" | jq '.assets')
    if [[ -z "$ASSETS" ]]; then
        e2e_assert_eq "$A" "[]" "there should be no assets"
    else
        #TODO: list the actual binary and provenance
        e2e_assert_not_eq "$A" "[]" "there should be no assets"
    fi
fi

#TODO: read out the provenance information once we print it
#TODO: previous releases, curl the "$BINARY" directly. We should list the releases and run all commands automatically
