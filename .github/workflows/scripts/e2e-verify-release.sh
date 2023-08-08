#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"

# Script Inputs
DEFAULT_VERSION=${DEFAULT_VERSION:-}
GITHUB_EVENT_NAME=${GITHUB_REF_NAME:-}
GITHUB_EVENT_PATH=${GITHUB_REF_PATH:-}
GITHUB_OUTPUT=${GITHUB_OUTPUT:-}
GITHUB_REF_NAME=${GITHUB_REF_NAME:-}
GITHUB_REF_TYPE=${GITHUB_REF_TYPE:-}

this_file=$(e2e_this_file)
echo "THIS_FILE: ${this_file}"
annotated_tags=$(echo "${this_file}" | cut -d '.' -f5 | grep annotated || true)

if [[ "$GITHUB_REF_TYPE" != "tag" ]]; then
    echo "unexpected ref type $GITHUB_REF_TYPE"
    exit 4
fi

# 1- Verify the branch
# WARNING: GITHUB_BASE_REF is empty on tag releases.
this_branch=$(e2e_this_branch)
env_branch=$(jq -r '.base_ref' <"$GITHUB_EVENT_PATH")

# On release events, the base_ref above is empty.
if [[ "$GITHUB_EVENT_NAME" == "release" ]]; then
    env_branch="refs/heads/$(jq -r '.release.target_commitish' <"$GITHUB_EVENT_PATH")"
fi

# NOTE: We allow no branch for annotated tags. We only run them on main branch.
# NOTE: 'create' event do not have a branch so don't validate.
if [[ "$GITHUB_EVENT_NAME" != "create" ]] && [[ "${env_branch}" != "refs/heads/${this_branch}" ]] && [[ -z "$annotated_tags" ]]; then
    echo "mismatch branch: file contains refs/heads/${this_branch}; GitHub env contains ${env_branch}"
    echo "GITHUB_EVENT_PATH:"
    cat "$GITHUB_EVENT_PATH"
    if [[ "${env_branch}" == "" ]] || [[ "${env_branch}" == "null" ]]; then
        echo "Unable to detect branch: ${env_branch}"
        exit 1
    fi
    exit 0
fi

echo "ENV_BRANCH: ${env_branch}"

# 2- Verify that the release is intended for this e2e workflow
tag="$GITHUB_REF_NAME"
default_major=$(version_major "$DEFAULT_VERSION")
if [[ -z "$default_major" ]]; then
    echo "Invalid DEFAULT_VERSION: $DEFAULT_VERSION"
    exit 1
fi

major=$(version_major "$tag")
if [ "$major" == "$default_major" ]; then
    echo "match: continue"
    echo "continue=yes" >>"${GITHUB_OUTPUT}"
    exit 0
fi

echo "no match :/"
