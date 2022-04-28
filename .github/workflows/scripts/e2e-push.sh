#!/bin/bash

# https://docs.github.com/en/rest/repos/contents#create-a-file.
curl \
  -X PUT \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $GH_TOKEN" \
  https://api.github.com/repos/$GITHUB_REPOSITORY/contents/e2e/$FILE \
  -d '{"message":"$COMMIT_MESSAGE","committer":{"name":"github-actions","email":"github-actions@github.com"},"content":"$(cat $DATE | base64 --wrap=0)"}'
