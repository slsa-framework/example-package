#!/usr/bin/env bash

source "./.github/workflows/scripts/e2e-utils.sh"

e2e_create_issue_failure_body

ISSUE_ID=$(gh -R "$ISSUE_REPOSITORY" issue list --state open -S "$THIS_FILE" --json number | jq '.[0]' | jq -r '.number' | jq 'select (.!=null)')

if [[ -z "$ISSUE_ID" ]]; then
  gh -R "$ISSUE_REPOSITORY" issue create -t "E2E: $GITHUB_WORKFLOW" -F ./BODY -l e2e -l "type:bug"
else
  gh -R "$ISSUE_REPOSITORY" issue comment "$ISSUE_ID" -F ./BODY
fi

 
