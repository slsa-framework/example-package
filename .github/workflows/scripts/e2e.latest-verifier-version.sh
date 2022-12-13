#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"

latest_tag="$MIMINUM_VERIFIER_VERSION"
# Check the releases.
echo "Listing releases"
# Note: can remove -R option.
release_list=$(gh -R slsa-framework/slsa-verifier release list)
while read -r line; do
    tag=$(echo "$line" | cut -f1)
    if version_ge "$tag" "$latest_tag"; then
        echo " INFO: updating to $tag"
        latest_tag="$tag"
    fi
done <<<"$release_list"

echo "latest_tag=$latest_tag" >> "$GITHUB_OUTPUT"
