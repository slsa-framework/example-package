#!/usr/bin/env bash

source "./.github/workflows/scripts/e2e-utils.sh"

if [[ "$GITHUB_REF_TYPE" != "tag" ]]; then
    echo "unexpected ref type $GITHUB_REF_TYPE"
    exit 4
fi

# WARNING: GITHUB_BASE_REF is empty on tag releases.
BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
ENV_BRANCH=$(cat "$GITHUB_EVENT_PATH" | jq -r '.base_ref')

echo "id: $GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT"
echo "branch: $BRANCH"
cat "$GITHUB_EVENT_PATH"
echo

if [[ "$ENV_BRANCH" != "refs/heads/$BRANCH" ]]; then
    echo "mismatch branch: file contains refs/heads/$BRANCH; GitHub env contains $ENV_BRANCH"
    exit 0
fi

# Verify that the release is intended for this e2e workflow
#, ie that the notes contains the string $THIS_FILE
TAG="$GITHUB_REF_NAME"
BODY=$(gh release view "$TAG" --json body | jq -r '.body')
if [[ "$BODY" == *"$THIS_FILE"* ]]; then
    RELEASE_TAG="$TAG"
    echo "::set-output name=continue::yes"
fi

