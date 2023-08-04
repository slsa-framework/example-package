#!/usr/bin/env bash

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-verify.common.sh"

RUNNER_DEBUG=${RUNNER_DEBUG:-}
if [[ -n "${RUNNER_DEBUG}" ]]; then
    set -x
fi

go env -w GOFLAGS=-mod=mod

verify_provenance_content() {
    e2e_verify_predicate_subject_name "${ATTESTATION}" "test-java-project-0.1.19.jar"
    e2e_verify_predicate_v1_runDetails_builder_id "${ATTESTATION}" "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_maven_slsa3.yml@refs/heads/main"
    e2e_verify_predicate_v1_buildDefinition_buildType "${ATTESTATION}" "https://github.com/slsa-framework/slsa-github-generator/delegator-generic@v0"
}

THIS_FILE=$(e2e_this_file)
BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
echo "branch is $BRANCH"
echo "GITHUB_REF_NAME: $GITHUB_REF_NAME"
echo "GITHUB_REF_TYPE: $GITHUB_REF_TYPE"
echo "GITHUB_REF: $GITHUB_REF"
echo "DEBUG: file is $THIS_FILE"
echo "PROVENANCE is: ${PROVENANCE}"

ATTESTATION=$(jq -r '.dsseEnvelope.payload' "${PROVENANCE}" | base64 -d)
export ATTESTATION

export SLSA_VERIFIER_TESTING="true"

# Verify provenance content.
echo "verify_provenance_content:"
verify_provenance_content
