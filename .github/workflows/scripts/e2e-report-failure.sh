#!/usr/bin/env bash
set -euo pipefail

source "./.github/workflows/scripts/e2e-utils.sh"

THIS_FILE=$(e2e_this_file)

e2e_create_issue_failure_body

ISSUE_ID=$(gh -R "$ISSUE_REPOSITORY" issue list --state open -S "$THIS_FILE" --json number | jq '.[0]' | jq -r '.number' | jq 'select (.!=null)')

if [[ -z "$ISSUE_ID" ]]; then
    # Replace `.`` by ` ` and remove the last 3 characters `yml`
    TITLE=$(echo "$THIS_FILE" | sed -e 's/\./ /g' | rev | cut -c4- | rev)
    gh -R "$ISSUE_REPOSITORY" issue create -t "E2E: $TITLE" -F ./BODY -l e2e -l "type:bug"
else
    gh -R "$ISSUE_REPOSITORY" issue comment "$ISSUE_ID" -F ./BODY
fi
