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
slsa-verifier --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
e2e_assert_eq "$?" "0" "default parameters"

# Main branch
slsa-verifier --branch main --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
e2e_assert_eq "$?" "0" "main branch"

# Wrong branch
slsa-verifier --branch not-main --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
e2e_assert_not_eq "$?" "0" "wrong branch"

# Wrong tag
slsa-verifier --tag v1.2.3 --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
e2e_assert_not_eq "$?" "0" "wrong tag"

# Wrong versioned-tag
slsa-verifier --versioned-tag v1.2.3 --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
e2e_assert_not_eq "$?" "0" "wrong versioned-tag"



# Provenance content verification.
ATTESTATION=$(cat ""$PROVENANCE"" | jq -r '.payload' | base64 -d)
TRIGGER=$(echo "$THIS_FILE" | cut -d '.' -f3)
#BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
LDFLAGS=$(echo "$THIS_FILE" | cut -d '.' -f5 | grep -v noldflags)
ASSETS=$(echo "$THIS_FILE" | cut -d '.' -f5 | grep -v noassets)

e2e_verify_predicate_subject_name "$ATTESTATION" "binary-linux-amd64"
e2e_verify_predicate_builder_id "$ATTESTATION" "https://github.com/slsa-framework/slsa-github-generator-go/.github/workflows/slsa3_builder.yml@refs/heads/main"
e2e_verify_predicate_builderType "$ATTESTATION" "https://github.com/slsa-framework/slsa-github-generator-go@v1"

e2e_verify_predicate_invocation_configSource "$ATTESTATION" "{\"uri\":\"git+https://"github.com/$GITHUB_REPOSITORY"@$GITHUB_REF\",\"digest\":{\"sha1\":\"$GITHUB_SHA\"},\"entryPoint\":\"$GITHUB_WORKFLOW\"}"
e2e_verify_predicate_invocation_environment "$ATTESTATION" "[\"$GITHUB_ACTOR\",\"$GITHUB_SHA\",\"ubuntu20\",\"X64\",\"$TRIGGER\",\"$GITHUB_REF\",\"$GITHUB_REF_TYPE\"]"

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
if [[ "$TRIGGER" == "tag" ]]; then
    A=$(gh release view --json assets "$GITHUB_REF_NAME" | jq '.assets')
    if [[ -z "$ASSETS" ]]; then
        e2e_assert_eq "$A" "[]" "there should be no assets"
    else
        #TODO: list the actual binari and provenance
        e2e_assert_not_eq "$A" "[]" "there should be no assets"
    fi
fi
#TODO: read out the provenance information once we print it
#TODO: previous releases, curl the "$BINARY" directly. We should list the releases and run all commands automatically
