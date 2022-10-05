#!/usr/bin/env bash
set -euo pipefail

today=$(date +"%F")

# Use the PAT_TOKEN if one is specified.
# TODO(github.com/slsa-framework/example-package/issues/52): Always use PAT_TOKEN
token=${PAT_TOKEN+$PAT_TOKEN}
if [[ -z "$token" ]]; then
    token=$GH_TOKEN
fi

# NOTE: use published_at because while GitHub deletes releases it retains them
# internally. Scripts that re-create the release with the same tag name re-publish
# rather than re-create the release so the old creation date is used. Only the
# published_at date is updated.
while read -r line; do
    tag=$(echo "$line" | awk '{ print $1 }')
    created_at=$(echo "$line" | awk '{ print $2 }')
    days="$((($(date --date="$today" +%s) - $(date --date="$created_at" +%s)) / (60 * 60 * 24)))"
    if [ "$days" -gt 7 ]; then
        echo "Deleting tag $tag..."
        GH_TOKEN=$token gh release delete "$tag" -y
    fi
done <<<"$(GH_TOKEN=$token gh api --header 'Accept: application/vnd.github.v3+json' --method GET "/repos/${GITHUB_REPOSITORY}/releases" --paginate | jq -r '.[] | "\(.tag_name) \(.published_at)"')"
