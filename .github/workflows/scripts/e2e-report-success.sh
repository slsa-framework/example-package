#!/usr/bin/env bash

source "./.github/workflows/scripts/e2e-utils.sh"

e2e_create_issue_success_body

ISSUE_ID=$(gh -R "$ISSUE_REPOSITORY" issue list --state open -S "$THIS_FILE" --json number | jq '.[0]' | jq -r '.number' | jq 'select (.!=null)')

if [[ ! -z "$ISSUE_ID" ]]; then
  echo gh -R "$ISSUE_REPOSITORY" issue close "$ISSUE_ID" -c "$(cat ./BODY)"
  gh -R "$ISSUE_REPOSITORY" issue close "$ISSUE_ID" -c "$(cat ./BODY)"
fi

 
