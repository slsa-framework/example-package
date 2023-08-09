#!/usr/bin/env bash

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-verify.common.sh"

# Input variables
PROVENANCE=${PROVENANCE:-}
ARTIFACT_VERSION=${ARTIFACT_VERSION:-}
EXPECTED_ARTIFACT_OUTPUT=${EXPECTED_ARTIFACT_OUTPUT:-}
GITHUB_REF_NAME=${GITHUB_REF_NAME:-}
GITHUB_REF=${GITHUB_REF:-}
RUNNER_DEBUG=${RUNNER_DEBUG:-}
if [[ -n "${RUNNER_DEBUG}" ]]; then
    set -x
fi

go env -w GOFLAGS=-mod=mod

verify_provenance_content() {
    local attestation
    attestation=$(jq -r '.dsseEnvelope.payload' "${PROVENANCE}" | base64 -d)

    # Run the artifact and verify the output is correct
    artifact_output=$(java -jar target/test-java-project-"${ARTIFACT_VERSION}".jar)
    expected_artifact_output="${EXPECTED_ARTIFACT_OUTPUT}"
    e2e_assert_eq "${artifact_output}" "${expected_artifact_output}" "The output from the artifact should be '${expected_artifact_output}' but was '${artifact_output}'"
    
    # Verify the content of the attestation
    e2e_verify_predicate_subject_name "${attestation}" "test-java-project-${ARTIFACT_VERSION}.jar"
    e2e_verify_predicate_v1_runDetails_builder_id "${attestation}" "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_maven_slsa3.yml@refs/heads/main"
    e2e_verify_predicate_v1_buildDefinition_buildType "${attestation}" "https://github.com/slsa-framework/slsa-github-generator/delegator-generic@v0"
}

this_file=$(e2e_this_file)
branch=$(echo "$this_file" | cut -d '.' -f4)
echo "branch is $branch"
echo "GITHUB_REF_NAME: $GITHUB_REF_NAME"
echo "GITHUB_REF_TYPE: $GITHUB_REF_TYPE"
echo "GITHUB_REF: $GITHUB_REF"
echo "DEBUG: file is $this_file"
echo "PROVENANCE is: ${PROVENANCE}"

export SLSA_VERIFIER_TESTING="true"

# Verify provenance content.
verify_provenance_content

e2e_run_verifier_all_releases "2.3.0"
