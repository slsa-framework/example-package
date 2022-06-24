#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"

RELEASE_TAG=""

THIS_FILE=$(e2e_this_file)
echo "THIS_FILE: $THIS_FILE"

# Use the PAT_TOKEN if one is specified.
# TODO(github.com/slsa-framework/example-package/issues/52): Always use PAT_TOKEN
TOKEN=$PAT_TOKEN
if [[ -z "$TOKEN" ]]; then
    TOKEN=$GH_TOKEN
fi

# List the releases and find the latest for THIS_FILE.
DEFAULT_MAJOR=$(version_major "$DEFAULT_VERSION")
RELEASE_LIST=$(gh release -L 200 list)
HIGHEST_PATCH="0"
while read -r line; do
    TAG=$(echo "$line" | cut -f1)
    MAJOR=$(version_major "$TAG")
    if [ "$MAJOR" == "$DEFAULT_MAJOR" ]; then
        # We only bump the patch, so we need not verify major/minor.
        PATCH=$(version_patch "$TAG")
        if [ "$PATCH" == "" ]; then
            echo "invalid patch version for $TAG"
            continue
        fi
        echo "  Processing $TAG"
        echo "  PATCH: $PATCH"
        echo "  HIGEST_PATCH: $HIGHEST_PATCH"
        echo "  RELEASE_TAG: $RELEASE_TAG"
        if [[ "$PATCH" -gt "$HIGHEST_PATCH" ]]; then
            echo " INFO: updating to $TAG"
            PATCH="$P"
            RELEASE_TAG="$TAG"
        fi
    fi
done <<<"$RELEASE_LIST"

if [[ -z "$RELEASE_TAG" ]]; then
    echo "Tag not found for $THIS_FILE"
    echo "Defaulting to DEFAULT_VERSION: $DEFAULT_VERSION"
    RELEASE_TAG="$DEFAULT_VERSION"
fi

echo "Latest tag found is $RELEASE_TAG"

RELEASE_MAJOR=$(version_major "$RELEASE_TAG")
RELEASE_MINOR=$(version_minor "$RELEASE_TAG")
RELEASE_PATCH=$(version_patch "$RELEASE_TAG")
NEW_PATCH=$((${RELEASE_PATCH:-0} + 1))
NEW_RELEASE_TAG="${RELEASE_MAJOR:-$DEFAULT_MAJOR}.${RELEASE_MINOR:-0}.$NEW_PATCH"

BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)

TAG="$NEW_RELEASE_TAG"

echo "New release tag used: $TAG"
echo "Target branch: $BRANCH"

cat <<EOF >DATA
**E2e release creation**:
Tag: $TAG
Branch: $BRANCH
Commit: $GITHUB_SHA
Caller file: $THIS_FILE
EOF

# We must use a PAT here in order to trigger subsequent workflows.
# See: https://github.community/t/push-from-action-does-not-trigger-subsequent-action/16854
GH_TOKEN=$TOKEN gh release create "$TAG" --notes-file ./DATA --target "$BRANCH"
