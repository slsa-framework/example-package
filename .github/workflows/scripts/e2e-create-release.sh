#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"

this_file=$(e2e_this_file)
echo "THIS_FILE: $this_file"

# Use the PAT_TOKEN if one is specified.
# TODO(github.com/slsa-framework/example-package/issues/52): Always use PAT_TOKEN
token=$PAT_TOKEN
if [[ -z "$token" ]]; then
    token=$GH_TOKEN
fi

# List the releases and find the latest for THIS_FILE.
default_major=$(version_major "$DEFAULT_VERSION")
if [[ -z "$default_major" ]]; then
    echo "Invalid DEFAULT_VERSION: $DEFAULT_VERSION"
    exit 1
fi

# Here we find the latest version with the major version equal to that of
# DEFAULT_VERSION.
release_list=$(gh release -L 200 list)
latest_tag=$DEFAULT_VERSION
while read -r line; do
    tag=$(echo "$line" | cut -f1)
    major=$(version_major "$tag")
    if [ "$major" == "$default_major" ]; then
        echo "  Processing $tag"
        echo "  latest_tag: $latest_tag"
        if version_gt "$TAG" "$latest_tag"; then
            echo " INFO: updating to $tag"
            latest_tag="$tag"
        fi
    fi
done <<<"$release_list"

echo "Latest tag found is $latest_tag"

release_major=$(version_major "$latest_tag")
release_minor=$(version_minor "$latest_tag")
release_patch=$(version_patch "$latest_tag")
new_patch=$((${release_patch:-0} + 1))
tag="${release_major:-$default_major}.${release_minor:-0}.$new_patch"

branch=$(echo "$this_file" | cut -d '.' -f4)

echo "New release tag used: $tag"
echo "Target branch: $branch"

cat <<EOF >DATA
**E2E release creation**:
Tag: $tag
Branch: $branch
Commit: $GITHUB_SHA
Caller file: $this_file
EOF

# We must use a PAT here in order to trigger subsequent workflows.
# See: https://github.community/t/push-from-action-does-not-trigger-subsequent-action/16854
GH_TOKEN=$token gh release create "$tag" --notes-file ./DATA --target "$branch"
