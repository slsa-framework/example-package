#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"

# HEADER
header="${HEADER:-e2e}"

# ISSUE_REPOSITORY
issue_repository="${ISSUE_REPOSITORY:-}"

# Use the PAT_TOKEN if one is specified.
# TODO(github.com/slsa-framework/example-package/issues/52): Always use PAT_TOKEN
token=${PAT_TOKEN:-${GH_TOKEN:-}}

this_file=$(e2e_this_file)

body_file=$(e2e_create_issue_success_body)

issue_id=$(gh -R "${issue_repository}" issue list --label "${header}" --label "type:bug" --state open -S "${this_file}" --json number | jq '.[0]' | jq -r '.number' | jq 'select (.!=null)')

if [[ -n "${issue_id}" ]]; then
    echo gh -R "${issue_repository}" issue close "${issue_id}" -c "$(cat "${body_file}")"
    GH_TOKEN=${token} gh -R "${issue_repository}" issue close "${issue_id}" -c "$(cat "${body_file}")"
fi
