#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"

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
if [[ -z "$DEFAULT_MAJOR" ]]; then
    echo "Invalid DEFAULT_VERSION: $DEFAULT_VERSION"
    exit 1
fi

# Here we find the latest version with the major version equal to that of
# DEFAULT_VERSION.
RELEASE_LIST=$(gh release -L 200 list)
LATEST_TAG=$DEFAULT_VERSION
while read -r line; do
    TAG=$(echo "$line" | cut -f1)
    MAJOR=$(version_major "$TAG")
    if [ "$MAJOR" == "$DEFAULT_MAJOR" ]; then
        echo "  Processing $TAG"
        echo "  LATEST_TAG: $LATEST_TAG"
        if version_gt "$TAG" "$LATEST_TAG"; then
            echo " INFO: updating to $TAG"
            LATEST_TAG="$TAG"
        fi
    fi
done <<<"$RELEASE_LIST"

echo "Latest tag found is $LATEST_TAG"

RELEASE_MAJOR=$(version_major "$LATEST_TAG")
RELEASE_MINOR=$(version_minor "$LATEST_TAG")
RELEASE_PATCH=$(version_patch "$LATEST_TAG")
NEW_PATCH=$((${RELEASE_PATCH:-0} + 1))
TAG="${RELEASE_MAJOR:-$DEFAULT_MAJOR}.${RELEASE_MINOR:-0}.$NEW_PATCH"

BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)

echo "New release tag used: $TAG"
echo "Target branch: $BRANCH"

cat <<EOF >DATA
**E2E release creation**:
Tag: $TAG
Branch: $BRANCH
Commit: $GITHUB_SHA
Caller file: $THIS_FILE
EOF

# We must use a PAT here in order to trigger subsequent workflows.
# See: https://github.community/t/push-from-action-does-not-trigger-subsequent-action/16854
GH_TOKEN=$TOKEN gh release create "$TAG" --notes-file ./DATA --target "$BRANCH"
