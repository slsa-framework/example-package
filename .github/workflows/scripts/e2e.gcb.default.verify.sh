#!/usr/bin/env bash

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-verify.common.sh"

go env -w GOFLAGS=-mod=mod

THIS_FILE=$(e2e_this_file)
BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
echo "branch is $BRANCH"
echo "GITHUB_REF_NAME: $GITHUB_REF_NAME"
echo "GITHUB_REF_TYPE: $GITHUB_REF_TYPE"
echo "GITHUB_REF: $GITHUB_REF"
echo "DEBUG: file is $THIS_FILE"

export SLSA_VERIFIER_TESTING="true"

# Verify provenance authenticity.
e2e_run_verifier_all_releases "v2.1.0"

# TODO: Verify provenance content. The GCB provenance format is not like others!
