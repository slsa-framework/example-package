#!/usr/bin/env bash
set -euo pipefail

source "./.github/workflows/scripts/e2e-utils.sh"

THIS_FILE=$(e2e_this_file)

e2e_create_issue_success_body

ISSUE_ID=$(gh -R "$ISSUE_REPOSITORY" issue list --label "e2e" --label "type:bug" --state open -S "$THIS_FILE" --json number | jq '.[0]' | jq -r '.number' | jq 'select (.!=null)')

# Use the PAT_TOKEN if one is specified.
# TODO(github.com/slsa-framework/example-package/issues/52): Always use PAT_TOKEN
TOKEN=$PAT_TOKEN
if [[ -z "$TOKEN" ]]; then
    TOKEN=$GH_TOKEN
fi

if [[ -n "$ISSUE_ID" ]]; then
    echo gh -R "$ISSUE_REPOSITORY" issue close "$ISSUE_ID" -c "$(cat ./BODY)"
    GH_TOKEN=$TOKEN gh -R "$ISSUE_REPOSITORY" issue close "$ISSUE_ID" -c "$(cat ./BODY)"
fi
