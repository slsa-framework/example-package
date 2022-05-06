#!/usr/bin/env bash

source "./.github/workflows/scripts/e2e-utils.sh"

if [[ "$GITHUB_REF_TYPE" != "tag" ]]; then
    echo "unexpected ref type $GITHUB_REF_TYPE"
    exit 4
fi

# Verify that the release is intended for this e2e workflow
#, ie that the notes contains the string $THIS_FILE
TAG="$GITHUB_REF_NAME"
echo "tag is $TAG"
BODY=$(gh release view "$TAG" --json body | jq -r '.body')
if [[ "$BODY" == *"$THIS_FILE"* ]]; then
    RELEASE_TAG="$TAG"
    echo "we found it $RELEASE_TAG"
    echo "::set-output name=continue::yes"
fi

exit 10