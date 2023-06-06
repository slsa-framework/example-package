#!/usr/bin/env bash
set -euo pipefail

source "./.github/workflows/scripts/e2e-utils.sh"

THIS_FILE=$(e2e_this_file)
echo "THIS_FILE: $THIS_FILE"
annotated_tags=$(echo "$THIS_FILE" | cut -d '.' -f5 | grep annotated || true)

if [[ "$GITHUB_REF_TYPE" != "tag" ]]; then
    echo "unexpected ref type $GITHUB_REF_TYPE"
    exit 4
fi

# 1- Verify the branch
# WARNING: GITHUB_BASE_REF is empty on tag releases.
BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
ENV_BRANCH=$(jq -r '.base_ref' <"$GITHUB_EVENT_PATH")

# On release events, the base_ref above is empty.
if [[ "$GITHUB_EVENT_NAME" == "release" ]]; then
    ENV_BRANCH="refs/heads/$(jq -r '.release.target_commitish' <"$GITHUB_EVENT_PATH")"
fi

if [[ "${ENV_BRANCH}" == "" ]] || [[ "${ENV_BRANCH}" == "null" ]]; then
    echo "Unable to detect branch: ${ENV_BRANCH}"
    exit 1
if

# NOTE: We allow no branch for annotated tags. We only run them on main branch.
# NOTE: 'create' event do not have a branch so don't validate.
if [[ "$GITHUB_EVENT_NAME" != "create" ]] && [[ "$ENV_BRANCH" != "refs/heads/$BRANCH" ]] && [[ -z "$annotated_tags" ]]; then
    echo "mismatch branch: file contains refs/heads/$BRANCH; GitHub env contains $ENV_BRANCH"
    echo "GITHUB_EVENT_PATH:"
    cat "$GITHUB_EVENT_PATH"
    exit 0
fi

echo "ENV_BRANCH: $ENV_BRANCH"

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
    echo "continue=yes" >>"$GITHUB_OUTPUT"
    exit 0
fi

echo "no match :/"
