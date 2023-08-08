#!/usr/bin/env bash

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

go env -w GOFLAGS=-mod=mod

this_file=$(e2e_this_file)
this_branch=$(e2e_this_branch)
echo "branch is ${this_branch}"
echo "GITHUB_REF_NAME: $GITHUB_REF_NAME"
echo "GITHUB_REF_TYPE: $GITHUB_REF_TYPE"
echo "GITHUB_REF: $GITHUB_REF"
echo "DEBUG: file is ${this_file}"

export SLSA_VERIFIER_TESTING="true"

# Verify provenance authenticity.
e2e_run_verifier_all_releases "v2.1.0"

# TODO: Verify provenance content. The GCB provenance format is not like others!
