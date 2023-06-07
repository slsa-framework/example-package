#!/usr/bin/env bash
set -eo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"
# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-badges.sh"

this_file=$(e2e_this_file)
body_file=$(e2e_create_issue_failure_body)

if [[ -z "$TITLE" ]]; then
    # Replace `.`` by ` `, remove the last 3 characters `yml` and remove the e2e prefix
    TITLE=$(echo "${this_file}" | sed -e 's/\./ /g' | rev | cut -c4- | rev | cut -c5-)
fi
if [[ -z "$WORKFLOW" ]]; then
    WORKFLOW=$(echo "${this_file}" | cut -d '.' -f2)
fi
if [[ -z "$HEADER" ]]; then
    HEADER="e2e"
fi
issue_id=$(gh -R "$ISSUE_REPOSITORY" issue list --label "$HEADER" --label "type:bug" --state open -S "${this_file}" --json number | jq '.[0]' | jq -r '.number' | jq 'select (.!=null)')

# Use the PAT_TOKEN if one is specified.
# TODO(github.com/slsa-framework/example-package/issues/52): Always use PAT_TOKEN
token=${PAT_TOKEN+$PAT_TOKEN}
if [[ -z "$token" ]]; then
    token=$GH_TOKEN
fi

if [[ -z "${issue_id}" ]]; then
    GH_TOKEN="${token}" gh -R "$ISSUE_REPOSITORY" issue create -t "[$HEADER]: $TITLE" -F "${body_file}" --label "$HEADER" --label "type:bug" --label "area:$WORKFLOW"
else
    GH_TOKEN="${token}" gh -R "$ISSUE_REPOSITORY" issue comment "${issue_id}" -F "${body_file}"
fi

e2e_update_badge_failing
