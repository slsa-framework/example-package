#!/bin/bash

curl -X POST -H "Accept: application/vnd.github.v3+json" \
     https://api.github.com/repos/$GITHUB_REPOSITORY/actions/workflows/$THIS_FILE/dispatches \
     -d '{"ref":"main"}' \
     -H "Authorization: token $GH_TOKEN"
