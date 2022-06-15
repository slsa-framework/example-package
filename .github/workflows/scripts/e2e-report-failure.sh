#!/usr/bin/env bash
set -euo pipefail

source "./.github/workflows/scripts/e2e-utils.sh"

THIS_FILE=$(e2e_this_file)

e2e_create_issue_failure_body

ISSUE_ID=$(gh -R "$ISSUE_REPOSITORY" issue list --label "e2e" --label "type:bug" --state open -S "$THIS_FILE" --json number | jq '.[0]' | jq -r '.number' | jq 'select (.!=null)')

if [[ -z "$ISSUE_ID" ]]; then
    # Replace `.`` by ` `, remove the last 3 characters `yml` and remove the e2e prefix
    TITLE=$(echo "$THIS_FILE" | sed -e 's/\./ /g' | rev | cut -c4- | rev | cut -c5-)
    gh -R "$ISSUE_REPOSITORY" issue create -t "E2E: $TITLE" -F ./BODY --label "e2e" --label "type:bug"
else
    gh -R "$ISSUE_REPOSITORY" issue comment "$ISSUE_ID" -F ./BODY
fi
