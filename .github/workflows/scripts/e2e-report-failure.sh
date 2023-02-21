#!/usr/bin/env bash
set -eo pipefail

source "./.github/workflows/scripts/e2e-utils.sh"

THIS_FILE=$(e2e_this_file)

e2e_create_issue_failure_body

if [[ -z "$TITLE" ]]; then
    # Replace `.`` by ` `, remove the last 3 characters `yml` and remove the e2e prefix
    TITLE=$(echo "$THIS_FILE" | sed -e 's/\./ /g' | rev | cut -c4- | rev | cut -c5-)
fi
if [[ -z "$WORKFLOW" ]]; then
    WORKFLOW=$(echo "$THIS_FILE" | cut -d '.' -f2)
fi
if [[ -z "$HEADER" ]]; then
    HEADER="e2e"
fi
ISSUE_ID=$(gh -R "$ISSUE_REPOSITORY" issue list --label "$HEADER" --label "type:bug" --state open -S "$THIS_FILE" --json number | jq '.[0]' | jq -r '.number' | jq 'select (.!=null)')

# Use the PAT_TOKEN if one is specified.
# TODO(github.com/slsa-framework/example-package/issues/52): Always use PAT_TOKEN
TOKEN=${PAT_TOKEN+$PAT_TOKEN}
if [[ -z "$TOKEN" ]]; then
    TOKEN=$GH_TOKEN
fi

if [[ -z "$ISSUE_ID" ]]; then
    GH_TOKEN=$TOKEN gh -R "$ISSUE_REPOSITORY" issue create -t "[$HEADER]: $TITLE" -F ./BODY --label "$HEADER" --label "type:bug" --label "area:$WORKFLOW"
else
    GH_TOKEN=$TOKEN gh -R "$ISSUE_REPOSITORY" issue comment "$ISSUE_ID" -F ./BODY
fi
