#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"
# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-badges.sh"

this_file=$(e2e_this_file)
body_file=$(e2e_create_issue_failure_body)

# TITLE
title="${TITLE:-}"
if [[ -z "${title}" ]]; then
    # Replace `.`` by ` `, remove the last 3 characters `yml` and remove the e2e prefix
    title=$(echo "${this_file}" | sed -e 's/\./ /g' | rev | cut -c4- | rev | cut -c5-)
fi

# WORKFLOW
workflow="${WORKFLOW:-}"
if [[ -z "${workflow}" ]]; then
    workflow=$(echo "${this_file}" | cut -d '.' -f2)
fi

# HEADER
header="${HEADER:-e2e}"

# ISSSE_REPOSITORY
issue_repository="${ISSUE_REPOSITORY:-}"

issue_id=$(gh -R "${issue_repository}" issue list --label "${header}" --label "type:bug" --state open -S "${this_file}" --json number | jq '.[0]' | jq -r '.number' | jq 'select (.!=null)')

# Use the PAT_TOKEN if one is specified.
# TODO(github.com/slsa-framework/example-package/issues/52): Always use PAT_TOKEN
token=${PAT_TOKEN:-${GH_TOKEN:-}}
if [[ -z "${issue_id}" ]]; then
    GH_TOKEN="${token}" gh -R "${issue_repository}" issue create -t "[${header}]: ${title}" -F "${body_file}" --label "${header}" --label "type:bug" --label "area:${workflow}"
else
    GH_TOKEN="${token}" gh -R "${issue_repository}" issue comment "${issue_id}" -F "${body_file}"
fi

e2e_update_badge_failing
