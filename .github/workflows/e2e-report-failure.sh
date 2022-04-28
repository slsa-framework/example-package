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

echo ISSUE_ID=$(gh -R "$TARGET_REPOSITORY" issue list --state open -S "$THIS_FILE" --json number | jq '.[0]' | jq -r '.number')
ISSUE_ID=$(gh -R "$TARGET_REPOSITORY" issue list --state open -S "$THIS_FILE" --json number | jq '.[0]' | jq -r '.number')

if [[ -z "$ISSUE_ID" ]]; then
  echo gh -R "$TARGET_REPOSITORY" issue create -t "BUG: $GITHUB_WORKFLOW" -F ./BODY
  gh -R "$TARGET_REPOSITORY" issue create -t "BUG: $GITHUB_WORKFLOW" -F ./BODY
else
  echo gh -R "$TARGET_REPOSITORY" issue comment "$ISSUE_ID" -F ./BODY
  gh -R "$TARGET_REPOSITORY" issue comment "$ISSUE_ID" -F ./BODY
fi

 
