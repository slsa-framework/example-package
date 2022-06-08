#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $(basename $0) workflow-name"
    exit 1
fi

if [[ -z "$GH_TOKEN" ]]; then
    echo "GH_TOKEN is not set"
    exit 2
fi

if [[ -z "$GH" ]]; then
    echo "GH is not set. Should point to the gh binary"
    exit 3
fi

REPOSITORY="slsa-framework/example-package"
BRANCH="main"
FILE="$1"

# Trigger the workflow.
echo curl -s -X POST -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$REPOSITORY/actions/workflows/$FILE/dispatches" \
    -d "{\"ref\":\"$BRANCH\"}" \
    -H "Authorization: token $GH_TOKEN"
