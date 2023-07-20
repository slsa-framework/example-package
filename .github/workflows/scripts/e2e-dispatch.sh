#!/usr/bin/env bash
set -euo pipefail

source "./.github/workflows/scripts/e2e-utils.sh"

# Script Inputs
GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-}
GH_TOKEN=${GH_TOKEN:-}
RUNNER_DEBUG=${RUNNER_DEBUG:-}
if [[ -n "${RUNNER_DEBUG}" ]]; then
    set -x
fi

this_file=$(e2e_this_file)
echo "THIS_FILE: ${this_file}"

this_branch=$(e2e_this_branch)
curl -s -X POST -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/workflows/${this_file}/dispatches" \
    -d "{\"ref\":\"${this_branch}\"}" \
    -H "Authorization: token ${GH_TOKEN}"
