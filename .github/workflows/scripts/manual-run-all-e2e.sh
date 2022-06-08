#!/usr/bin/env bash
set -euo pipefail

if [[ -z "$GH_TOKEN" ]]; then
    echo "GH_TOKEN is not set"
    exit 2
fi

if [[ -z "$GH" ]]; then
    echo "GH is not set. Should point to the gh binary"
    exit 2
fi

REPOSITORY="slsa-framework/example-package"
BRANCH="main"

# List all workflows whose names start with `e2e.`
FILES=$("$GH" api \
  -H "Accept: application/vnd.github.v3+json" \
  "/repos/$REPOSITORY/contents/.github/workflows/")


for row in $(echo "$FILES" | jq -r '.[] | @base64'); do
    FILE=$(echo "$row" | base64 -d | jq -r '.name')
    if [[ "$FILE" != e2e.* ]]; then
        continue
    fi
    
    # Trigger the workflow.
    curl -s -X POST -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPOSITORY/actions/workflows/$FILE/dispatches" \
        -d "{\"ref\":\"$BRANCH\"}" \
         -H "Authorization: token $GH_TOKEN"
done
 
