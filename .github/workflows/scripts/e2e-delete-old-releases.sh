#!/usr/bin/env bash
set -euo pipefail

# Script Inputs
GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-}

today=$(date +"%F")

while read -r line; do
    tag=$(echo "$line" | awk '{ print $1 }')
    created_at=$(echo "$line" | awk '{ print $2 }')
    days="$((($(date --date="$today" +%s) - $(date --date="$created_at" +%s)) / (60 * 60 * 24)))"
    if [ "$days" -gt 7 ]; then
        echo "Deleting tag $tag..."
        gh release delete "$tag" -y
        # Also delete the tag for the release. Use the normal GH_TOKEN.
        git push --delete origin "$tag"
    fi
done <<<"$(gh api --header 'Accept: application/vnd.github.v3+json' --method GET "/repos/${GITHUB_REPOSITORY}/releases" --paginate | jq -r '.[] | "\(.tag_name) \(.created_at)"')"
