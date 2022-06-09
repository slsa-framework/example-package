#!/usr/bin/env bash
set -euo pipefail

source "./.github/workflows/scripts/e2e-utils.sh"

THIS_FILE=$(e2e_this_file)
echo "THIS_FILE: $THIS_FILE"

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
    ENV_BRANCH="refs/heads/$(cat $GITHUB_EVENT_PATH | jq -r '.release.target_commitish')"
fi

if [[ "$ENV_BRANCH" != "refs/heads/$BRANCH" ]]; then
    echo "mismatch branch: file contains refs/heads/$BRANCH; GitHub env contains $ENV_BRANCH"
    exit 0
fi

# 2- Verify that the release is intended for this e2e workflow
#, ie that the notes contains the string $THIS_FILE
TAG="$GITHUB_REF_NAME"
BODY=$(gh release view "$TAG" --json body | jq -r '.body')
if [[ "$BODY" == *"$THIS_FILE"* ]]; then
    echo "::set-output name=continue::yes"
fi
