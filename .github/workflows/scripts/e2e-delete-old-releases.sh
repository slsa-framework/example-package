#!/usr/bin/env bash
set -euo pipefail

today=$(date +"%F")

# Use the PAT_TOKEN if one is specified.
# TODO(github.com/slsa-framework/example-package/issues/52): Always use PAT_TOKEN
token=${PAT_TOKEN+$PAT_TOKEN}
if [[ -z "$token" ]]; then
    token=$GH_TOKEN
fi

# TODO(github.com/slsa-framework/example-package/issues/113): Delete tags for releases.
#
# NOTE: use published_at for now because created_at comes from the commit date
# of the tag for the release. If the release is re-created for an existing old
# tag it will get deleted immediately.
while read -r line; do
    tag=$(echo "$line" | awk '{ print $1 }')
    created_at=$(echo "$line" | awk '{ print $2 }')
    days="$((($(date --date="$today" +%s) - $(date --date="$created_at" +%s)) / (60 * 60 * 24)))"
    if [ "$days" -gt 7 ]; then
        echo "Deleting tag $tag..."
        GH_TOKEN=$token gh release delete "$tag" -y
    fi
done <<<"$(GH_TOKEN=$token gh api --header 'Accept: application/vnd.github.v3+json' --method GET "/repos/${GITHUB_REPOSITORY}/releases" --paginate | jq -r '.[] | "\(.tag_name) \(.published_at)"')"
