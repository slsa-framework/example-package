#!/usr/bin/env bash
set -euo pipefail

source "./.github/workflows/scripts/e2e-utils.sh"

RELEASE_TAG=""

THIS_FILE=$(e2e_this_file)
echo "THIS_FILE: $THIS_FILE"

# List the releases and find the latest for THIS_FILE.
RELEASE_LIST=$(gh release -L 200 list)
while read -r line; do
    TAG=$(echo "$line" | cut -f1)
    BODY=$(gh release view "$TAG" --json body | jq -r '.body')
    if [[ "$BODY" == *"$THIS_FILE"* ]]; then
        RELEASE_TAG="$TAG"
        break
    fi
done <<<"$RELEASE_LIST"

if [[ -z "$RELEASE_TAG" ]]; then
    echo "Tag not found for $THIS_FILE"
    exit 3
fi

echo "Latest tag found is $RELEASE_TAG"

PATCH=$(echo "$RELEASE_TAG" | cut -d '.' -f3)

NEW_PATCH=$((PATCH + 1))
MAJOR_MINOR=$(echo "$RELEASE_TAG" | cut -d '.' -f1,2)
NEW_RELEASE_TAG="$MAJOR_MINOR.$NEW_PATCH"

BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)

TAG="$NEW_RELEASE_TAG"

echo "New release tag used: $TAG"
echo "target branch $BRANCH"

cat <<EOF >DATA
**E2e release creation**:
Tag: $TAG
Branch: $BRANCH
Commit: $GITHUB_SHA
Caller file: $THIS_FILE
Caller name: $GITHUB_WORKFLOW
EOF

gh release create "$TAG" --notes-file ./DATA --target "$BRANCH"
