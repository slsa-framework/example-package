#!/usr/bin/env bash

BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
echo curl -s -X POST -H "Accept: application/vnd.github.v3+json" \
     https://api.github.com/repos/$GITHUB_REPOSITORY/actions/workflows/$THIS_FILE/dispatches \
     -d "{\"ref\":\"$BRANCH\"}" \
     -H "Authorization: token $GH_TOKEN"

curl -s -X POST -H "Accept: application/vnd.github.v3+json" \
     https://api.github.com/repos/$GITHUB_REPOSITORY/actions/workflows/$THIS_FILE/dispatches \
     -d "{\"ref\":\"$BRANCH\"}" \
     -H "Authorization: token $GH_TOKEN"