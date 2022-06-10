#!/usr/bin/env bash
set -euo pipefail

source "./.github/workflows/scripts/e2e-utils.sh"

THIS_FILE=$(e2e_this_file)
echo "THIS_FILE: $THIS_FILE"

BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
curl -s -X POST -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/workflows/$THIS_FILE/dispatches" \
    -d "{\"ref\":\"$BRANCH\"}" \
    -H "Authorization: token $GH_TOKEN"
