#!/usr/bin/env bash
set -eo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"
# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-badges.sh"

THIS_FILE=$(e2e_this_file)

body_file=$(e2e_create_issue_success_body)

HEADER="${HEADER:-e2e}"

issue_id=$(gh -R "$ISSUE_REPOSITORY" issue list --label "$HEADER" --label "type:bug" --state open -S "$THIS_FILE" --json number | jq '.[0]' | jq -r '.number' | jq 'select (.!=null)')

# Use the PAT_TOKEN if one is specified.
# TODO(github.com/slsa-framework/example-package/issues/52): Always use PAT_TOKEN
token=${PAT_TOKEN+$PAT_TOKEN}
if [[ -z "$TOKEN" ]]; then
    token=$GH_TOKEN
fi

if [[ -n "${issue_id}" ]]; then
    echo gh -R "$ISSUE_REPOSITORY" issue close "${issue_id}" -c "$(cat "${body_file}")"
    GH_TOKEN=${token} gh -R "$ISSUE_REPOSITORY" issue close "${issue_id}" -c "$(cat "${body_file}")"
fi

e2e_update_badge_passing
