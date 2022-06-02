#!/usr/bin/env bash -euo pipefail

THIS_FILE=$(gh api -H "Accept: application/vnd.github.v3+json" "/repos/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID" | jq -r '.path' | cut -d '/' -f3)
BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
curl -s -X POST -H "Accept: application/vnd.github.v3+json" \
     https://api.github.com/repos/$GITHUB_REPOSITORY/actions/workflows/$THIS_FILE/dispatches \
     -d "{\"ref\":\"$BRANCH\"}" \
     -H "Authorization: token $GH_TOKEN"
