#!/usr/bin/env bash
set -euo pipefail

today=$(date +"%F")

# Use the PAT_TOKEN if one is specified.
# TODO(github.com/slsa-framework/example-package/issues/52): Always use PAT_TOKEN
token=${PAT_TOKEN+$PAT_TOKEN}
if [[ -z "$token" ]]; then
    token=$GH_TOKEN
fi

while read -r line; do
    tag=$(echo "$line" | awk '{ print $1 }')
    created_at=$(echo "$line" | awk '{ print $2 }')
    days="$((($(date --date="$today" +%s) - $(date --date="$created_at" +%s)) / (60 * 60 * 24)))"
    if [ "$days" -gt 7 ]; then
        echo "Deleting tag $tag..."
        GH_TOKEN=$token gh release delete "$tag" -y
        # Also delete the tag for the release. Use the normal GH_TOKEN.
        git push --delete origin "$tag"
    fi
done <<<"$(GH_TOKEN=$token gh api --header 'Accept: application/vnd.github.v3+json' --method GET "/repos/${GITHUB_REPOSITORY}/releases" --paginate | jq -r '.[] | "\(.tag_name) \(.created_at)"')"
