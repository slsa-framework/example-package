#!/bin/bash

RUN_DATE=$(date --utc)

# see https://docs.github.com/en/actions/learn-github-actions/environment-variables
# https://docs.github.com/en/actions/learn-github-actions/contexts.
cat << EOF > BODY
Repo: https://github.com/$GITHUB_REPOSITORY/tree/$GITHUB_REF_NAME
Run: https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID
Workflow name: $GITHUB_WORKFLOW
Workflow file: https://github.com/$GITHUB_REPOSITORY/tree/main/.github/workflows/$THIS_FILE
Trigger: $GITHUB_EVENT_NAME
Branch: $GITHUB_REF_NAME
Date: $RUN_DATE
EOF

ISSUE_ID=$(gh -R "$ISSUE_REPOSITORY" issue list --state open -S "$THIS_FILE" --json number | jq '.[0]' | jq -r '.number' | jq 'select (.!=null)')

if [[ -z "$ISSUE_ID" ]]; then
  gh -R "$ISSUE_REPOSITORY" issue create -t "E2E: $GITHUB_WORKFLOW" -F ./BODY -l e2e -l bug
else
  gh -R "$ISSUE_REPOSITORY" issue comment "$ISSUE_ID" -F ./BODY -l e2e -l bug
fi

 
