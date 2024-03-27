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
RUNNER_DEBUG=${RUNNER_DEBUG:-}
if [[ -n "${RUNNER_DEBUG}" ]]; then
    set -x
fi

verify_dist_tag() {
    dist_tag="${NPM_DIST_TAG:-}"

    if [ -z "${dist_tag}" ]; then
        dist_tag="latest"
    fi

    package_dir="$(e2e_npm_package_dir)"
    pkg_version=$(jq -r ".version" <"${package_dir}/package.json")

    # NOTE: change directory to the package directory because npm has some weird
    # detection git repository detection logic which often fails.
    cd "${package_dir}" || exit 1
    dist_tag=$(npm view --json | jq -r ".\"dist-tags\".\"${dist_tag}\"")
    cd - || exit 1

    echo "Checking dist-tag: ${dist_tag} == ${pkg_version}"

    if ! assert_not_empty "${dist_tag}" "dist-tag version is empty"; then
        exit 1
    fi
    if ! assert_not_empty "${pkg_version}" "package version is empty"; then
        exit 1
    fi

    e2e_assert_eq "${dist_tag}" "${pkg_version}" "dist-tag not set at the right version"
}

# Function used to verify the content of the provenance.
verify_provenance_content() {
    ATTESTATIONS=$(mktemp)
    export ATTESTATIONS

    package_dir="$(e2e_npm_package_dir)"

    # PACKAGE_VERSION is used by verification.
    PACKAGE_VERSION=$(jq -r ".version" <"${package_dir}/package.json")
    export PACKAGE_VERSION

    # PACKAGE_NAME is used by verification.
    PACKAGE_NAME="$(e2e_npm_package_name)"
    export PACKAGE_NAME

    package_name_and_version="${PACKAGE_NAME}@${PACKAGE_VERSION}"

    # Write the attestations file.
    curl -Ss "$(npm view "${package_name_and_version}" --json | jq -r '.dist.attestations.url')" >"${ATTESTATIONS}"

    PROVENANCE=$(jq -r '.attestations[] | select(.predicateType=="https://slsa.dev/provenance/v0.2").bundle.dsseEnvelope.payload | @base64d' <"${ATTESTATIONS}")
    export PROVENANCE

    # BINARY is the tarball.
    BINARY=$(mktemp)
    export BINARY
    curl -Sso "${BINARY}" "$(npm view "${package_name_and_version}" --json | jq -r '.dist.tarball')"

    echo "  **** Provenance content verification *****"

    # Verify all common provenance fields.
    e2e_verify_common_all_v02 "${PROVENANCE}"

    e2e_verify_predicate_subject_name "${PROVENANCE}" "$(name_to_purl "${package_name_and_version}")"
    e2e_verify_predicate_builder_id "${PROVENANCE}" "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_nodejs_slsa3.yml@refs/heads/main"
    e2e_verify_predicate_buildType "${PROVENANCE}" "https://github.com/slsa-framework/slsa-github-generator/delegator-generic@v0"
}

# =====================================
# ===== main execution starts =========
# =====================================

this_branch=$(e2e_this_branch)
echo "branch is ${this_branch}"
echo "GITHUB_REF_NAME: $GITHUB_REF_NAME"
echo "GITHUB_REF_TYPE: $GITHUB_REF_TYPE"
echo "GITHUB_REF: $GITHUB_REF"
echo "DEBUG: file is $(e2e_this_file)"

export SLSA_VERIFIER_TESTING="true"
export SLSA_VERIFIER_EXPERIMENTAL="1"

# Verify the provenance content.
verify_provenance_content

verify_dist_tag

# Verify provenance authenticity with min version at release v2.5.1
# Due to the breaking change below, we only need to verify starting at v2.51
# https://github.com/slsa-framework/slsa-github-generator/issues/3350
e2e_run_verifier_all_releases "v2.5.1"