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

THIS_FILE=$(e2e_this_file)

# Convert the test name to the package name.
# remove the file extension
PACKAGE_NAME="$(echo "${THIS_FILE}" | rev | cut -d'.' -f2- | rev)"
# convert periods to hyphen
PACKAGE_NAME="${PACKAGE_NAME//./-}"
PACKAGE_NAME="@slsa-framework/${PACKAGE_NAME}"

ATTESTATIONS=$(mktemp)
curl -Sso "${ATTESTATIONS}" "$(npm view "${PACKAGE_NAME}" --json | jq -r '.dist.attestations.url')"

# Function used to verify the content of the provenance.
verify_provenance_content() {
    provenance=$(jq -r '.attestations[] | select(.predicateType=="https://slsa.dev/provenance/v0.2").bundle.dsseEnvelope.payload | @base64d' <"${ATTESTATIONS}")

    echo "  **** Provenance content verification *****"

    # Verify all common provenance fields.
    e2e_verify_common_all_v02 "$provenance"

    e2e_verify_predicate_subject_name "$provenance" "$(name_to_purl "${PACKAGE_NAME}")"
    e2e_verify_predicate_builder_id "$provenance" "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_nodejs_slsa3.yml@refs/heads/main"
    e2e_verify_predicate_buildType "$provenance" "https://github.com/slsa-framework/slsa-github-generator/delegator-generic@v0"
}

# =====================================
# ===== main execution starts =========
# =====================================

THIS_FILE=$(e2e_this_file)
BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
echo "branch is $BRANCH"
echo "GITHUB_REF_NAME: $GITHUB_REF_NAME"
echo "GITHUB_REF_TYPE: $GITHUB_REF_TYPE"
echo "GITHUB_REF: $GITHUB_REF"
echo "DEBUG: file is $THIS_FILE"
echo "BINARY: file is $BINARY"

export SLSA_VERIFIER_TESTING="true"

# Verify provenance authenticity with min version at release v1.0.0
# TODO: verify npm packages
# e2e_run_verifier_all_releases v1.0.0

# Verify the provenance content.
verify_provenance_content
